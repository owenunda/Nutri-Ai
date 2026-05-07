import { saveGeneratedRecipeService } from './ai.service.js';
import { successResponse } from '../../utils/response.js';

/**
 * Recibe una receta generada por n8n y la guarda para el usuario.
 */
export const receiveGeneratedRecipe = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const recipeData = req.body;
    
    const recipe = await saveGeneratedRecipeService(userId, recipeData);
    
    return successResponse(
      res, 
      recipe, 
      'Receta generada por IA guardada correctamente en tu lista', 
      201
    );
  } catch (error) {
    next(error);
  }
};
