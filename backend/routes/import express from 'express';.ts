import express from 'express';
import { GoogleGenAI, Type } from "@google/genai";
import Groq from "groq-sdk";
import Structure from '../models/Structure.js';

const router = express.Router();

// Helper to get Gemini AI instance
function getGenAI() {
  const key = process.env.GEMINI_API_KEY;
  return key ? new GoogleGenAI({ apiKey: key }) : null;
}

// Helper to get Groq instance
function getGroq() {
  const key = process.env.GROQ_API_KEY;
  return key ? new Groq({ apiKey: key }) : null;
}

const MISSING_KEY_RESPONSE = { 
  message: 'Configuration requise : Une clé API (GEMINI_API_KEY ou GROQ_API_KEY) est absente.',
  error: 'MISSING_API_KEY',
  instructions: 'Allez dans Settings > Secrets et ajoutez GROQ_API_KEY (gratuit sur console.groq.com) ou GEMINI_API_KEY.'
};

// Helper for fallback search when AI fails
function fallbackSearch(query: string) {
  const commonCategories = ['Santé', 'Education', 'Commerce', 'Transport', 'Restaurant', 'Pharmacie', 'Hôtel', 'Banque'];
  const foundCategories = commonCategories.filter(cat => 
    query.toLowerCase().includes(cat.toLowerCase())
  );
  
  const keywords = query.split(' ').filter(w => w.length > 3);
  
  return {
    categories: foundCategories.length > 0 ? foundCategories : ['Commerce'],
    keywords: keywords,
    intent: "Recherche par mots-clés (Mode Secours)"
  };
}

router.post('/search', async (req, res) => {
  const { query } = req.body;

  try {
    const ai = getGenAI();

    if (!query) {
      return res.status(400).json({ message: 'Query is required' });
    }

    let searchParams;
    const ai = getGenAI();
    const groq = getGroq();

    if (!ai && !groq) {
      return res.status(401).json(MISSING_KEY_RESPONSE);
    }

    try {
      // 1. Try Gemini first if available
      if (ai) {
        const response = await ai.models.generateContent({
          model: "gemini-1.5-flash-latest",
          contents: `Analyse la requête suivante de l'utilisateur pour une application de géolocalisation à Ngaoundéré (GeoSmart). 
          Extrais les catégories de structures pertinentes (ex: Santé, Education, Commerce, Transport, Restaurant, Pharmacie, Dentiste, etc.) 
          et les mots-clés de recherche.
          
          Requête: "${query}"
          
          Réponds UNIQUEMENT au format JSON suivant:
          {
            "categories": ["cat1", "cat2"],
            "keywords": ["mot1", "mot2"],
            "intent": "description de l'intention"
          }`,
        });

        let text = response.text || '{}';
        text = text.replace(/```json/g, '').replace(/```/g, '').trim();
        searchParams = JSON.parse(text);
      } else {
        throw new Error('Gemini not configured');
      }
    } catch (aiError) {
      console.warn('Gemini Search failed, trying Groq:', aiError);
      
      if (groq) {
        try {
          const completion = await groq.chat.completions.create({
            messages: [
              {
                role: "user",
                content: `Analyse la requête: "${query}". Extrais les catégories et mots-clés pour Ngaoundéré. Réponds UNIQUEMENT en JSON: {"categories": [], "keywords": [], "intent": ""}`
              }
            ],
            model: "llama-3.3-70b-versatile",
            response_format: { type: "json_object" }
          });
          searchParams = JSON.parse(completion.choices[0].message.content || '{}');
        } catch (groqError) {
          console.error('Groq Search failed:', groqError);
          searchParams = fallbackSearch(query);
        }
      } else {
        searchParams = fallbackSearch(query);
      }
    }

    const { categories, keywords } = searchParams;

    // 2. Query MongoDB based on extracted parameters
    const mongoQuery: any = {
      isBlocked: false,
      $or: [
        { type: { $in: categories.map((c: string) => new RegExp(c, 'i')) } },
        { name: { $in: keywords.map((k: string) => new RegExp(k, 'i')) } },
        { description: { $in: keywords.map((k: string) => new RegExp(k, 'i')) } },
        { 'products.name': { $in: keywords.map((k: string) => new RegExp(k, 'i')) } },
        { 'services.name': { $in: keywords.map((k: string) => new RegExp(k, 'i')) } }
      ]
    };

    const results = await Structure.find(mongoQuery).limit(10);

    res.json({
      intent: searchParams.intent,
      categories,
      keywords,
      results
    });

  } catch (error: any) {
    if (error.message === 'MISSING_API_KEY') {
      return res.status(401).json(MISSING_KEY_RESPONSE);
    }
    console.error('AI Search Error:', error);
    res.status(500).json({ message: 'Error processing AI search', error: String(error) });
  }
});

router.post('/analyze-image', async (req, res) => {
  const { image, type } = req.body; // type: 'qr' or 'facade'

  try {
    const ai = getGenAI();

    if (!image) {
      return res.status(400).json({ message: 'Image is required' });
    }

    const prompt = type === 'facade' 
      ? "Identifie ce bâtiment à Ngaoundéré. S'agit-il d'une structure connue ? Donne son nom et sa catégorie si possible."
      : "Extrais les informations de ce code QR ou code-barres. S'il s'agit d'un produit, donne son nom.";

    let analysis;
    try {
      const response = await ai.models.generateContent({
        model: "gemini-1.5-flash-latest",
        contents: [
          { text: prompt },
          { inlineData: { data: image, mimeType: "image/jpeg" } }
        ],
      });

      let text = response.text || '{}';
      text = text.replace(/```json/g, '').replace(/```/g, '').trim();
      analysis = JSON.parse(text);
    } catch (aiError) {
      console.warn('Gemini Vision failed, using fallback:', aiError);
      analysis = {
        identifiedName: type === 'facade' ? "Bâtiment identifié" : "Code détecté",
        description: "Analyse visuelle en mode maintenance. L'IA n'a pas pu traiter l'image en temps réel.",
        confidence: 0.5
      };
    }
    
    // Search for the identified structure in DB
    let structure = null;
    if (analysis.identifiedName) {
      structure = await Structure.findOne({ 
        name: new RegExp(analysis.identifiedName, 'i'),
        isBlocked: false
      });
    }

    res.json({
      analysis,
      structure
    });

  } catch (error: any) {
    if (error.message === 'MISSING_API_KEY') {
      return res.status(401).json(MISSING_KEY_RESPONSE);
    }
    console.error('AI Image Analysis Error:', error);
    res.status(500).json({ message: 'Error analyzing image', error: String(error) });
  }
});

router.post('/chat', async (req, res) => {
  const { message, history } = req.body;

  try {
    const ai = getGenAI();

    if (!message) {
      return res.status(400).json({ message: 'Message is required' });
    }

    // Fetch some context (structures) to simulate RAG
    const structures = await Structure.find({ isBlocked: false, isPremium: true }).limit(20);
    const context = structures.map(s => `${s.name} (${s.type}): ${s.description}`).join('\n');

    let reply;
    const ai = getGenAI();
    const groq = getGroq();

    try {
      if (ai) {
        const response = await ai.models.generateContent({
          model: "gemini-1.5-flash-latest",
          contents: [
            { 
              role: "user", 
              parts: [{ text: `Tu es l'assistant intelligent de GeoSmart, une application de géolocalisation à Ngaoundéré. 
              Voici quelques informations sur les structures locales pour t'aider:
              ${context}
              
              Réponds à la question de l'utilisateur de manière utile et sécurisée.
              Question: ${message}` }]
            }
          ],
        });
        reply = response.text || '';
      } else {
        throw new Error('Gemini not configured');
      }
    } catch (aiError) {
      console.warn('Gemini Chat failed, trying Groq:', aiError);
      if (groq) {
        try {
          const completion = await groq.chat.completions.create({
            messages: [
              {
                role: "system",
                content: "Tu es l'assistant GeoSmart à Ngaoundéré."
              },
              {
                role: "user",
                content: `Infos locales: ${context}\n\nQuestion: ${message}`
              }
            ],
            model: "llama-3.3-70b-versatile",
          });
          reply = completion.choices[0].message.content || '';
        } catch (groqError) {
          reply = `Je suis l'assistant GeoSmart. Je peux vous dire que Ngaoundéré regorge de structures intéressantes comme ${structures.slice(0, 3).map(s => s.name).join(', ')}.`;
        }
      } else {
        reply = `Je suis l'assistant GeoSmart . Je peux vous dire que Ngaoundéré regorge de structures intéressantes comme ${structures.slice(0, 3).map(s => s.name).join(', ')}.`;
      }
    }

    res.json({
      reply: reply
    });

  } catch (error: any) {
    if (error.message === 'MISSING_API_KEY') {
      return res.status(401).json(MISSING_KEY_RESPONSE);
    }
    console.error('AI Chat Error:', error);
    res.status(500).json({ message: 'Error in AI chat', error: String(error) });
  }
});

export default router;
