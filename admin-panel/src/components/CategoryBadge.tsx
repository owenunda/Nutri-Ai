import { Crown } from 'lucide-react';
import { Badge, type BadgeProps } from './ui/badge';
import { moduleMeta } from '../lib/modules';

const CATEGORY_VARIANT: Record<string, BadgeProps['variant']> = {
  AUTH: 'info',
  AI: 'default',
  ERROR: 'destructive',
  CRUD: 'secondary',
  SYSTEM: 'outline',
};

/** Muestra la categoría del evento con un color consistente. */
export function CategoryBadge({ category }: { category: string }) {
  return <Badge variant={CATEGORY_VARIANT[category] ?? 'secondary'}>{category}</Badge>;
}

/** Módulo de la app (Alimentos, Chat IA, Bots...) con su icono y color. */
export function ModuleBadge({ module }: { module: string }) {
  const meta = moduleMeta(module);
  const Icon = meta.icon;
  return (
    <span
      className="inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-semibold"
      style={{ backgroundColor: `${meta.color}22`, color: meta.color }}
      title={meta.description}
    >
      <Icon className="h-3.5 w-3.5" />
      {meta.label}
    </span>
  );
}

export function PlanBadge({ plan }: { plan: string }) {
  if (plan === 'PRO') {
    return (
      <Badge variant="warning" className="gap-1">
        <Crown className="h-3 w-3" /> PRO
      </Badge>
    );
  }
  return <Badge variant="secondary">{plan}</Badge>;
}

/** Color por código de estado HTTP. */
export function StatusBadge({ status }: { status: number | null }) {
  if (status === null) return <span className="text-muted-foreground">—</span>;
  let variant: BadgeProps['variant'] = 'default';
  if (status >= 500) variant = 'destructive';
  else if (status >= 400) variant = 'warning';
  else if (status >= 300) variant = 'info';
  return <Badge variant={variant}>{status}</Badge>;
}
