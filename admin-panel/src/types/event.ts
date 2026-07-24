export type EventCategory = 'AUTH' | 'AI' | 'ERROR' | 'CRUD' | 'SYSTEM';

export interface ActivityEvent {
  eventId: number;
  eventType: string;
  category: EventCategory | string;
  userId: number | null;
  method: string | null;
  path: string | null;
  statusCode: number | null;
  ipAddress: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export interface EventListResponse {
  total: number;
  items: ActivityEvent[];
}

export interface EventStats {
  total: number;
  byType: { eventType: string; count: number }[];
  byCategory: { category: string; count: number }[];
  byDay: { day: string; count: number }[];
  topUsers: { userId: number; count: number }[];
}

export interface EventFilters {
  type?: string;
  category?: string;
  userId?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
}

export interface RetentionResult {
  deleted: number;
  days: number;
  type: string | null;
}
