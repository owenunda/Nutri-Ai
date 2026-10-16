// backend/src/i18n/localize.js
import { CODE_MESSAGES, SOURCE_MESSAGES } from './messages.js';

// Object.hasOwn: un texto o código como "constructor" no debe resolver a
// propiedades heredadas del objeto.
const own = (table, key) =>
  table && typeof key === 'string' && Object.hasOwn(table, key) ? table[key] : undefined;

const bySource = (message, lang) => own(own(SOURCE_MESSAGES, message), lang);

const byCode = (code, lang, params) => {
  const entry = own(own(CODE_MESSAGES, lang), code);
  return typeof entry === 'function' ? entry(params ?? {}) : entry;
};

const localizeDetail = (detail, lang) => {
  if (!detail || typeof detail.message !== 'string') return detail;
  const translated = bySource(detail.message, lang);
  return translated ? { ...detail, message: translated } : detail;
};

// Mensaje y detalles de un error en el idioma pedido. Si no hay traducción,
// queda el texto original: nunca falla por una traducción que falte.
export const localizeError = ({ code, message, details = [], params } = {}, lang = 'es') => ({
  message: bySource(message, lang) ?? byCode(code, lang, params) ?? message,
  details: Array.isArray(details) ? details.map((d) => localizeDetail(d, lang)) : details,
});
