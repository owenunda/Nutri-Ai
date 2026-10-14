import { useCallback, useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  Apple,
  ArrowLeft,
  ArrowRight,
  CalendarDays,
  ChefHat,
  Crown,
  KeyRound,
  Loader2,
  MessageCircle,
  Refrigerator,
  Scale,
  ShieldCheck,
  ShieldOff,
  Sparkles,
  UtensilsCrossed,
} from 'lucide-react';
import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { fetchUserDetail, updateUserPassword, updateUserPlan, updateUserRole } from '../lib/admin.api';
import { getErrorMessage } from '../lib/api';
import { useAuth } from '../lib/auth';
import { cn, formatAxisDay, formatDate, formatDay, formatNumber, formatRelative } from '../lib/utils';
import type { Plan, Role, UserDetail as UserDetailData } from '../types/admin';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button, buttonVariants } from '../components/ui/button';
import { Dialog } from '../components/ui/dialog';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { StatCard } from '../components/StatCard';
import { UserAvatar } from '../components/UserAvatar';
import { ModuleBadge, PlanBadge, StatusBadge, authMethodLabel } from '../components/CategoryBadge';
import { EmptyState, ErrorState, LoadingState } from '../components/States';
import { Nutria } from '../components/Nutria';
import { CHART_COLORS, ModuleBars, axisProps, chartTooltipStyle } from '../components/charts';

export default function UserDetail() {
  const { userId } = useParams();
  const id = Number(userId);
  const [data, setData] = useState<UserDetailData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [planDialog, setPlanDialog] = useState(false);
  const [passwordDialog, setPasswordDialog] = useState(false);
  const [roleDialog, setRoleDialog] = useState(false);
  const { user: currentUser } = useAuth();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setData(await fetchUserDetail(id));
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  const back = (
    <Link to="/users" className="inline-flex items-center gap-1 text-sm font-semibold text-muted-foreground hover:text-foreground">
      <ArrowLeft className="h-4 w-4" /> Usuarios
    </Link>
  );

  if (loading && !data) return <div className="space-y-4">{back}<LoadingState label="Cargando usuario..." /></div>;
  if (error || !data) {
    return (
      <div className="space-y-4">
        {back}
        <ErrorState message={error ?? 'Usuario no encontrado'} onRetry={load} />
      </div>
    );
  }

  const { profile, usage } = data;
  const isPro = profile.plan === 'PRO';
  const isAdmin = profile.role === 'ADMIN';
  const isSelf = currentUser?.userId === profile.userId;

  return (
    <div className="space-y-6">
      {back}

      {/* Cabecera del perfil */}
      <section className="brand-gradient relative overflow-hidden rounded-3xl p-6 text-white md:p-8">
        <div className="pointer-events-none absolute -right-10 -top-10 h-56 w-56 rounded-full bg-white/10" />
        <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <UserAvatar name={profile.name} userId={profile.userId} className="h-16 w-16 text-xl ring-4 ring-white/20" />
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-bold">{profile.name}</h1>
                <PlanBadge plan={profile.plan} />
                <span className="rounded-full bg-white/20 px-2 py-0.5 text-xs font-bold">
                  {authMethodLabel(profile.authMethod)}
                </span>
                {profile.role === 'ADMIN' && (
                  <span className="rounded-full bg-white/20 px-2 py-0.5 text-xs font-bold">ADMIN</span>
                )}
              </div>
              <p className="truncate text-white/80">{profile.email}</p>
              <p className="mt-1 text-sm text-white/70">
                #{profile.userId} · Se unió el {formatDay(profile.createdAt)} · Activo {formatRelative(usage.lastActivity)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <dl className="grid grid-cols-2 gap-y-1 text-sm sm:grid-cols-4 md:grid-cols-2">
              <ProfileFact label="Objetivo" value={profile.goal ?? '—'} />
              <ProfileFact label="Edad" value={profile.age ? `${profile.age} años` : '—'} />
              <ProfileFact label="Altura" value={profile.height ? `${Number(profile.height)} cm` : '—'} />
              <ProfileFact label="Peso" value={profile.weight ? `${Number(profile.weight)} kg` : '—'} />
            </dl>
            <Nutria mood={isPro ? 'premium' : 'feliz'} className="hidden h-28 w-28 shrink-0 lg:block" />
          </div>
        </div>
        <div className="relative mt-5 flex flex-wrap gap-2">
          <Button
            size="sm"
            onClick={() => setPlanDialog(true)}
            className={isPro ? 'bg-white/15 text-white hover:bg-white/25' : 'bg-white text-emerald-900 hover:bg-white/90'}
          >
            <Crown className="h-4 w-4" />
            {isPro ? 'Pasar a FREE' : 'Regalar PRO'}
          </Button>
          <Button
            size="sm"
            onClick={() => setPasswordDialog(true)}
            className="bg-white/15 text-white hover:bg-white/25"
          >
            <KeyRound className="h-4 w-4" />
            Cambiar contraseña
          </Button>
          <Button
            size="sm"
            onClick={() => setRoleDialog(true)}
            disabled={isSelf}
            title={isSelf ? 'No puedes cambiar tu propio rol' : undefined}
            className="bg-white/15 text-white hover:bg-white/25"
          >
            {isAdmin ? <ShieldOff className="h-4 w-4" /> : <ShieldCheck className="h-4 w-4" />}
            {isAdmin ? 'Quitar admin' : 'Hacer admin'}
          </Button>
          <Link
            to={`/events?userId=${profile.userId}`}
            className={cn(buttonVariants({ size: 'sm' }), 'bg-white/15 text-white hover:bg-white/25')}
          >
            Ver todos sus eventos <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </section>

      {/* Uso de la IA y de la app */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Consultas a la IA"
          value={usage.aiQueries}
          icon={Sparkles}
          tone="violet"
          hint={`${usage.aiQueries7d} en los últimos 7 días`}
        />
        <StatCard
          title="Mensajes al chat"
          value={usage.chatMessages}
          icon={MessageCircle}
          hint={`${usage.chatSessions} conversaciones`}
        />
        <StatCard
          title="Comidas registradas"
          value={usage.mealItems}
          icon={UtensilsCrossed}
          tone="orange"
          hint={`en ${usage.mealDays} ${usage.mealDays === 1 ? 'día' : 'días'}`}
        />
        <StatCard
          title="Recetas guardadas"
          value={usage.recipesSaved}
          icon={ChefHat}
          tone="amber"
        />
      </div>
      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <SmallFact icon={Refrigerator} label="En la nevera" value={usage.fridgeItems} />
        <SmallFact icon={Apple} label="Alimentos propios" value={usage.customFoods} />
        <SmallFact icon={Scale} label="Registros de peso" value={usage.weighIns} />
        <SmallFact icon={KeyRound} label="Inicios de sesión" value={usage.logins} />
        <SmallFact icon={CalendarDays} label="Días activo" value={usage.activeDays} />
        <SmallFact icon={Sparkles} label="Peticiones totales" value={usage.totalEvents} />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader className="pb-2">
            <CardTitle>Últimos 30 días</CardTitle>
            <p className="text-sm text-muted-foreground">Peticiones a la API y consultas a la IA por día</p>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={260}>
              <ComposedChart data={data.series} margin={{ left: -20, right: 8, top: 8 }}>
                <CartesianGrid strokeDasharray="3 3" stroke={CHART_COLORS.grid} vertical={false} />
                <XAxis dataKey="day" tickFormatter={formatAxisDay} minTickGap={20} {...axisProps} />
                <YAxis yAxisId="left" allowDecimals={false} {...axisProps} />
                <YAxis yAxisId="right" orientation="right" allowDecimals={false} {...axisProps} />
                <Tooltip contentStyle={chartTooltipStyle} labelFormatter={(d) => formatAxisDay(String(d))} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar yAxisId="left" dataKey="events" name="Peticiones" fill={CHART_COLORS.users} radius={[4, 4, 0, 0]} />
                <Line
                  yAxisId="right"
                  type="monotone"
                  dataKey="aiQueries"
                  name="Consultas IA"
                  stroke={CHART_COLORS.ai}
                  strokeWidth={2}
                  dot={false}
                />
              </ComposedChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle>Qué usa de la app</CardTitle>
            <p className="text-sm text-muted-foreground">Peticiones por sección</p>
          </CardHeader>
          <CardContent>
            {data.byModule.length === 0 ? (
              <EmptyState mood="sentada" title="Sin actividad" description="Todavía no ha usado la app." />
            ) : (
              <ModuleBars data={data.byModule} />
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle>Actividad reciente</CardTitle>
          <Link
            to={`/events?userId=${profile.userId}`}
            className="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:underline"
          >
            Ver todo <ArrowRight className="h-4 w-4" />
          </Link>
        </CardHeader>
        <CardContent>
          {data.recentEvents.length === 0 ? (
            <EmptyState mood="sentada" title="Sin eventos" />
          ) : (
            <ul className="divide-y">
              {data.recentEvents.map((ev) => (
                <li key={ev.eventId} className="flex flex-wrap items-center gap-x-3 gap-y-1 py-2.5 text-sm">
                  <span className="w-36 shrink-0 text-muted-foreground" title={formatDate(ev.createdAt)}>
                    {formatRelative(ev.createdAt)}
                  </span>
                  <ModuleBadge module={ev.module} />
                  <span className="font-medium">{ev.eventType}</span>
                  {ev.path && (
                    <span className="min-w-0 flex-1 truncate font-mono text-xs text-muted-foreground">
                      {ev.method} {ev.path}
                    </span>
                  )}
                  <span className="ml-auto">
                    <StatusBadge status={ev.statusCode} />
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      <PlanDialog
        open={planDialog}
        onClose={() => setPlanDialog(false)}
        userId={profile.userId}
        name={profile.name}
        current={profile.plan}
        onChanged={(plan) => setData((d) => (d ? { ...d, profile: { ...d.profile, plan } } : d))}
      />

      <PasswordDialog
        open={passwordDialog}
        onClose={() => setPasswordDialog(false)}
        userId={profile.userId}
        name={profile.name}
        // Con contraseña, un usuario que solo entraba con Google pasa a "Ambos".
        onChanged={() =>
          setData((d) =>
            d && d.profile.authMethod === 'GOOGLE'
              ? { ...d, profile: { ...d.profile, authMethod: 'BOTH' } }
              : d
          )
        }
      />

      <RoleDialog
        open={roleDialog}
        onClose={() => setRoleDialog(false)}
        userId={profile.userId}
        name={profile.name}
        isAdmin={isAdmin}
        onChanged={(role) => setData((d) => (d ? { ...d, profile: { ...d.profile, role } } : d))}
      />
    </div>
  );
}

function ProfileFact({ label, value }: { label: string; value: string }) {
  return (
    <div className="mr-6">
      <dt className="text-xs text-white/60">{label}</dt>
      <dd className="font-semibold">{value}</dd>
    </div>
  );
}

function SmallFact({ icon: Icon, label, value }: { icon: typeof Apple; label: string; value: number }) {
  return (
    <div className="rounded-2xl border bg-card p-4">
      <Icon className="h-4 w-4 text-primary" />
      <p className="mt-2 text-xl font-bold tabular-nums">{formatNumber(value)}</p>
      <p className="text-xs text-muted-foreground">{label}</p>
    </div>
  );
}

function PlanDialog({
  open,
  onClose,
  userId,
  name,
  current,
  onChanged,
}: {
  open: boolean;
  onClose: () => void;
  userId: number;
  name: string;
  current: Plan;
  onChanged: (plan: Plan) => void;
}) {
  const next: Plan = current === 'PRO' ? 'FREE' : 'PRO';
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const confirm = async () => {
    setSaving(true);
    setError(null);
    try {
      const result = await updateUserPlan(userId, next);
      onChanged(result.plan);
      onClose();
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={next === 'PRO' ? 'Regalar NutriLife PRO' : 'Quitar el plan PRO'}>
      <div className="flex items-center gap-4">
        <Nutria mood={next === 'PRO' ? 'premium' : 'triste'} className="h-20 w-20 shrink-0" />
        <p className="text-sm text-muted-foreground">
          {next === 'PRO'
            ? `${name} pasará al plan PRO.`
            : `${name} volverá al plan FREE.`}{' '}
          El cambio se ve en la app la próxima vez que inicie sesión.
        </p>
      </div>
      {error && <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
      <div className="mt-6 flex justify-end gap-2">
        <Button variant="outline" onClick={onClose} disabled={saving}>
          Cancelar
        </Button>
        <Button
          onClick={confirm}
          disabled={saving}
          variant={next === 'PRO' ? 'default' : 'destructive'}
        >
          {saving && <Loader2 className="h-4 w-4 animate-spin" />}
          {next === 'PRO' ? 'Dar PRO' : 'Pasar a FREE'}
        </Button>
      </div>
    </Dialog>
  );
}

const MIN_PASSWORD_LENGTH = 6;

function PasswordDialog({
  open,
  onClose,
  userId,
  name,
  onChanged,
}: {
  open: boolean;
  onClose: () => void;
  userId: number;
  name: string;
  onChanged: () => void;
}) {
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const close = () => {
    setPassword('');
    setConfirmation('');
    setError(null);
    onClose();
  };

  const save = async (event: React.FormEvent) => {
    event.preventDefault();
    if (password.length < MIN_PASSWORD_LENGTH) {
      setError(`La contraseña debe tener al menos ${MIN_PASSWORD_LENGTH} caracteres.`);
      return;
    }
    if (password !== confirmation) {
      setError('Las contraseñas no coinciden.');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      await updateUserPassword(userId, password);
      onChanged();
      close();
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={close} title="Cambiar contraseña">
      <form onSubmit={save} className="space-y-4">
        <p className="text-sm text-muted-foreground">
          {name} podrá entrar con esta contraseña desde ahora. Su contraseña anterior deja de funcionar.
        </p>
        <div className="space-y-2">
          <Label htmlFor="new-password">Contraseña nueva</Label>
          <Input
            id="new-password"
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={saving}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="confirm-password">Repite la contraseña</Label>
          <Input
            id="confirm-password"
            type="password"
            autoComplete="new-password"
            value={confirmation}
            onChange={(e) => setConfirmation(e.target.value)}
            disabled={saving}
          />
        </div>
        {error && <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={close} disabled={saving}>
            Cancelar
          </Button>
          <Button type="submit" disabled={saving}>
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            Guardar
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

function RoleDialog({
  open,
  onClose,
  userId,
  name,
  isAdmin,
  onChanged,
}: {
  open: boolean;
  onClose: () => void;
  userId: number;
  name: string;
  isAdmin: boolean;
  onChanged: (role: Role) => void;
}) {
  const next: Role = isAdmin ? 'USER' : 'ADMIN';
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const confirm = async () => {
    setSaving(true);
    setError(null);
    try {
      const result = await updateUserRole(userId, next);
      onChanged(result.role);
      onClose();
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={next === 'ADMIN' ? 'Hacer administrador' : 'Quitar administrador'}>
      <p className="text-sm text-muted-foreground">
        {next === 'ADMIN'
          ? `${name} podrá entrar a este panel y ver y cambiar los datos de todos los usuarios.`
          : `${name} ya no podrá entrar a este panel.`}{' '}
        El cambio se aplica la próxima vez que inicie sesión.
      </p>
      {error && <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
      <div className="mt-6 flex justify-end gap-2">
        <Button variant="outline" onClick={onClose} disabled={saving}>
          Cancelar
        </Button>
        <Button onClick={confirm} disabled={saving} variant={next === 'ADMIN' ? 'default' : 'destructive'}>
          {saving && <Loader2 className="h-4 w-4 animate-spin" />}
          {next === 'ADMIN' ? 'Hacer admin' : 'Quitar admin'}
        </Button>
      </div>
    </Dialog>
  );
}
