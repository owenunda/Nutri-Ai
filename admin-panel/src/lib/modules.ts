import {
  Apple,
  BarChart3,
  BookOpen,
  Bug,
  CircleDot,
  Globe,
  KeyRound,
  MessageCircle,
  Refrigerator,
  ShieldCheck,
  UserRound,
  UtensilsCrossed,
  Wand2,
  type LucideIcon,
} from 'lucide-react';
import type { EventModule } from '../types/event';

export interface ModuleMeta {
  label: string;
  description: string;
  icon: LucideIcon;
  /** Color sólido (gráficas e iconos). */
  color: string;
}

/** Cómo se muestra cada módulo de la app en el panel. */
export const MODULES: Record<EventModule, ModuleMeta> = {
  chat: { label: 'Chat IA', description: 'Conversaciones con la nutria', icon: MessageCircle, color: '#22c55e' },
  ai: { label: 'Recetas IA', description: 'Recetas generadas por n8n', icon: Wand2, color: '#4ade80' },
  food: { label: 'Alimentos', description: 'Catálogo y alimentos propios', icon: Apple, color: '#f59e0b' },
  meals: { label: 'Comidas', description: 'Registro diario de comidas', icon: UtensilsCrossed, color: '#fb923c' },
  fridge: { label: 'Nevera', description: 'Inventario de la nevera', icon: Refrigerator, color: '#38bdf8' },
  recipe: { label: 'Recetas', description: 'Recetas guardadas', icon: BookOpen, color: '#a78bfa' },
  user: { label: 'Perfil', description: 'Perfil, peso y cuenta', icon: UserRound, color: '#60a5fa' },
  stats: { label: 'Estadísticas', description: 'Calorías y progreso', icon: BarChart3, color: '#2dd4bf' },
  auth: { label: 'Acceso', description: 'Logins y registros', icon: KeyRound, color: '#facc15' },
  admin: { label: 'Admin', description: 'Acciones del panel', icon: ShieldCheck, color: '#94a3b8' },
  bots: { label: 'Escaneos', description: 'Bots buscando fallos en rutas que no existen (/.env, /wp-login...)', icon: Bug, color: '#f87171' },
  external: {
    label: 'Externo',
    description: 'Raíz, favicon o robots.txt: monitores, buscadores o alguien abriendo la URL de la API',
    icon: Globe,
    color: '#818cf8',
  },
  other: { label: 'Otros', description: 'Sin clasificar', icon: CircleDot, color: '#a1a1aa' },
};

export const MODULE_KEYS = Object.keys(MODULES) as EventModule[];

export function moduleMeta(module: string): ModuleMeta {
  return MODULES[module as EventModule] ?? MODULES.other;
}
