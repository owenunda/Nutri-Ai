import { cn, initials } from '../lib/utils';

const PALETTE = ['#16a34a', '#0d9488', '#2563eb', '#7c3aed', '#db2777', '#ea580c', '#ca8a04', '#0891b2'];

/** Avatar con iniciales; el color sale del id para que sea estable. */
export function UserAvatar({
  name,
  userId,
  className,
}: {
  name: string;
  userId: number;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white',
        className
      )}
      style={{ backgroundColor: PALETTE[userId % PALETTE.length] }}
      aria-hidden
    >
      {initials(name)}
    </div>
  );
}
