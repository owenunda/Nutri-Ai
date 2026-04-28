import { Router } from "express";
import { getAllRecipes, createRecipe } from "./recipe.controller.js";
import authenticateToken from "../../middleware/auth.middleware.js";

const router = Router();

router.get('/', authenticateToken(['ADMIN', 'USER']), getAllRecipes);
router.post('/', authenticateToken(['ADMIN', 'USER']), createRecipe);

export default router