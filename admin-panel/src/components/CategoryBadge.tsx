import { Badge, type BadgeProps } from './ui/badge';

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

/** Color por código de estado HTTP. */
export function StatusBadge({ status }: { status: number | null }) {
  if (status === null) return <span className="text-muted-foreground">—</span>;
  let variant: BadgeProps['variant'] = 'default';
  if (status >= 500) variant = 'destructive';
  else if (status >= 400) variant = 'warning';
  else if (status >= 300) variant = 'info';
  return <Badge variant={variant}>{status}</Badge>;
}
