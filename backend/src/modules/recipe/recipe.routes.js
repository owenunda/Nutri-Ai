import { Router } from "express";
import { getAllRecipes } from "./recipe.controller.js";

const router = Router();

router.get('/', getAllRecipes);

export default router