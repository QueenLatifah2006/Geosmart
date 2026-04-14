import { Router } from "express";
import { getStructures, createStructure } from "../controllers/structureController";

const router = Router();

router.get("/", getStructures);
router.post("/", createStructure);

export default router;