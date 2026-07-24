import { api } from './api';
import type { ApiResponse } from '../types/auth';
import type {
  ActivityEvent,
  EventFilters,
  EventListResponse,
  EventStats,
  RetentionResult,
} from '../types/event';

/** Construye los query params ignorando valores vacíos. */
function buildParams(filters: EventFilters): Record<string, string> {
  const params: Record<string, string> = {};
  Object.entries(filters).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      params[key] = String(value);
    }
  });
  return params;
}

export async function fetchEvents(filters: EventFilters): Promise<EventListResponse> {
  const { data } = await api.get<ApiResponse<EventListResponse>>('/admin/events', {
    params: buildParams(filters),
  });
  return data.data;
}

export async function fetchStats(
  filters: Pick<EventFilters, 'from' | 'to'>
): Promise<EventStats> {
  const { data } = await api.get<ApiResponse<EventStats>>('/admin/events/stats', {
    params: buildParams(filters),
  });
  return data.data;
}

export async function runRetention(days: number, type?: string): Promise<RetentionResult> {
  const { data } = await api.delete<ApiResponse<RetentionResult>>('/admin/events', {
    data: { days, ...(type ? { type } : {}) },
  });
  return data.data;
}

export type { ActivityEvent };
