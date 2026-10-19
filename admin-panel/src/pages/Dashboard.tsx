import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  AlertTriangle,
  ArrowRight,
  Bug,
  ChefHat,
  Droplet,
  Flame,
  MessageCircle,
  Sparkles,
  UserCheck,
  Users,
} from 'lucide-react';
import {
  Area,
  Bar,
  BarChart,
  CartesianGrid,
  ComposedChart,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { fetchOverview } from '../lib/admin.api';
import { getErrorMessage } from '../lib/api';
import { useAuth } from '../lib/auth';
import { formatAxisDay, formatNumber, formatRelative } from '../lib/utils';
import type { Overview, WaterStreakUser } from '../types/admin';
import { PlanBadge } from '../components/CategoryBadge';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { StatCard } from '../components/StatCard';
import { Nutria } from '../components/Nutria';
import { ErrorState, LoadingState, EmptyState } from '../components/States';
import { UserAvatar } from '../components/UserAvatar';
import { CHART_COLORS, ModuleBars, RangeTabs, axisProps, chartTooltipStyle } from '../components/charts';

export default function Dashboard() {
  const { user } = useAuth();
  const [days, setDays] = useState(30);
  const [data, setData] = useState<Overview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (range: number) => {
    setLoading(true);
    setError(null);
    try {
      setData(await fetchOverview(range));
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(days);
  }, [days, load]);

  const firstName = user?.name.split(' ')[0] ?? '';
  const appModules = data?.byModule.filter((m) => m.module !== 'bots' && m.module !== 'external') ?? [];

  return (
    <div className="space-y-6">
      {/* Saludo, como en la home de la app */}
      <section className="brand-gradient relative overflow-hidden rounded-3xl p-6 text-white md:p-8">
        <div className="pointer-events-none absolute -right-10 -top-10 h-56 w-56 rounded-full bg-white/10" />
        <div className="pointer-events-none absolute -bottom-16 right-40 h-40 w-40 rounded-full bg-white/5" />
        <div className="relative flex items-center justify-between gap-4">
          <div className="max-w-xl">
            <p className="text-sm font-medium text-white/80">Panel de administración</p>
            <h1 className="mt-1 text-2xl font-bold md:text-3xl">¡Hola, {firstName}!</h1>
            <p className="mt-2 text-white/85">
              {data
                ? `En los últimos ${data.days} días se unieron ${formatNumber(data.users.newInRange)} usuarios y hubo ${formatNumber(data.activity.aiQueriesInRange)} consultas a la IA.`
                : 'Esto es lo que está pasando en NutriLife.'}
            </p>
            <RangeTabs value={days} onChange={setDays} className="mt-5" />
          </div>
          <Nutria mood="saludando" bob className="hidden h-36 w-36 shrink-0 sm:block md:h-44 md:w-44" />
        </div>
      </section>

      {loading && !data ? (
        <LoadingState label="Cargando estadísticas..." />
      ) : error ? (
        <ErrorState message={error} onRetry={() => load(days)} />
      ) : data ? (
        <div className={loading ? 'pointer-events-none space-y-6 opacity-60 transition-opacity' : 'space-y-6'}>
          {/* KPIs */}
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard
              title="Usuarios registrados"
              value={data.users.total}
              icon={Users}
              hint={`+${formatNumber(data.users.newInRange)} en ${data.days} días · ${data.users.pro} PRO`}
            />
            <StatCard
              title="Usuarios activos (7 días)"
              value={data.activity.active7d}
              icon={UserCheck}
              tone="sky"
              hint={`${data.activity.active24h} en las últimas 24 h`}
            />
            <StatCard
              title="Consultas a la IA"
              value={data.activity.aiQueriesInRange}
              icon={Sparkles}
              tone="violet"
              hint={`${data.activity.aiQueries24h} hoy · ${formatNumber(data.activity.aiQueriesTotal)} en total`}
            />
            <StatCard
              title="Errores del servidor"
              value={data.activity.errorsInRange}
              icon={AlertTriangle}
              tone={data.activity.errors24h > 0 ? 'red' : 'teal'}
              hint={`${data.activity.errors24h} en 24 h · ${data.activity.failedLoginsInRange} logins fallidos`}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-3">
            {/* Actividad diaria */}
            <Card className="lg:col-span-2">
              <CardHeader className="pb-2">
                <CardTitle>Actividad diaria</CardTitle>
                <p className="text-sm text-muted-foreground">Usuarios activos y consultas a la IA por día</p>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={280}>
                  <ComposedChart data={data.series} margin={{ left: -20, right: 8, top: 8 }}>
                    <defs>
                      <linearGradient id="fillActive" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={CHART_COLORS.users} stopOpacity={0.35} />
                        <stop offset="95%" stopColor={CHART_COLORS.users} stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke={CHART_COLORS.grid} vertical={false} />
                    <XAxis dataKey="day" tickFormatter={formatAxisDay} minTickGap={20} {...axisProps} />
                    <YAxis allowDecimals={false} {...axisProps} />
                    <Tooltip contentStyle={chartTooltipStyle} labelFormatter={(d) => formatAxisDay(String(d))} />
                    <Legend wrapperStyle={{ fontSize: 12 }} />
                    <Area
                      type="monotone"
                      dataKey="activeUsers"
                      name="Usuarios activos"
                      stroke={CHART_COLORS.users}
                      strokeWidth={2}
                      fill="url(#fillActive)"
                    />
                    <Bar dataKey="aiQueries" name="Consultas IA" fill={CHART_COLORS.ai} radius={[4, 4, 0, 0]} barSize={10} />
                  </ComposedChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Uso por módulo */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>¿Qué usan más?</CardTitle>
                <p className="text-sm text-muted-foreground">Peticiones por sección de la app</p>
              </CardHeader>
              <CardContent>
                {appModules.length === 0 ? (
                  <EmptyState title="Sin actividad" description="Nadie usó la app en este periodo." />
                ) : (
                  <ModuleBars data={appModules} />
                )}
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 xl:grid-cols-2">
            <WaterCard data={data} />
            <CaloriesCard data={data} />
          </div>

          <div className="grid gap-6 lg:grid-cols-3">
            {/* Top IA */}
            <Card>
              <CardHeader className="flex-row items-center justify-between space-y-0 pb-3">
                <div>
                  <CardTitle>Quién más usa la IA</CardTitle>
                  <p className="mt-1 text-sm text-muted-foreground">Consultas en {data.days} días</p>
                </div>
                <Nutria mood="pensando" className="h-12 w-12" />
              </CardHeader>
              <CardContent>
                {data.topAiUsers.length === 0 ? (
                  <EmptyState mood="sentada" title="Sin consultas" description="Nadie habló con la nutria en este periodo." />
                ) : (
                  <ol className="space-y-1">
                    {data.topAiUsers.map((u, index) => {
                      const max = data.topAiUsers[0].aiQueries;
                      return (
                        <li key={u.userId}>
                          <Link
                            to={`/users/${u.userId}`}
                            className="flex items-center gap-3 rounded-xl p-2 transition-colors hover:bg-accent"
                          >
                            <span className="w-4 text-center text-xs font-bold text-muted-foreground">{index + 1}</span>
                            <UserAvatar name={u.name} userId={u.userId} className="h-8 w-8" />
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-semibold">{u.name}</p>
                              <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-muted">
                                <div
                                  className="h-full rounded-full bg-primary"
                                  style={{ width: `${(u.aiQueries / max) * 100}%` }}
                                />
                              </div>
                            </div>
                            <span className="text-sm font-bold tabular-nums">{u.aiQueries}</span>
                          </Link>
                        </li>
                      );
                    })}
                  </ol>
                )}
              </CardContent>
            </Card>

            {/* Registros */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>Nuevos registros</CardTitle>
                <p className="text-sm text-muted-foreground">
                  {formatNumber(data.users.newInRange)} en {data.days} días · {data.users.new7d} esta semana
                </p>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={150}>
                  <BarChart data={data.series} margin={{ left: -28, right: 4 }}>
                    <XAxis dataKey="day" tickFormatter={formatAxisDay} minTickGap={24} {...axisProps} />
                    <YAxis allowDecimals={false} {...axisProps} />
                    <Tooltip
                      contentStyle={chartTooltipStyle}
                      cursor={{ fill: CHART_COLORS.grid }}
                      labelFormatter={(d) => formatAxisDay(String(d))}
                    />
                    <Bar dataKey="registrations" name="Registros" fill={CHART_COLORS.registrations} radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
                <ul className="mt-3 space-y-1">
                  {data.recentUsers.slice(0, 4).map((u) => (
                    <li key={u.userId}>
                      <Link
                        to={`/users/${u.userId}`}
                        className="flex items-center gap-3 rounded-xl p-2 transition-colors hover:bg-accent"
                      >
                        <UserAvatar name={u.name} userId={u.userId} className="h-8 w-8" />
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-semibold">{u.name}</p>
                          <p className="truncate text-xs text-muted-foreground">{u.goal ?? 'Sin objetivo'}</p>
                        </div>
                        <span className="shrink-0 text-xs text-muted-foreground">{formatRelative(u.createdAt)}</span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>

            {/* Contenido + bots */}
            <div className="space-y-6">
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle>Lo que crean los usuarios</CardTitle>
                </CardHeader>
                <CardContent className="grid grid-cols-2 gap-3">
                  <MiniStat icon={MessageCircle} label="Mensajes al chat" value={data.content.chatMessages} />
                  <MiniStat icon={MessageCircle} label="Conversaciones" value={data.content.chatSessions} />
                  <MiniStat icon={ChefHat} label="Recetas guardadas" value={data.content.recipesSaved} />
                  <MiniStat icon={ChefHat} label="Comidas registradas" value={data.content.mealItems} />
                </CardContent>
              </Card>

              <Card className="relative overflow-hidden border-red-500/20">
                <CardContent className="p-5">
                  <Nutria mood="enojada" className="absolute -bottom-2 -right-2 h-24 w-24 opacity-90" />
                  <div className="flex items-center gap-2 text-red-400">
                    <Bug className="h-4 w-4" />
                    <p className="text-sm font-semibold">Escaneos de bots</p>
                  </div>
                  <p className="mt-2 text-3xl font-bold tabular-nums">
                    {formatNumber(data.activity.botHitsInRange)}
                  </p>
                  <p className="mt-1 max-w-[70%] text-xs text-muted-foreground">
                    Peticiones a rutas que no existen, como /.env o /wp-login.php, en {data.days} días. Además hubo{' '}
                    {formatNumber(data.activity.externalHitsInRange)} visitas externas a la raíz de la API
                    (monitores, buscadores o alguien abriendo la URL). Ninguna viene de la app: se separan de las{' '}
                    {formatNumber(data.activity.apiRequestsInRange)} peticiones reales.
                  </p>
                  <Link
                    to="/events?module=bots"
                    className="mt-3 inline-flex items-center gap-1 text-xs font-semibold text-red-400 hover:underline"
                  >
                    Ver escaneos <ArrowRight className="h-3 w-3" />
                  </Link>
                </CardContent>
              </Card>
            </div>
          </div>

          <div className="flex justify-end">
            <Link to="/users" className="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:underline">
              Ver todos los usuarios <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function WaterCard({ data }: { data: Overview }) {
  const { water } = data;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2">
          <Droplet className="h-5 w-5 text-sky-400" />
          Agua
        </CardTitle>
        <p className="text-sm text-muted-foreground">
          {formatNumber(water.users)} usuarios han registrado agua alguna vez · {formatNumber(water.users7d)} en los
          últimos 7 días
        </p>
      </CardHeader>
      <CardContent className="grid gap-6 lg:grid-cols-3">
        <div className="grid grid-cols-2 gap-3 lg:col-span-2">
          <MiniStat icon={Users} label={`Registran agua (${data.days} días)`} value={water.usersInRange} />
          <MiniStat icon={Flame} label="Rachas activas ahora" value={water.activeStreaks} />
          <MiniStat icon={Droplet} label={`Días con la meta cumplida (${data.days} días)`} value={water.goalDaysInRange} />
          <MiniStat
            icon={Droplet}
            label={`Vasos en ${formatNumber(water.daysInRange)} días registrados`}
            value={water.glassesInRange}
          />
        </div>
        <TopStreaks users={water.topStreaks} emptyText="Nadie cumplió la meta de agua hoy ni ayer." />
      </CardContent>
    </Card>
  );
}

function CaloriesCard({ data }: { data: Overview }) {
  const { calories } = data;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2">
          <Flame className="h-5 w-5 text-orange-400" />
          Calorías
        </CardTitle>
        <p className="text-sm text-muted-foreground">
          Un día cuenta si lo comido cae en el rango de la meta: bajar 70–100 %, mantener 85–115 %, subir 100–130 %.
          La misma regla que la app.
        </p>
      </CardHeader>
      <CardContent className="grid gap-6 lg:grid-cols-3">
        <div className="grid grid-cols-2 gap-3 lg:col-span-2">
          <MiniStat icon={Flame} label="Rachas calóricas activas ahora" value={calories.activeStreaks} />
        </div>
        <TopStreaks users={calories.topStreaks} emptyText="Nadie tiene una racha calórica viva hoy ni ayer." />
      </CardContent>
    </Card>
  );
}

function TopStreaks({ users, emptyText }: { users: WaterStreakUser[]; emptyText: string }) {
  return (
    <div>
      <p className="text-sm font-semibold">Rachas más largas ahora</p>
      {users.length === 0 ? (
        <EmptyState mood="sentada" title="Sin rachas" description={emptyText} />
      ) : (
        <ol className="mt-2 space-y-1">
          {users.map((u) => (
            <li key={u.userId}>
              <Link
                to={`/users/${u.userId}`}
                className="flex items-center gap-3 rounded-xl p-2 transition-colors hover:bg-accent"
              >
                <UserAvatar name={u.name} userId={u.userId} className="h-8 w-8" />
                <p className="min-w-0 flex-1 truncate text-sm font-semibold">{u.name}</p>
                <PlanBadge plan={u.plan} />
                <span className="flex items-center gap-1 text-sm font-bold tabular-nums">
                  <Flame className="h-4 w-4 text-orange-400" />
                  {u.currentStreak}
                </span>
              </Link>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}

function MiniStat({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Users;
  label: string;
  value: number;
}) {
  return (
    <div className="rounded-xl bg-muted/60 p-3">
      <Icon className="h-4 w-4 text-primary" />
      <p className="mt-2 text-xl font-bold tabular-nums">{formatNumber(value)}</p>
      <p className="text-xs text-muted-foreground">{label}</p>
    </div>
  );
}
