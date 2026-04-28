import { Router } from "express";
import { getAllRecipes, createRecipe, addIngredientsToRecipe } from "./recipe.controller.js";
import authenticateToken from "../../middleware/auth.middleware.js";

const router = Router();

router.get('/', authenticateToken(['ADMIN', 'USER']), getAllRecipes);
router.post('/', authenticateToken(['ADMIN', 'USER']), createRecipe);
router.post('/:recipeId/ingredients', authenticateToken(['ADMIN', 'USER']), addIngredientsToRecipe);

export default router