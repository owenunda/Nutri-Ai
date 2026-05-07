import { Router } from "express";
import { getAllRecipes, createRecipe, addIngredientsToRecipe, getRecipeById, updateRecipeStatus, handleRecipeAction } from "./recipe.controller.js";
import authenticateToken from "../../middleware/auth.middleware.js";

const router = Router();

router.get('/', authenticateToken(['ADMIN', 'USER']), getAllRecipes);
router.get('/:recipeId', authenticateToken(['ADMIN', 'USER']), getRecipeById);
router.post('/', authenticateToken(['ADMIN', 'USER']), createRecipe);
router.post('/:recipeId/ingredients', authenticateToken(['ADMIN', 'USER']), addIngredientsToRecipe);
router.patch('/:recipeId/status', authenticateToken(['ADMIN', 'USER']), updateRecipeStatus);
router.post('/:recipeId/action', authenticateToken(['ADMIN', 'USER']), handleRecipeAction);

export default router;
