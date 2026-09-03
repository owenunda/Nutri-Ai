export interface AuthUser {
  userId: number;
  name: string;
  email: string;
  role: string;
  plan?: string;
  goal?: string | null;
}

export interface LoginResponse {
  token: string;
  user: AuthUser;
}

/** Envoltorio estándar de respuestas del backend NutriLife. */
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}
