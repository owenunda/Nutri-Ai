import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { BarChart3, Clock, Loader2, ShieldCheck, Sparkles } from 'lucide-react';
import { useAuth } from '../lib/auth';
import { getErrorMessage } from '../lib/api';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Nutria } from '../components/Nutria';

const HIGHLIGHTS = [
  { icon: Sparkles, text: 'Quién usa la IA y cuántas consultas hace cada usuario' },
  { icon: BarChart3, text: 'Qué secciones de la app se usan más' },
  { icon: ShieldCheck, text: 'Errores y bots separados de los usuarios reales' },
];

export default function Login() {
  const { isAuthenticated, sessionExpired, login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email, password);
      navigate('/', { replace: true });
    } catch (err) {
      setError(getErrorMessage(err, 'No se pudo iniciar sesión'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid min-h-screen bg-background lg:grid-cols-[1.1fr_1fr]">
      {/* Panel de marca */}
      <section className="brand-gradient relative flex flex-col justify-between overflow-hidden p-8 text-white lg:p-12">
        <div className="pointer-events-none absolute -right-24 -top-24 h-80 w-80 rounded-full bg-white/10" />
        <div className="pointer-events-none absolute -bottom-32 -left-20 h-96 w-96 rounded-full bg-black/10" />

        <div className="relative flex items-center gap-2.5">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/15">
            <Nutria mood="feliz" className="h-9 w-9" />
          </div>
          <div className="leading-tight">
            <p className="font-bold">NutriLife</p>
            <p className="text-xs font-medium text-white/75">Panel admin</p>
          </div>
        </div>

        <div className="relative my-10 flex flex-col items-center gap-8 lg:my-0 lg:items-start">
          <Nutria mood={error ? 'triste' : 'saludando'} bob={!error} className="h-40 w-40 lg:h-56 lg:w-56" />
          <div className="max-w-md text-center lg:text-left">
            <h2 className="text-3xl font-bold leading-tight lg:text-4xl">Todo NutriLife en un solo lugar</h2>
            <ul className="mt-6 hidden space-y-3 lg:block">
              {HIGHLIGHTS.map(({ icon: Icon, text }) => (
                <li key={text} className="flex items-center gap-3 text-white/90">
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white/15">
                    <Icon className="h-4 w-4" />
                  </span>
                  {text}
                </li>
              ))}
            </ul>
          </div>
        </div>

        <p className="relative hidden text-xs text-white/60 lg:block">Solo cuentas con rol ADMIN</p>
      </section>

      {/* Formulario */}
      <section className="flex items-center justify-center p-6 sm:p-10">
        <div className="w-full max-w-sm">
          <h1 className="text-3xl font-bold">¡Hola de nuevo!</h1>
          <p className="mt-2 text-muted-foreground">Inicia sesión con tu cuenta de administrador.</p>

          {sessionExpired && !error && (
            <p className="mt-6 flex items-center gap-2 rounded-xl bg-amber-500/10 px-3 py-2.5 text-sm text-amber-400">
              <Clock className="h-4 w-4 shrink-0" />
              Tu sesión caducó. Vuelve a iniciar sesión.
            </p>
          )}

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div className="space-y-2">
              <Label htmlFor="email">Correo</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@nutrilife.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                className="h-12 rounded-xl"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Contraseña</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
                className="h-12 rounded-xl"
              />
            </div>
            {error && (
              <p className="rounded-xl bg-destructive/10 px-3 py-2.5 text-sm text-destructive">{error}</p>
            )}
            <Button
              type="submit"
              className="brand-gradient h-12 w-full rounded-xl text-base font-semibold text-white hover:opacity-95"
              disabled={loading}
            >
              {loading && <Loader2 className="h-4 w-4 animate-spin" />}
              {loading ? 'Entrando...' : 'Entrar'}
            </Button>
          </form>
        </div>
      </section>
    </div>
  );
}
