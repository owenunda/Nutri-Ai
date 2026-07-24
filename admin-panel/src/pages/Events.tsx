import { useCallback, useEffect, useState } from 'react';
import { Loader2, RefreshCw, Search, Trash2 } from 'lucide-react';
import { fetchEvents, runRetention } from '../lib/events.api';
import { getErrorMessage } from '../lib/api';
import type { ActivityEvent, EventFilters } from '../types/event';
import { formatDate } from '../lib/utils';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Select } from '../components/ui/select';
import { Card, CardContent } from '../components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table';
import { CategoryBadge, StatusBadge } from '../components/CategoryBadge';

const CATEGORIES = ['AUTH', 'AI', 'ERROR', 'CRUD', 'SYSTEM'];
const PAGE_SIZE = 20;

const emptyFilters: EventFilters = {
  type: '',
  category: '',
  userId: '',
  from: '',
  to: '',
};

export default function Events() {
  const [filters, setFilters] = useState<EventFilters>(emptyFilters);
  const [page, setPage] = useState(1);
  const [items, setItems] = useState<ActivityEvent[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<number | null>(null);

  const load = useCallback(
    async (currentPage: number, currentFilters: EventFilters) => {
      setLoading(true);
      setError(null);
      try {
        const res = await fetchEvents({
          ...currentFilters,
          page: currentPage,
          limit: PAGE_SIZE,
        });
        setItems(res.items);
        setTotal(res.total);
      } catch (err) {
        setError(getErrorMessage(err));
      } finally {
        setLoading(false);
      }
    },
    []
  );

  useEffect(() => {
    load(page, filters);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const applyFilters = () => {
    if (page === 1) {
      load(1, filters);
    } else {
      setPage(1);
    }
  };

  const clearFilters = () => {
    setFilters(emptyFilters);
    setPage(1);
    load(1, emptyFilters);
  };

  const handleRetention = async () => {
    const input = window.prompt(
      'Eliminar eventos más antiguos que N días. Introduce el número de días:',
      '30'
    );
    if (input === null) return;
    const days = Number(input);
    if (!Number.isInteger(days) || days <= 0) {
      window.alert('Introduce un número entero de días mayor que 0.');
      return;
    }
    if (!window.confirm(`¿Eliminar todos los eventos con más de ${days} días? Esta acción no se puede deshacer.`)) {
      return;
    }
    try {
      const result = await runRetention(days);
      window.alert(`Se eliminaron ${result.deleted} eventos.`);
      load(page, filters);
    } catch (err) {
      window.alert(getErrorMessage(err));
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Eventos</h1>
          <p className="text-muted-foreground">{total} eventos registrados</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => load(page, filters)}>
            <RefreshCw className="h-4 w-4" />
            Refrescar
          </Button>
          <Button variant="destructive" size="sm" onClick={handleRetention}>
            <Trash2 className="h-4 w-4" />
            Retención
          </Button>
        </div>
      </div>

      {/* Filtros */}
      <Card>
        <CardContent className="grid gap-4 p-4 sm:grid-cols-2 lg:grid-cols-6">
          <div className="space-y-1.5">
            <Label htmlFor="f-type">Tipo</Label>
            <Input
              id="f-type"
              placeholder="LOGIN, AI_REQUEST..."
              value={filters.type ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, type: e.target.value }))}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="f-cat">Categoría</Label>
            <Select
              id="f-cat"
              value={filters.category ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, category: e.target.value }))}
            >
              <option value="">Todas</option>
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="f-user">User ID</Label>
            <Input
              id="f-user"
              type="number"
              placeholder="Ej: 4"
              value={filters.userId ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, userId: e.target.value }))}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="f-from">Desde</Label>
            <Input
              id="f-from"
              type="date"
              value={filters.from ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, from: e.target.value }))}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="f-to">Hasta</Label>
            <Input
              id="f-to"
              type="date"
              value={filters.to ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, to: e.target.value }))}
            />
          </div>
          <div className="flex items-end gap-2">
            <Button className="flex-1" onClick={applyFilters}>
              <Search className="h-4 w-4" />
              Filtrar
            </Button>
            <Button variant="outline" onClick={clearFilters}>
              Limpiar
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Tabla */}
      <Card>
        <CardContent className="p-0">
          {error ? (
            <div className="p-6 text-sm text-destructive">{error}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Fecha</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead>Categoría</TableHead>
                  <TableHead>Usuario</TableHead>
                  <TableHead>Método</TableHead>
                  <TableHead>Ruta</TableHead>
                  <TableHead>Estado</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-32 text-center text-muted-foreground">
                      <Loader2 className="mx-auto h-5 w-5 animate-spin" />
                    </TableCell>
                  </TableRow>
                ) : items.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-32 text-center text-muted-foreground">
                      No hay eventos que coincidan con los filtros.
                    </TableCell>
                  </TableRow>
                ) : (
                  items.map((ev) => (
                    <TableRow
                      key={ev.eventId}
                      className="cursor-pointer"
                      onClick={() => setExpanded(expanded === ev.eventId ? null : ev.eventId)}
                    >
                      <TableCell className="whitespace-nowrap text-muted-foreground">
                        {formatDate(ev.createdAt)}
                      </TableCell>
                      <TableCell className="font-medium">{ev.eventType}</TableCell>
                      <TableCell>
                        <CategoryBadge category={ev.category} />
                      </TableCell>
                      <TableCell>{ev.userId ?? '—'}</TableCell>
                      <TableCell className="text-muted-foreground">{ev.method ?? '—'}</TableCell>
                      <TableCell className="max-w-[220px] truncate text-muted-foreground">
                        {ev.path ?? '—'}
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={ev.statusCode} />
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Detalle de metadata del evento expandido */}
      {expanded !== null && (() => {
        const ev = items.find((e) => e.eventId === expanded);
        if (!ev) return null;
        return (
          <Card>
            <CardContent className="p-4">
              <p className="mb-2 text-sm font-medium">
                Metadata del evento #{ev.eventId} · IP: {ev.ipAddress ?? '—'}
              </p>
              <pre className="overflow-auto rounded-md bg-muted p-3 text-xs">
                {JSON.stringify(ev.metadata, null, 2)}
              </pre>
            </CardContent>
          </Card>
        );
      })()}

      {/* Paginación */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Página {page} de {totalPages}
        </p>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            disabled={page <= 1 || loading}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
          >
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
    </div>
  );
}
