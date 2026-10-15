// n8n/scripts/add-language.mjs
// Agrega el idioma al flujo del chat: el nodo que extrae el request saca
// `language`, y cada agente que escribe texto para el usuario recibe una
// sección "Idioma". Idempotente: correrlo dos veces no duplica nada.
//
// Uso: node n8n/scripts/add-language.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const path = new URL('../NutriLife - Chat de Recetas.json', import.meta.url);
const original = readFileSync(path, 'utf8');
const flow = JSON.parse(original);

const EXTRACT = 'Extraer Datos del Request';
const AGENTS = [
  'Agente: Chef de Cocina',
  'Agente: Modificar Receta',
  'Agente: Responder Pregunta',
  'Agente: Chat General',
];
const MARK = '## Idioma';
const LANGUAGE_SECTION = `${MARK}

Escribe todo el texto que ve el usuario en {{ $('${EXTRACT}').first().json.language === 'en' ? 'inglés' : 'español' }}. Los nombres de alimentos del catálogo pueden quedar como vienen. Las claves del JSON no se traducen.

`;

const extract = flow.nodes.find((n) => n.name === EXTRACT);
if (!extract) throw new Error(`No existe el nodo ${EXTRACT}`);
const assignments = extract.parameters.assignments.assignments;
if (!assignments.some((a) => a.name === 'language')) {
  assignments.push({
    id: 'f1a0c7d2-0006-4a11-9f01-0a1b2c3d4e06',
    name: 'language',
    value: "={{ $json.body.language === 'en' ? 'en' : 'es' }}",
    type: 'string',
  });
}

for (const name of AGENTS) {
  const node = flow.nodes.find((n) => n.name === name);
  if (!node) throw new Error(`No existe el nodo ${name}`);
  for (const value of node.parameters.responses.values) {
    if (typeof value.content !== 'string' || value.content.includes(MARK)) continue;
    // El agente general fija el español en sus reglas; esa línea ahora la da la sección.
    value.content = value.content.replace('- En español, tono cercano.', '- Tono cercano.');
    const anchor = value.content.indexOf('Responde ÚNICAMENTE en JSON');
    value.content =
      anchor === -1
        ? `${value.content}\n\n${LANGUAGE_SECTION.trimEnd()}`
        : value.content.slice(0, anchor) + LANGUAGE_SECTION + value.content.slice(anchor);
  }
}

// Conserva si el archivo original terminaba con salto de línea.
const trailingNewline = original.endsWith('\n') ? '\n' : '';
writeFileSync(path, `${JSON.stringify(flow, null, 2)}${trailingNewline}`);
console.log('Listo: idioma agregado al flujo.');
