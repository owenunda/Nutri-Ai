import {
  listEventsService,
  getStatsService,
  runRetentionService,
} from './events.service.js';
import { successResponse } from '../../utils/response.js';

export const listEvents = async (req, res, next) => {
  try {
    const result = await listEventsService(req.eventFilters);
    return successResponse(res, result, 'Eventos consultados con éxito');
  } catch (error) {
    next(error);
  }
};

export const getStats = async (req, res, next) => {
  try {
    const stats = await getStatsService(req.eventFilters);
    return successResponse(res, stats, 'Estadísticas de eventos consultadas con éxito');
  } catch (error) {
    next(error);
  }
};

export const runRetention = async (req, res, next) => {
  try {
    const result = await runRetentionService(req.retentionOptions);
    return successResponse(res, result, 'Política de retención ejecutada con éxito');
  } catch (error) {
    next(error);
  }
};
