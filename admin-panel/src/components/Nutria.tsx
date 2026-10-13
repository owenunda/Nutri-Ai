import { cn } from '../lib/utils';

export type NutriaMood =
  | 'saludando'
  | 'feliz'
  | 'pensando'
  | 'triste'
  | 'celebracion'
  | 'atenta'
  | 'comiendo'
  | 'premium'
  | 'enojada'
  | 'sentada'
  | 'caminando';

/** La mascota de NutriLife (las mismas ilustraciones que la app). */
export function Nutria({
  mood,
  className,
  bob = false,
  alt = '',
}: {
  mood: NutriaMood;
  className?: string;
  /** Pequeño balanceo, como en la app. */
  bob?: boolean;
  alt?: string;
}) {
  return (
    <img
      src={`/nutria/${mood}.webp`}
      alt={alt}
      aria-hidden={alt ? undefined : true}
      draggable={false}
      className={cn('nutria object-contain', bob && 'animate-bob', className)}
    />
  );
}
