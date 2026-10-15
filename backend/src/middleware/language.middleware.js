// Idioma de la respuesta según Accept-Language. La app lo manda en cada
// petición; sin header (apps viejas, panel de admin con otro idioma) queda en
// español, que es como respondía el backend antes.
export const SUPPORTED_LANGS = ['es', 'en'];
export const DEFAULT_LANG = 'es';

// "fr, en-US;q=0.8" -> 'en'. Ordena por q y, a igual q, por orden de aparición.
export const resolveLang = (header) => {
  if (typeof header !== 'string' || !header.trim()) return DEFAULT_LANG;

  const ranked = header
    .split(',')
    .map((part, index) => {
      const [tag, ...params] = part.trim().split(';');
      const qParam = params.map((p) => p.trim()).find((p) => p.startsWith('q='));
      return {
        lang: tag.trim().toLowerCase().split('-')[0],
        q: qParam ? Number(qParam.slice(2)) : 1,
        index,
      };
    })
    .filter((entry) => entry.lang && !Number.isNaN(entry.q) && entry.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);

  return ranked.find((entry) => SUPPORTED_LANGS.includes(entry.lang))?.lang ?? DEFAULT_LANG;
};

export const languageMiddleware = (req, res, next) => {
  req.lang = resolveLang(req.headers['accept-language']);
  next();
};
