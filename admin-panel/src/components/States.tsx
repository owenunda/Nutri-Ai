import type { ReactNode } from 'react';
import { Loader2, RefreshCw } from 'lucide-react';
import { Nutria, type NutriaMood } from './Nutria';
import { Button } from './ui/button';
import { cn } from '../lib/utils';

export function LoadingState({ label = 'Cargando...', className }: { label?: string; className?: string }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 py-16 text-muted-foreground', className)}>
      <Nutria mood="pensando" bob className="h-24 w-24" />
      <p className="flex items-center gap-2 text-sm">
        <Loader2 className="h-4 w-4 animate-spin" /> {label}
      </p>
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
  className,
}: {
  message: string;
  onRetry?: () => void;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 py-16 text-center', className)}>
      <Nutria mood="triste" className="h-24 w-24" />
      <div>
        <p className="font-semibold">Algo salió mal</p>
        <p className="mt-1 text-sm text-muted-foreground">{message}</p>
      </div>
      {onRetry && (
        <Button variant="outline" size="sm" onClick={onRetry}>
          <RefreshCw className="h-4 w-4" /> Reintentar
        </Button>
      )}
    </div>
  );
}

export function EmptyState({
  title,
  description,
  mood = 'sentada',
  action,
  className,
}: {
  title: string;
  description?: string;
  mood?: NutriaMood;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-2 py-12 text-center', className)}>
      <Nutria mood={mood} className="h-20 w-20" />
      <p className="font-semibold">{title}</p>
      {description && <p className="max-w-sm text-sm text-muted-foreground">{description}</p>}
      {action}
    </div>
  );
}
