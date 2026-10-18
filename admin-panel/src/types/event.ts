export type EventCategory = 'AUTH' | 'AI' | 'ERROR' | 'CRUD' | 'SYSTEM';

/** Módulo de la app derivado de la ruta del evento (ver backend moduleSql). */
export type EventModule =
  | 'food'
  | 'fridge'
  | 'recipe'
  | 'user'
  | 'stats'
  | 'meals'
  | 'hydration'
  | 'ai'
  | 'admin'
  | 'chat'
  | 'auth'
  | 'bots'
  | 'external'
  | 'other';

export interface ActivityEvent {
  eventId: number;
  eventType: string;
  category: EventCategory | string;
  module: EventModule;
  userId: number | null;
  userName: string | null;
  userEmail: string | null;
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

export interface EventFilters {
  type?: string;
  category?: string;
  module?: string;
  userId?: string;
  from?: string;
  to?: string;
  hideReads?: boolean;
  hideBots?: boolean;
  page?: number;
  limit?: number;
}

export interface RetentionResult {
  deleted: number;
  days: number;
  type: string | null;
}
