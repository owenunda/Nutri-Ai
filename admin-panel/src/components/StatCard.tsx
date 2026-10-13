import type { LucideIcon } from 'lucide-react';
import type { ReactNode } from 'react';
import { Card, CardContent } from './ui/card';
import { cn, formatNumber } from '../lib/utils';

const TONES = {
  green: 'bg-primary/15 text-primary',
  amber: 'bg-amber-500/15 text-amber-400',
  sky: 'bg-sky-500/15 text-sky-400',
  violet: 'bg-violet-500/15 text-violet-400',
  red: 'bg-red-500/15 text-red-400',
  orange: 'bg-orange-500/15 text-orange-400',
  teal: 'bg-teal-500/15 text-teal-400',
};

export type StatTone = keyof typeof TONES;

export function StatCard({
  title,
  value,
  hint,
  icon: Icon,
  tone = 'green',
  className,
}: {
  title: string;
  value: number | string;
  hint?: ReactNode;
  icon: LucideIcon;
  tone?: StatTone;
  className?: string;
}) {
  return (
    <Card className={className}>
      <CardContent className="flex items-start justify-between gap-3 p-5">
        <div className="min-w-0">
          <p className="text-sm text-muted-foreground">{title}</p>
          <p className="mt-1 text-3xl font-bold tabular-nums tracking-tight">
            {typeof value === 'number' ? formatNumber(value) : value}
          </p>
          {hint && <p className="mt-1 text-xs text-muted-foreground">{hint}</p>}
        </div>
        <div className={cn('flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl', TONES[tone])}>
          <Icon className="h-5 w-5" />
        </div>
      </CardContent>
    </Card>
  );
}
