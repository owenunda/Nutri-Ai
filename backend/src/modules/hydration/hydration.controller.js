import { successResponse } from '../../utils/response.js';
import {
  addGlassService,
  getHistoryService,
  importHistoryService,
  undoGlassService,
} from './hydration.service.js';

const handle = (run, message) => async (req, res, next) => {
  try {
    return successResponse(res, await run(req), message);
  } catch (error) {
    next(error);
  }
};

export const getHistory = handle((req) => getHistoryService(req.user.userId), 'Historial de agua obtenido');
export const addGlass = handle((req) => addGlassService(req.user.userId, req.hydrationDate), 'Vaso registrado');
export const undoGlass = handle((req) => undoGlassService(req.user.userId, req.hydrationDate), 'Vaso deshecho');
export const importHistory = handle(
  (req) => importHistoryService(req.user.userId, req.hydrationHistory),
  'Historial de agua importado'
);
