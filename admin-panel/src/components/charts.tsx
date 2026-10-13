import { moduleMeta } from '../lib/modules';
import { cn, formatNumber } from '../lib/utils';
import type { ModuleCount } from '../types/admin';

export const CHART_COLORS = {
  primary: 'hsl(142 71% 45%)',
  ai: '#4ade80',
  users: '#38bdf8',
  registrations: '#f59e0b',
  grid: 'hsl(160 12% 14%)',
  axis: 'hsl(150 8% 62%)',
};

export const chartTooltipStyle = {
  backgroundColor: 'hsl(160 16% 7%)',
  border: '1px solid hsl(160 12% 16%)',
  borderRadius: '0.75rem',
  color: 'hsl(140 10% 96%)',
  fontSize: '0.8rem',
};

export const axisProps = {
  tick: { fontSize: 11, fill: CHART_COLORS.axis },
  stroke: CHART_COLORS.grid,
  tickLine: false,
};

/** Barras horizontales por módulo, con el icono y color de cada uno. */
export function ModuleBars({ data, className }: { data: ModuleCount[]; className?: string }) {
  const max = Math.max(1, ...data.map((d) => d.count));
  const total = data.reduce((sum, d) => sum + d.count, 0);
  return (
    <ul className={cn('space-y-3', className)}>
      {data.map(({ module, count }) => {
        const meta = moduleMeta(module);
        const Icon = meta.icon;
        return (
          <li key={module}>
            <div className="mb-1 flex items-center justify-between gap-2 text-sm">
              <span className="flex items-center gap-2 font-medium">
                <Icon className="h-4 w-4" style={{ color: meta.color }} />
                {meta.label}
              </span>
              <span className="tabular-nums text-muted-foreground">
                {formatNumber(count)}
                <span className="ml-1.5 text-xs">({Math.round((count / Math.max(total, 1)) * 100)}%)</span>
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full"
                style={{ width: `${(count / max) * 100}%`, backgroundColor: meta.color }}
              />
            </div>
          </li>
        );
      })}
    </ul>
  );
}

/** Selector de rango (7 / 14 / 30 / 90 días). */
export function RangeTabs({
  value,
  onChange,
  options = [7, 14, 30, 90],
  className,
}: {
  value: number;
  onChange: (days: number) => void;
  options?: number[];
  className?: string;
}) {
  return (
    <div className={cn('inline-flex rounded-xl bg-black/25 p-1', className)} role="tablist">
      {options.map((days) => (
        <button
          key={days}
          type="button"
          role="tab"
          aria-selected={value === days}
          onClick={() => onChange(days)}
          className={cn(
            'rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors',
            value === days ? 'bg-white text-emerald-900 shadow' : 'text-white/80 hover:text-white'
          )}
        >
          {days} días
        </button>
      ))}
    </div>
  );
}
