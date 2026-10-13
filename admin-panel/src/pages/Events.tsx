import { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { Loader2, RefreshCw, Search, Trash2 } from 'lucide-react';
import { fetchEvents, runRetention } from '../lib/events.api';
import { getErrorMessage } from '../lib/api';
import { MODULES, MODULE_KEYS } from '../lib/modules';
import type { ActivityEvent, EventFilters } from '../types/event';
import { cn, formatDate, formatNumber } from '../lib/utils';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Select } from '../components/ui/select';
import { Card, CardContent } from '../components/ui/card';
import { Dialog } from '../components/ui/dialog';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table';
import { CategoryBadge, ModuleBadge, StatusBadge } from '../components/CategoryBadge';
import { EmptyState, ErrorState } from '../components/States';
import { Nutria } from '../components/Nutria';

const CATEGORIES = ['AUTH', 'AI', 'ERROR', 'CRUD', 'SYSTEM'];
const PAGE_SIZE = 25;

const emptyFilters: EventFilters = {
  type: '',
  category: '',
  module: '',
  userId: '',
  from: '',
  to: '',
  hideBots: true,
  hideReads: false,
};

/** Los filtros iniciales pueden venir en la URL (?userId=8, ?module=bots). */
function filtersFromUrl(params: URLSearchParams): EventFilters {
  return {
    ...emptyFilters,
    userId: params.get('userId') ?? '',
    module: params.get('module') ?? '',
  };
}

export default function Events() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [filters, setFilters] = useState<EventFilters>(() => filtersFromUrl(searchParams));
  const [applied, setApplied] = useState<EventFilters>(filters);
  const [page, setPage] = useState(1);
  const [items, setItems] = useState<ActivityEvent[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<number | null>(null);
  const [retentionOpen, setRetentionOpen] = useState(false);
  const requestId = useRef(0);

  // Los enlaces de otras páginas (?userId=...) cambian la URL sin desmontar esta.
  const lastQuery = useRef(searchParams.toString());
  useEffect(() => {
    if (searchParams.toString() === lastQuery.current) return;
    lastQuery.current = searchParams.toString();
    const next = filtersFromUrl(searchParams);
    setFilters(next);
    setApplied(next);
    setPage(1);
  }, [searchParams]);

  const load = useCallback(async () => {
    const id = ++requestId.current;
    setLoading(true);
    setError(null);
    try {
      const res = await fetchEvents({ ...applied, page, limit: PAGE_SIZE });
      if (id !== requestId.current) return;
      setItems(res.items);
      setTotal(res.total);
    } catch (err) {
      if (id === requestId.current) setError(getErrorMessage(err));
    } finally {
      if (id === requestId.current) setLoading(false);
    }
  }, [applied, page]);

  useEffect(() => {
    load();
  }, [load]);

  const apply = (next: EventFilters) => {
    setApplied(next);
    setPage(1);
    setExpanded(null);
  };

  const clearFilters = () => {
    setFilters(emptyFilters);
    if (searchParams.toString()) setSearchParams({});
    else apply(emptyFilters);
  };

  /** Los interruptores se aplican al momento. */
  const toggle = (key: 'hideBots' | 'hideReads') => {
    const next = { ...filters, [key]: !filters[key] };
    setFilters(next);
    apply({ ...applied, [key]: next[key] });
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const set = (key: keyof EventFilters) => (e: { target: { value: string } }) =>
    setFilters((f) => ({ ...f, [key]: e.target.value }));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <Nutria mood="atenta" className="h-14 w-14" />
          <div>
            <h1 className="text-2xl font-bold">Eventos</h1>
            <p className="text-muted-foreground">{formatNumber(total)} eventos con estos filtros</p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={load} disabled={loading}>
            <RefreshCw className={cn('h-4 w-4', loading && 'animate-spin')} />
            Refrescar
          </Button>
          <Button variant="outline" size="sm" onClick={() => setRetentionOpen(true)} className="text-red-400">
            <Trash2 className="h-4 w-4" />
            Limpiar antiguos
          </Button>
        </div>
      </div>

      {/* Atajos por módulo */}
      <div className="flex flex-wrap gap-2">
        {['', ...MODULE_KEYS].map((key) => {
          const meta = key ? MODULES[key as keyof typeof MODULES] : null;
          const Icon = meta?.icon;
          const active = (applied.module ?? '') === key;
          return (
            <button
              key={key || 'all'}
              type="button"
              onClick={() => {
                setFilters((f) => ({ ...f, module: key }));
                apply({ ...applied, module: key });
              }}
              className={cn(
                'flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-semibold transition-colors',
                active ? 'border-transparent text-white' : 'text-muted-foreground hover:text-foreground'
              )}
              style={active ? { backgroundColor: meta?.color ?? 'hsl(142 71% 35%)' } : undefined}
            >
              {Icon && <Icon className="h-3.5 w-3.5" />}
              {meta?.label ?? 'Todos'}
            </button>
          );
        })}
      </div>

      {/* Filtros */}
      <Card>
        <CardContent className="space-y-4 p-4">
          <form
            className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5"
            onSubmit={(e) => {
              e.preventDefault();
              apply(filters);
            }}
          >
            <div className="space-y-1.5">
              <Label htmlFor="f-type">Tipo</Label>
              <Input id="f-type" placeholder="LOGIN, CRUD_CREATE..." value={filters.type ?? ''} onChange={set('type')} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="f-cat">Categoría</Label>
              <Select id="f-cat" value={filters.category ?? ''} onChange={set('category')}>
                <option value="">Todas</option>
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="f-user">ID de usuario</Label>
              <Input id="f-user" type="number" min={1} placeholder="Ej: 8" value={filters.userId ?? ''} onChange={set('userId')} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="f-from">Desde</Label>
              <Input id="f-from" type="date" value={filters.from ?? ''} onChange={set('from')} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="f-to">Hasta</Label>
              <Input id="f-to" type="date" value={filters.to ?? ''} onChange={set('to')} />
            </div>
            <div className="flex flex-wrap items-center gap-4 sm:col-span-2 lg:col-span-5">
              <Switch label="Ocultar escaneos y tráfico externo" checked={!!filters.hideBots} onChange={() => toggle('hideBots')} />
              <Switch label="Ocultar lecturas (GET)" checked={!!filters.hideReads} onChange={() => toggle('hideReads')} />
              <div className="ml-auto flex gap-2">
                <Button type="button" variant="outline" onClick={clearFilters}>
                  Limpiar
                </Button>
                <Button type="submit">
                  <Search className="h-4 w-4" />
                  Filtrar
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Tabla */}
      <Card>
        <CardContent className="p-0">
          {error ? (
            <ErrorState message={error} onRetry={load} />
          ) : !loading && items.length === 0 ? (
            <EmptyState
              mood="sentada"
              title="No hay eventos"
              description="Nada coincide con estos filtros. Prueba a quitar alguno."
            />
          ) : (
            <Table className={cn(loading && items.length > 0 && 'opacity-60')}>
              <TableHeader>
                <TableRow>
                  <TableHead>Fecha</TableHead>
                  <TableHead>Sección</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead>Usuario</TableHead>
                  <TableHead className="hidden lg:table-cell">Ruta</TableHead>
                  <TableHead>Estado</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading && items.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="h-32 text-center text-muted-foreground">
                      <Loader2 className="mx-auto h-5 w-5 animate-spin" />
                    </TableCell>
                  </TableRow>
                ) : (
                  items.map((ev) => (
                    <EventRow
                      key={ev.eventId}
                      ev={ev}
                      expanded={expanded === ev.eventId}
                      onToggle={() => setExpanded(expanded === ev.eventId ? null : ev.eventId)}
                    />
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Paginación */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Página {page} de {formatNumber(totalPages)}
        </p>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" disabled={page <= 1 || loading} onClick={() => setPage((p) => p - 1)}>
            Anterior
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= totalPages || loading}
            onClick={() => setPage((p) => p + 1)}
          >
            Siguiente
          </Button>
        </div>
      </div>

      <RetentionDialog open={retentionOpen} onClose={() => setRetentionOpen(false)} onDone={load} />
    </div>
  );
}

function EventRow({ ev, expanded, onToggle }: { ev: ActivityEvent; expanded: boolean; onToggle: () => void }) {
  return (
    <>
      <TableRow className={cn('cursor-pointer', expanded && 'bg-accent/50')} onClick={onToggle}>
        <TableCell className="whitespace-nowrap text-muted-foreground">{formatDate(ev.createdAt)}</TableCell>
        <TableCell>
          <ModuleBadge module={ev.module} />
        </TableCell>
        <TableCell className="font-medium">{ev.eventType}</TableCell>
        <TableCell>
          {ev.userId ? (
            <Link
              to={`/users/${ev.userId}`}
              onClick={(e) => e.stopPropagation()}
              className="font-medium hover:text-primary hover:underline"
            >
              {ev.userName ?? `#${ev.userId}`}
            </Link>
          ) : (
            <span className="text-muted-foreground">Anónimo</span>
          )}
        </TableCell>
        <TableCell className="hidden max-w-[280px] truncate font-mono text-xs text-muted-foreground lg:table-cell">
          {ev.path ? `${ev.method ?? ''} ${ev.path}` : '—'}
        </TableCell>
        <TableCell>
          <StatusBadge status={ev.statusCode} />
        </TableCell>
      </TableRow>
      {expanded && (
        <TableRow className="hover:bg-transparent">
          <TableCell colSpan={6} className="bg-background/60">
            <div className="grid gap-4 py-2 text-sm md:grid-cols-[auto_1fr]">
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1">
                <dt className="text-muted-foreground">Evento</dt>
                <dd>#{ev.eventId}</dd>
                <dt className="text-muted-foreground">Categoría</dt>
                <dd>
                  <CategoryBadge category={ev.category} />
                </dd>
                <dt className="text-muted-foreground">Usuario</dt>
                <dd>{ev.userEmail ?? '—'}</dd>
                <dt className="text-muted-foreground">Ruta</dt>
                <dd className="break-all font-mono text-xs">{ev.path ? `${ev.method} ${ev.path}` : '—'}</dd>
                <dt className="text-muted-foreground">IP</dt>
                <dd className="font-mono text-xs">{ev.ipAddress ?? '—'}</dd>
              </dl>
              <pre className="max-h-64 overflow-auto rounded-xl bg-muted p-3 text-xs">
                {JSON.stringify(ev.metadata, null, 2)}
              </pre>
            </div>
          </TableCell>
        </TableRow>
      )}
    </>
  );
}

function Switch({ label, checked, onChange }: { label: string; checked: boolean; onChange: () => void }) {
  return (
    <label className="flex cursor-pointer items-center gap-2 text-sm">
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={onChange}
        className={cn(
          'relative h-5 w-9 rounded-full transition-colors',
          checked ? 'bg-primary' : 'bg-muted'
        )}
      >
        <span
          className={cn(
            'absolute left-0.5 top-0.5 h-4 w-4 rounded-full bg-white transition-transform',
            checked && 'translate-x-4'
          )}
        />
      </button>
      {label}
    </label>
  );
}

function RetentionDialog({ open, onClose, onDone }: { open: boolean; onClose: () => void; onDone: () => void }) {
  const [days, setDays] = useState('30');
  const [onlyBots, setOnlyBots] = useState(false);
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const close = () => {
    setResult(null);
    setError(null);
    onClose();
  };

  const run = async () => {
    const n = Number(days);
    if (!Number.isInteger(n) || n <= 0) {
      setError('Introduce un número entero de días mayor que 0.');
      return;
    }
    setRunning(true);
    setError(null);
    try {
      const res = await runRetention(n, onlyBots ? 'HTTP_REQUEST' : undefined);
      setResult(`Se eliminaron ${formatNumber(res.deleted)} eventos.`);
      onDone();
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setRunning(false);
    }
  };

  return (
    <Dialog open={open} onClose={close} title="Limpiar eventos antiguos">
      {result ? (
        <div className="flex flex-col items-center gap-3 text-center">
          <Nutria mood="celebracion" className="h-24 w-24" />
          <p className="font-semibold">{result}</p>
          <Button onClick={close}>Listo</Button>
        </div>
      ) : (
        <>
          <p className="text-sm text-muted-foreground">
            Borra para siempre los eventos con más antigüedad que la indicada. No se puede deshacer.
          </p>
          <div className="mt-4 space-y-1.5">
            <Label htmlFor="ret-days">Más antiguos que (días)</Label>
            <Input id="ret-days" type="number" min={1} value={days} onChange={(e) => setDays(e.target.value)} />
          </div>
          <label className="mt-3 flex items-center gap-2 text-sm">
            <input type="checkbox" checked={onlyBots} onChange={(e) => setOnlyBots(e.target.checked)} />
            Solo lecturas (HTTP_REQUEST), que incluye la mayoría de bots
          </label>
          {error && <p className="mt-3 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <div className="mt-6 flex justify-end gap-2">
            <Button variant="outline" onClick={close} disabled={running}>
              Cancelar
            </Button>
            <Button variant="destructive" onClick={run} disabled={running}>
              {running && <Loader2 className="h-4 w-4 animate-spin" />}
              Eliminar
            </Button>
          </div>
        </>
      )}
    </Dialog>
  );
}
