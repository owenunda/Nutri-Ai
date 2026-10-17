import type { EventModule } from './event';

export type Plan = 'FREE' | 'PRO';
export type ProDuration = '7d' | '1m' | '3m' | '6m' | '12m' | 'forever';

export type AuthMethod = 'EMAIL' | 'GOOGLE' | 'BOTH';

export type Role = 'ADMIN' | 'USER';

export interface DayPoint {
  day: string;
  registrations: number;
  aiQueries: number;
  activeUsers: number;
  requests: number;
  bots: number;
}

export interface ModuleCount {
  module: EventModule;
  count: number;
}

export interface Overview {
  days: number;
  users: { total: number; new7d: number; newInRange: number; pro: number; admins: number };
  activity: {
    active24h: number;
    active7d: number;
    activeInRange: number;
    aiQueriesTotal: number;
    aiQueries24h: number;
    aiQueriesInRange: number;
    errors24h: number;
    errorsInRange: number;
    failedLoginsInRange: number;
    botHitsInRange: number;
    externalHitsInRange: number;
    apiRequestsInRange: number;
  };
  content: {
    recipesSaved: number;
    mealItems: number;
    chatSessions: number;
    chatMessages: number;
    customFoods: number;
  };
  series: DayPoint[];
  byModule: ModuleCount[];
  topAiUsers: { userId: number; name: string; email: string; plan: Plan; aiQueries: number }[];
  recentUsers: {
    userId: number;
    name: string;
    email: string;
    plan: Plan;
    goal: string | null;
    createdAt: string;
  }[];
}

export interface AdminUser {
  userId: number;
  name: string;
  email: string;
  age: number | null;
  goal: string | null;
  role: string;
  plan: Plan;
  /** Fin del PRO regalado. null = sin vencimiento (o FREE). */
  proUntil: string | null;
  authMethod: AuthMethod;
  createdAt: string;
  totalEvents: number;
  aiQueries: number;
  aiQueries7d: number;
  lastActivity: string | null;
  mealItems: number;
  recipesSaved: number;
}

export interface UserListResponse {
  total: number;
  items: AdminUser[];
}

export type UserSort = 'recent' | 'ai' | 'activity' | 'name';

export interface UserFilters {
  search?: string;
  plan?: Plan | '';
  sort?: UserSort;
  page?: number;
  limit?: number;
}

export interface UserDetail {
  profile: {
    userId: number;
    name: string;
    email: string;
    age: number | null;
    goal: string | null;
    role: string;
    plan: Plan;
    /** Fin del PRO regalado. null = sin vencimiento (o FREE). */
    proUntil: string | null;
    authMethod: AuthMethod;
    height: string | null;
    weight: string | null;
    createdAt: string;
    updatedAt: string;
  };
  usage: {
    totalEvents: number;
    aiQueries: number;
    aiQueries7d: number;
    logins: number;
    errors: number;
    lastLogin: string | null;
    lastActivity: string | null;
    activeDays: number;
    chatSessions: number;
    chatMessages: number;
    mealDays: number;
    mealItems: number;
    recipesSaved: number;
    fridgeItems: number;
    customFoods: number;
    weighIns: number;
  };
  series: { day: string; events: number; aiQueries: number }[];
  byModule: ModuleCount[];
  recentEvents: {
    eventId: number;
    eventType: string;
    category: string;
    module: EventModule;
    method: string | null;
    path: string | null;
    statusCode: number | null;
    createdAt: string;
  }[];
}
