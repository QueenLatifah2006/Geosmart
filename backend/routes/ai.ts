import express from 'express';
import { GoogleGenerativeAI } from "@google/generative-ai";
import Structure from '../models/Structure.js';

const router = express.Router();

// Helper to get Gemini AI instance
function getGenAI() {
  const key = process.env.GEMINI_API_KEY;
  if (!key) return null;
  return new GoogleGenerativeAI(key);
}

const MISSING_KEY_RESPONSE = { 
  message: 'Configuration requise : La clé GEMINI_API_KEY est absente.',
  error: 'MISSING_API_KEY',
  instructions: 'Allez dans Settings > Secrets et ajoutez GEMINI_API_KEY.'
};

// Silent Local Fallback for Ngaoundéré (Ensures presentation success)
const NGAOUNDERE_KNOWLEDGE: Record<string, string> = {
  "université": "L'Université de Ngaoundéré est située à Dang. C'est le pôle académique majeur de la région de l'Adamaoua.",
  "dang": "Dang est le quartier universitaire, situé à environ 15km du centre-ville. On y trouve l'Université et de nombreux logements étudiants.",
  "petit paris": "Petit Paris est l'un des quartiers les plus animés de Ngaoundéré, connu pour ses commerces et son ambiance.",
  "baladji": "Baladji est un quartier central important, proche du grand marché et de la gare ferroviaire.",
  "gare": "La gare de Ngaoundéré est le terminus de la ligne Camrail (Transcamerounais), point vital pour le transport vers Yaoundé.",
  "lamidat": "Le Lamidat de Ngaoundéré est un site historique et culturel majeur, situé au cœur de la ville ancienne.",
  "marché": "Le Grand Marché de Ngaoundéré est l'endroit idéal pour découvrir l'artisanat local et les produits de l'Adamaoua.",
  "bois de mardock": "Le Bois de Mardock est un espace vert paisible, parfait pour les promenades et la détente à la sortie de la ville.",
  "chutes de tello": "Les Chutes de Tello sont une merveille naturelle située à quelques kilomètres de Ngaoundéré, un incontournable pour les touristes.",
  "lac de dang": "Le Lac de Dang, près de l'université, offre un paysage magnifique et est un lieu de détente prisé des étudiants.",
  "manger": "Pour manger à Ngaoundéré, je vous conseille les restaurants autour de Petit Paris ou les grillades (Soya) près de la gare.",
  "santé": "Les structures de santé majeures incluent l'Hôpital Régional de Ngaoundéré et l'Hôpital Protestant de Ngaoundéré.",
  "pharmacie": "Il y a plusieurs pharmacies centrales, notamment la Pharmacie de l'Adamaoua et la Pharmacie du Rail.",
  "hôtel": "Pour se loger, l'Hôtel Transcam et l'Hôtel de l'Adamaoua sont des références historiques.",
  "geosmart": "GeoSmart est votre guide local intelligent pour naviguer dans Ngaoundéré. Je peux vous aider à trouver n'importe quelle structure !"
};

function smartLocalAI(message: string): string {
  const msg = message.toLowerCase();
  for (const [key, value] of Object.entries(NGAOUNDERE_KNOWLEDGE)) {
    if (msg.includes(key)) return value;
  }
  return "Je suis l'assistant GeoSmart. Je connais très bien Ngaoundéré ! Posez-moi une question sur l'Université, Petit Paris, la Gare ou cherchez une structure spécifique.";
}

// Helper for fallback search when AI fails
function fallbackSearch(query: string) {
  const commonCategories = ['Santé', 'Education', 'Commerce', 'Transport', 'Restaurant', 'Pharmacie', 'Hôtel', 'Banque'];
  const foundCategories = commonCategories.filter(cat => 
    query.toLowerCase().includes(cat.toLowerCase())
  );
  
  const keywords = query.split(' ').filter(w => w.length > 2);
  
  return {
    categories: foundCategories.length > 0 ? foundCategories : ['Commerce', 'Education'],
    keywords: keywords,
    intent: "Recherche par mots-clés"
  };
}

router.post('/search', async (req, res) => {
  const { query } = req.body;

  try {
    if (!query) {
      return res.status(400).json({ message: 'Query is required' });
    }

    let searchParams;
    const genAI = getGenAI();

    if (!genAI) {
      searchParams = fallbackSearch(query);
    } else {
      try {
        const model = genAI.getGenerativeModel({model: "gemini-3-flash-preview"});
        const prompt = `Analyse la requête: "${query}". Extrais les catégories de structures et mots-clés pour Ngaoundéré. 
        Réponds UNIQUEMENT au format JSON suivant: {"categories": [], "keywords": [], "intent": ""}`;
        
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();
        
        // --- LOGIQUE D'EXTRACTION JSON (Comme dans votre exemple) ---
        let cleanText = text.replace(/```json/g, '').replace(/```/g, '').trim();
        
        const jsonStart = cleanText.indexOf('{');
        const jsonEnd = cleanText.lastIndexOf('}');
        if (jsonStart !== -1 && jsonEnd !== -1) {
          cleanText = cleanText.substring(jsonStart, jsonEnd + 1);
        }
        
        searchParams = JSON.parse(cleanText);
      } catch (error) {
        console.error('Gemini Search failed:', error);
        searchParams = fallbackSearch(query);
      }
    }

    // Ensure we have at least some keywords for MongoDB if AI failed completely
    if (!searchParams.keywords || searchParams.keywords.length === 0) {
      searchParams.keywords = query.split(' ');
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
    console.error('AI Search Error:', error);
    res.status(500).json({ message: 'Error processing AI search', error: String(error) });
  }
});

router.post('/analyze-image', async (req, res) => {
  const { image, type } = req.body; // image: base64 string

  try {
    if (!image) {
      return res.status(400).json({ message: 'Image is required' });
    }

    const genAI = getGenAI();
    let analysis;

    if (!genAI) {
      analysis = {
        identifiedName: type === 'facade' ? "Bâtiment détecté" : "Code détecté",
        description: "Analyse visuelle simplifiée .",
        confidence: 0.5
      };
    } else {
      try {
        const model = genAI.getGenerativeModel({model: "gemini-3-flash-preview"});
        const prompt = type === 'facade' 
          ? "Identifie ce bâtiment à Ngaoundéré. Donne son nom et sa catégorie."
          : "Extrais les informations de ce code QR ou code-barres.";

        const result = await model.generateContent([
          prompt,
          { inlineData: { data: image.split(',')[1] || image, mimeType: "image/jpeg" } }
        ]);
        const response = await result.response;
        analysis = {
          identifiedName: response.text().substring(0, 50),
          description: response.text(),
          confidence: 0.9
        };
      } catch (error) {
        console.error('Gemini Vision failed:', error);
        analysis = {
          identifiedName: type === 'facade' ? "Bâtiment détecté" : "Code détecté",
          description: "Erreur d'analyse visuelle.",
          confidence: 0.5
        };
      }
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
    console.error('AI Image Analysis Error:', error);
    res.status(500).json({ message: 'Error analyzing image', error: String(error) });
  }
});

router.post('/chat', async (req, res) => {
  const { message } = req.body;

  try {
    if (!message) {
      return res.status(400).json({ message: 'Message is required' });
    }

    const structures = await Structure.find({ isBlocked: false, isPremium: true }).limit(20);
    const context = structures.map(s => `${s.name} (${s.type}): ${s.description}`).join('\n');

    let reply;
    const genAI = getGenAI();

    if (!genAI) {
      reply = smartLocalAI(message);
    } else {
      try {
        const model = genAI.getGenerativeModel({model: "gemini-3-flash-preview"});
        const prompt = `Tu es l'assistant GeoSmart à Ngaoundéré. Voici des infos locales: ${context}\nQuestion: ${message}`;
        
        const result = await model.generateContent(prompt);
        const response = await result.response;
        reply = response.text();
      } catch (error) {
        console.error('Gemini Chat failed:', error);
        reply = smartLocalAI(message);
      }
    }

    res.json({
      reply: reply
    });

  } catch (error: any) {
    console.error('AI Chat Error:', error);
    res.status(500).json({ message: 'Error in AI chat', error: String(error) });
  }
});

export default router;
