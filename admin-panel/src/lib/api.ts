import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3000/api/v1';

export const TOKEN_KEY = 'NutriLife_admin_token';
export const USER_KEY = 'NutriLife_admin_user';

export const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

/** Borra token y usuario guardados. Ambos van juntos: si queda el usuario sin
 *  token, el panel cree que hay sesión y entra en bucle login ↔ dashboard. */
export function clearStoredSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

let onUnauthorized: (() => void) | null = null;

/** El AuthProvider registra aquí cómo cerrar la sesión ante un 401. */
export function setUnauthorizedHandler(handler: (() => void) | null) {
  onUnauthorized = handler;
}

// Adjunta el token JWT en cada request si existe.
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Ante un 401 (token inválido/expirado) se cierra la sesión sin recargar la
// página; las rutas protegidas redirigen solas al login.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isLoginRequest = error?.config?.url?.includes('/auth/login');
    if (error?.response?.status === 401 && !isLoginRequest) {
      clearStoredSession();
      onUnauthorized?.();
    }
    return Promise.reject(error);
  }
);

/** Extrae un mensaje de error legible de una respuesta de axios. */
export function getErrorMessage(error: unknown, fallback = 'Ocurrió un error'): string {
  if (axios.isAxiosError(error)) {
    return error.response?.data?.message ?? error.message ?? fallback;
  }
  if (error instanceof Error) return error.message;
  return fallback;
}
