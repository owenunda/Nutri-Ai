import {
  createContext,
  useContext,
  useState,
  useCallback,
  useEffect,
  type ReactNode,
} from 'react';
import {
  api,
  TOKEN_KEY,
  USER_KEY,
  clearStoredSession,
  setUnauthorizedHandler,
} from './api';
import type { ApiResponse, AuthUser, LoginResponse } from '../types/auth';

interface AuthContextValue {
  user: AuthUser | null;
  isAuthenticated: boolean;
  /** true si la última sesión terminó porque el token caducó. */
  sessionExpired: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

/** Fecha de expiración (ms) del JWT, o null si no se puede leer. */
function tokenExpiry(token: string): number | null {
  try {
    const payload = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const { exp } = JSON.parse(atob(payload)) as { exp?: number };
    return typeof exp === 'number' ? exp * 1000 : null;
  } catch {
    return null;
  }
}

/** Solo hay sesión si existen usuario y token, y el token no ha caducado. */
function loadStoredSession(): { user: AuthUser | null; expired: boolean } {
  const token = localStorage.getItem(TOKEN_KEY);
  const raw = localStorage.getItem(USER_KEY);
  if (!token || !raw) {
    clearStoredSession();
    return { user: null, expired: false };
  }
  const exp = tokenExpiry(token);
  if (exp !== null && exp <= Date.now()) {
    clearStoredSession();
    return { user: null, expired: true };
  }
  try {
    return { user: JSON.parse(raw) as AuthUser, expired: false };
  } catch {
    clearStoredSession();
    return { user: null, expired: false };
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [initial] = useState(loadStoredSession);
  const [user, setUser] = useState<AuthUser | null>(initial.user);
  const [sessionExpired, setSessionExpired] = useState(initial.expired);

  const expireSession = useCallback(() => {
    clearStoredSession();
    setUser(null);
    setSessionExpired(true);
  }, []);

  // Un 401 de cualquier request cierra la sesión.
  useEffect(() => {
    setUnauthorizedHandler(expireSession);
    return () => setUnauthorizedHandler(null);
  }, [expireSession]);

  // Cierra la sesión justo cuando caduca el token, aunque no haya requests.
  useEffect(() => {
    if (!user) return;
    const token = localStorage.getItem(TOKEN_KEY);
    const exp = token ? tokenExpiry(token) : null;
    if (exp === null) return;
    const delay = Math.max(0, exp - Date.now());
    // setTimeout se desborda por encima de ~24,8 días y dispararía al instante.
    if (delay > 2_147_483_647) return;
    const timer = window.setTimeout(expireSession, delay);
    return () => window.clearTimeout(timer);
  }, [user, expireSession]);

  const login = useCallback(async (email: string, password: string) => {
    const { data } = await api.post<ApiResponse<LoginResponse>>('/auth/login', {
      email,
      password,
    });

    const { token, user: authUser } = data.data;

    if (authUser.role !== 'ADMIN') {
      throw new Error('Acceso denegado: se requiere una cuenta con rol ADMIN.');
    }

    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(authUser));
    setSessionExpired(false);
    setUser(authUser);
  }, []);

  const logout = useCallback(() => {
    clearStoredSession();
    setSessionExpired(false);
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, isAuthenticated: !!user, sessionExpired, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de <AuthProvider>');
  return ctx;
}
