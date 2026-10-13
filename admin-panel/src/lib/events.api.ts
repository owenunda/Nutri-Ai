import { api } from './api';
import type { ApiResponse } from '../types/auth';
import type { EventFilters, EventListResponse, RetentionResult } from '../types/event';

/** Construye los query params ignorando valores vacíos. */
export function buildParams(filters: object): Record<string, string> {
  const params: Record<string, string> = {};
  Object.entries(filters).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '' && value !== false) {
      params[key] = String(value);
    }
  });
  return params;
}

export async function fetchEvents(filters: EventFilters): Promise<EventListResponse> {
  // "Hasta" es un día completo: sin hora, el backend lo cortaría a las 00:00.
  const to = filters.to && filters.to.length === 10 ? `${filters.to}T23:59:59.999` : filters.to;
  const { data } = await api.get<ApiResponse<EventListResponse>>('/admin/events', {
    params: buildParams({ ...filters, to }),
  });
  return data.data;
}

export async function runRetention(days: number, type?: string): Promise<RetentionResult> {
  const { data } = await api.delete<ApiResponse<RetentionResult>>('/admin/events', {
    data: { days, ...(type ? { type } : {}) },
  });
  return data.data;
}
