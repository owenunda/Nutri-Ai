import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ChevronRight, Search, Sparkles } from 'lucide-react';
import { fetchUsers } from '../lib/admin.api';
import { getErrorMessage } from '../lib/api';
import { formatDay, formatNumber, formatRelative } from '../lib/utils';
import type { AdminUser, Plan, UserSort } from '../types/admin';
import { Card, CardContent } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Select } from '../components/ui/select';
import { Button } from '../components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table';
import { UserAvatar } from '../components/UserAvatar';
import { AuthMethodBadge, PlanBadge } from '../components/CategoryBadge';
import { EmptyState, ErrorState, LoadingState } from '../components/States';
import { Nutria } from '../components/Nutria';

const PAGE_SIZE = 25;

const SORTS: { value: UserSort; label: string }[] = [
  { value: 'recent', label: 'Más recientes' },
  { value: 'ai', label: 'Más consultas a la IA' },
  { value: 'activity', label: 'Actividad reciente' },
  { value: 'name', label: 'Nombre (A-Z)' },
];

/** Activo hace menos de 24 h → punto verde. */
function isOnlineRecently(iso: string | null) {
  return !!iso && Date.now() - new Date(iso).getTime() < 24 * 3600 * 1000;
}

export default function Users() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [plan, setPlan] = useState<Plan | ''>('');
  const [sort, setSort] = useState<UserSort>('recent');
  const [page, setPage] = useState(1);
  const [items, setItems] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Espera a que el admin deje de escribir antes de buscar.
  useEffect(() => {
    const timer = window.setTimeout(() => {
      setDebouncedSearch(search.trim());
      setPage(1);
    }, 300);
    return () => window.clearTimeout(timer);
  }, [search]);

  // Solo la última petición actualiza la tabla, aunque las respuestas lleguen desordenadas.
  const requestId = useRef(0);

  const load = useCallback(async () => {
    const id = ++requestId.current;
    setLoading(true);
    setError(null);
    try {
      const res = await fetchUsers({ search: debouncedSearch, plan, sort, page, limit: PAGE_SIZE });
      if (id !== requestId.current) return;
      setItems(res.items);
      setTotal(res.total);
    } catch (err) {
      if (id === requestId.current) setError(getErrorMessage(err));
    } finally {
      if (id === requestId.current) setLoading(false);
    }
  }, [debouncedSearch, plan, sort, page]);

  useEffect(() => {
    load();
  }, [load]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">Usuarios</h1>
          <p className="text-muted-foreground">
            {formatNumber(total)} {total === 1 ? 'usuario' : 'usuarios'}
            {debouncedSearch || plan ? ' con estos filtros' : ' registrados'}
          </p>
        </div>
        <Nutria mood="atenta" className="h-16 w-16" />
      </div>

      <Card>
        <CardContent className="grid gap-3 p-4 sm:grid-cols-[1fr_auto_auto]">
          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Buscar por nombre, correo o id..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
              aria-label="Buscar usuarios"
            />
          </div>
          <Select value={plan} onChange={(e) => {
              setPlan(e.target.value as Plan | '');
              setPage(1);
            }} aria-label="Plan">
            <option value="">Todos los planes</option>
            <option value="FREE">FREE</option>
            <option value="PRO">PRO</option>
          </Select>
          <Select value={sort} onChange={(e) => {
              setSort(e.target.value as UserSort);
              setPage(1);
            }} aria-label="Ordenar">
            {SORTS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </Select>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-0">
          {error ? (
            <ErrorState message={error} onRetry={load} />
          ) : loading && items.length === 0 ? (
            <LoadingState label="Buscando usuarios..." />
          ) : items.length === 0 ? (
            <EmptyState
              mood="pensando"
              title="No encontré a nadie"
              description="Prueba con otro nombre, correo o quita los filtros."
            />
          ) : (
            <Table className={loading ? 'opacity-60' : undefined}>
              <TableHeader>
                <TableRow>
                  <TableHead>Usuario</TableHead>
                  <TableHead>Plan</TableHead>
                  <TableHead className="hidden md:table-cell">Acceso</TableHead>
                  <TableHead className="text-right">Consultas IA</TableHead>
                  <TableHead className="hidden text-right lg:table-cell">Comidas</TableHead>
                  <TableHead className="hidden text-right lg:table-cell">Recetas</TableHead>
                  <TableHead className="hidden md:table-cell">Última actividad</TableHead>
                  <TableHead className="hidden xl:table-cell">Registro</TableHead>
                  <TableHead className="w-8" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((u) => (
                  <TableRow
                    key={u.userId}
                    className="cursor-pointer"
                    onClick={() => navigate(`/users/${u.userId}`)}
                  >
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="relative">
                          <UserAvatar name={u.name} userId={u.userId} />
                          {isOnlineRecently(u.lastActivity) && (
                            <span
                              className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-card bg-primary"
                              title="Activo en las últimas 24 h"
                            />
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="flex items-center gap-2 truncate font-semibold">
                            {u.name}
                            {u.role === 'ADMIN' && (
                              <span className="rounded bg-primary/15 px-1.5 text-[10px] font-bold text-primary">ADMIN</span>
                            )}
                          </p>
                          <p className="truncate text-xs text-muted-foreground">
                            #{u.userId} · {u.email}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <PlanBadge plan={u.plan} />
                    </TableCell>
                    <TableCell className="hidden md:table-cell">
                      <AuthMethodBadge method={u.authMethod} />
                    </TableCell>
                    <TableCell className="text-right">
                      <span className="inline-flex items-center gap-1 font-bold tabular-nums">
                        {u.aiQueries > 0 && <Sparkles className="h-3.5 w-3.5 text-primary" />}
                        {formatNumber(u.aiQueries)}
                      </span>
                      {u.aiQueries7d > 0 && (
                        <p className="text-xs text-muted-foreground">+{u.aiQueries7d} esta semana</p>
                      )}
                    </TableCell>
                    <TableCell className="hidden text-right tabular-nums lg:table-cell">{u.mealItems}</TableCell>
                    <TableCell className="hidden text-right tabular-nums lg:table-cell">{u.recipesSaved}</TableCell>
                    <TableCell className="hidden whitespace-nowrap text-muted-foreground md:table-cell">
                      {formatRelative(u.lastActivity)}
                    </TableCell>
                    <TableCell className="hidden whitespace-nowrap text-muted-foreground xl:table-cell">
                      {formatDay(u.createdAt)}
                    </TableCell>
                    <TableCell>
                      <ChevronRight className="h-4 w-4 text-muted-foreground" />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Página {page} de {totalPages}
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
      )}
    </div>
  );
}
