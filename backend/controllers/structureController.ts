import { Request, Response } from "express";
import { Structure } from "../models/structures";

export const getStructures = async (req: Request, res: Response) => {
  try {
    const role = req.headers['x-role'] || 'admin';
    const query = role === 'superadmin' ? {} : { deleted: false };
    const structures = await Structure.find(query);
    res.json(structures);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur" });
  }
};

export const createStructure = async (req: Request, res: Response) => {
  try {
    const role = req.headers['x-role'] || 'admin';
    const newStructure = new Structure({ 
      ...req.body, 
      lockedBySuperAdmin: role === 'superadmin'
    });
    await newStructure.save();
    res.status(201).json(newStructure);
  } catch (error) {
    res.status(400).json({ message: "Données invalides" });
  }
};