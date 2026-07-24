import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../lib/auth';

/** Bloquea el acceso a rutas si no hay sesión admin activa. */
export function ProtectedRoute() {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}
