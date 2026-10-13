import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LayoutDashboard, ListFilter, LogOut, Users } from 'lucide-react';
import { useAuth } from '../lib/auth';
import { cn } from '../lib/utils';
import { Button } from './ui/button';
import { Nutria } from './Nutria';
import { UserAvatar } from './UserAvatar';

const NAV = [
  { to: '/', label: 'Resumen', icon: LayoutDashboard, end: true },
  { to: '/users', label: 'Usuarios', icon: Users, end: false },
  { to: '/events', label: 'Eventos', icon: ListFilter, end: false },
];

function Brand() {
  return (
    <div className="flex items-center gap-2.5">
      <div className="brand-gradient flex h-10 w-10 items-center justify-center rounded-xl">
        <Nutria mood="feliz" className="h-9 w-9" />
      </div>
      <div className="leading-tight">
        <p className="font-bold">NutriLife</p>
        <p className="text-xs font-medium text-primary">Panel admin</p>
      </div>
    </div>
  );
}

export function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="flex min-h-screen bg-background">
      {/* Sidebar */}
      <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-r bg-card md:flex">
        <div className="flex h-20 items-center border-b px-5">
          <Brand />
        </div>
        <nav className="flex-1 space-y-1 p-4">
          {NAV.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors',
                  isActive
                    ? 'brand-gradient text-white shadow-md shadow-emerald-950/40'
                    : 'text-muted-foreground hover:bg-accent hover:text-foreground'
                )
              }
            >
              <Icon className="h-4 w-4" />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="relative mx-4 mb-4 overflow-hidden rounded-2xl border bg-background/60 p-4">
          <Nutria mood="sentada" className="absolute -right-3 -top-1 h-16 w-16 opacity-90" />
          <div className="flex items-center gap-2.5">
            {user && <UserAvatar name={user.name} userId={user.userId} />}
            <div className="min-w-0 pr-8">
              <p className="truncate text-sm font-semibold">{user?.name}</p>
              <p className="truncate text-xs text-muted-foreground">{user?.email}</p>
            </div>
          </div>
          <Button variant="outline" size="sm" className="mt-3 w-full" onClick={handleLogout}>
            <LogOut className="h-4 w-4" />
            Cerrar sesión
          </Button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex min-w-0 flex-1 flex-col">
        {/* Barra superior en móvil, con la navegación */}
        <header className="sticky top-0 z-40 border-b bg-card/95 backdrop-blur md:hidden">
          <div className="flex h-16 items-center justify-between px-4">
            <Brand />
            <Button variant="ghost" size="icon" onClick={handleLogout} aria-label="Cerrar sesión">
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
          <nav className="flex gap-1 overflow-x-auto px-3 pb-2">
            {NAV.map(({ to, label, icon: Icon, end }) => (
              <NavLink
                key={to}
                to={to}
                end={end}
                className={({ isActive }) =>
                  cn(
                    'flex shrink-0 items-center gap-2 rounded-lg px-3 py-1.5 text-sm font-semibold',
                    isActive ? 'brand-gradient text-white' : 'text-muted-foreground'
                  )
                }
              >
                <Icon className="h-4 w-4" />
                {label}
              </NavLink>
            ))}
          </nav>
        </header>
        <main className="mx-auto w-full max-w-7xl flex-1 p-4 md:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
