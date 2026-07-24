import { useEffect, useState, type ComponentType } from 'react';
import {
  Activity,
  AlertTriangle,
  KeyRound,
  Sparkles,
  Loader2,
} from 'lucide-react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { fetchStats } from '../lib/events.api';
import { getErrorMessage } from '../lib/api';
import type { EventStats } from '../types/event';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';

const PRIMARY = 'hsl(142 71% 45%)';

function StatCard({
  title,
  value,
  icon: Icon,
}: {
  title: string;
  value: number | string;
  icon: ComponentType<{ className?: string }>;
}) {
  return (
    <Card>
      <CardContent className="flex items-center justify-between p-6">
        <div>
          <p className="text-sm text-muted-foreground">{title}</p>
          <p className="mt-1 text-2xl font-bold">{value}</p>
        </div>
        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary/15">
          <Icon className="h-5 w-5 text-primary" />
        </div>
      </CardContent>
    </Card>
  );
}

function categoryCount(stats: EventStats, category: string): number {
  return stats.byCategory.find((c) => c.category === category)?.count ?? 0;
}

const chartTooltipStyle = {
  backgroundColor: 'hsl(240 10% 5.9%)',
  border: '1px solid hsl(240 3.7% 15.9%)',
  borderRadius: '0.5rem',
  color: 'hsl(0 0% 98%)',
  fontSize: '0.8rem',
};

export default function Dashboard() {
  const [stats, setStats] = useState<EventStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchStats({})
      .then((data) => {
        if (active) setStats(data);
      })
      .catch((err) => {
        if (active) setError(getErrorMessage(err));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center text-muted-foreground">
        <Loader2 className="mr-2 h-5 w-5 animate-spin" /> Cargando estadísticas...
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">
        {error}
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">Resumen de la actividad registrada</p>
      </div>

      {/* Stat cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total de eventos" value={stats.total} icon={Activity} />
        <StatCard title="Autenticación" value={categoryCount(stats, 'AUTH')} icon={KeyRound} />
        <StatCard title="Uso de IA" value={categoryCount(stats, 'AI')} icon={Sparkles} />
        <StatCard
          title="Errores del sistema"
          value={categoryCount(stats, 'ERROR')}
          icon={AlertTriangle}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Eventos por día */}
        <Card>
          <CardHeader>
            <CardTitle>Eventos por día</CardTitle>
          </CardHeader>
          <CardContent>
            {stats.byDay.length === 0 ? (
              <EmptyChart />
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <AreaChart data={stats.byDay} margin={{ left: -20, right: 8 }}>
                  <defs>
                    <linearGradient id="fillDay" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={PRIMARY} stopOpacity={0.35} />
                      <stop offset="95%" stopColor={PRIMARY} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(240 3.7% 15.9%)" />
                  <XAxis dataKey="day" tick={{ fontSize: 12 }} stroke="hsl(240 5% 64.9%)" />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12 }} stroke="hsl(240 5% 64.9%)" />
                  <Tooltip contentStyle={chartTooltipStyle} />
                  <Area
                    type="monotone"
                    dataKey="count"
                    stroke={PRIMARY}
                    strokeWidth={2}
                    fill="url(#fillDay)"
                    name="Eventos"
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Eventos por tipo */}
        <Card>
          <CardHeader>
            <CardTitle>Eventos por tipo</CardTitle>
          </CardHeader>
          <CardContent>
            {stats.byType.length === 0 ? (
              <EmptyChart />
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={stats.byType} margin={{ left: -20, right: 8 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(240 3.7% 15.9%)" />
                  <XAxis
                    dataKey="eventType"
                    tick={{ fontSize: 11 }}
                    stroke="hsl(240 5% 64.9%)"
                    interval={0}
                    angle={-20}
                    textAnchor="end"
                    height={60}
                  />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12 }} stroke="hsl(240 5% 64.9%)" />
                  <Tooltip contentStyle={chartTooltipStyle} cursor={{ fill: 'hsl(240 3.7% 15.9%)' }} />
                  <Bar dataKey="count" fill={PRIMARY} radius={[4, 4, 0, 0]} name="Eventos" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function EmptyChart() {
  return (
    <div className="flex h-[280px] items-center justify-center text-sm text-muted-foreground">
      Aún no hay datos para mostrar.
    </div>
  );
}
