import { getAllRecipesService } from "./recipe.service.js";
import { successResponse } from "../../utils/response.js";

export const getAllRecipes = async (req, res, next) => {
  try {
    // se hara un middleware para proteger las rutas por lo que no es necesario enviar el token
    // lo token cuando lo reciba el middleware se lo asignara a req.user 
    // se ahi sacaremos el usuario 
    const TemporalId = 1;
    const recipes = await getAllRecipesService(Number(TemporalId));
    return successResponse(res, recipes, 'Recipes fetched successfully');
  } catch (error) {
    next(error);
  }
};