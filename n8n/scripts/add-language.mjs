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

Escribe todo el texto que ve el usuario en {{ $('${EXTRACT}').first().json.language === 'en' ? 'inglés' : 'español' }}. Los nombres de alimentos del catálogo pueden quedar como vienen. Las claves del JSON no se traducen.`;
// Los prompts que piden `meal_type` lo validan el backend: ese valor no se traduce.
const FIXED_VALUES_NOTE =
  'Los valores fijos que piden las reglas (como `meal_type`, que debe ser exactamente desayuno, almuerzo o cena) se escriben tal cual, sin traducir.';
// Reglas que fijaban el español en el prompt; ahora el idioma lo da la sección.
const LANGUAGE_RULES = [
  ['- En español, tono cercano.', '- Tono cercano.'],
  ['- Responde en español, tono cercano y directo.', '- Responde con tono cercano y directo.'],
];
// Dónde insertar la sección: antes de la instrucción de salida JSON de cada prompt.
const ANCHORS = ['## IMPORTANTE', 'El campo answer es un string', 'Responde ÚNICAMENTE en JSON'];

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
    for (const [from, to] of LANGUAGE_RULES) value.content = value.content.replace(from, to);
    const section = value.content.includes('meal_type')
      ? `${LANGUAGE_SECTION} ${FIXED_VALUES_NOTE}\n\n`
      : `${LANGUAGE_SECTION}\n\n`;
    const anchor = ANCHORS.map((text) => value.content.indexOf(text)).find((i) => i !== -1);
    if (anchor === undefined) throw new Error(`No encontré dónde insertar el idioma en ${name}`);
    value.content = value.content.slice(0, anchor) + section + value.content.slice(anchor);
  }
}

// Textos fijos que ve el usuario fuera de los agentes. Cada cambio busca el texto
// español exacto (lanza error si no está) y lo deja idéntico en la rama 'es'.
const LANG_EXPR = `$('${EXTRACT}').first().json.language === 'en'`;
const LANG_CONST = `const lang = $('${EXTRACT}').first().json.language === 'en' ? 'en' : 'es';`;

const getNode = (name) => {
  const node = flow.nodes.find((n) => n.name === name);
  if (!node) throw new Error(`No existe el nodo ${name}`);
  return node;
};

const replaceExact = (text, from, to, where) => {
  if (!text.includes(from)) throw new Error(`No encontré el texto en ${where}: ${from}`);
  return text.replace(from, () => to);
};

// Nodo Set: el valor pasa a ser una expresión con las dos versiones.
const localizeSetValue = (nodeName, field, spanish, english) => {
  const assignment = getNode(nodeName).parameters.assignments.assignments.find((a) => a.name === field);
  if (!assignment) throw new Error(`No existe el campo ${field} en ${nodeName}`);
  if (assignment.value.startsWith('={{')) return; // ya aplicado
  if (assignment.value !== spanish) throw new Error(`Texto inesperado en ${nodeName}.${field}`);
  assignment.value = `={{ ${LANG_EXPR} ? ${JSON.stringify(english)} : ${JSON.stringify(spanish)} }}`;
};

// Nodo Code: lee el idioma una vez arriba y elige el texto en cada punto.
const localizeCode = (nodeName, replacements) => {
  const node = getNode(nodeName);
  const code = node.parameters.jsCode;
  if (code.includes(LANG_CONST)) return; // ya aplicado
  node.parameters.jsCode = replacements.reduce(
    (text, [from, to]) => replaceExact(text, from, to, nodeName),
    `${LANG_CONST}\n${code}`,
  );
};

localizeSetValue(
  'Respuesta: Nevera Vacía',
  'message',
  'Tu nevera está vacía 🥲 Agrega alimentos desde la app, o dime qué tienes a mano y te armo algo con eso.',
  "Your fridge is empty 🥲 Add foods from the app, or tell me what you have on hand and I'll put something together.",
);

localizeCode('Respuesta: Alimentos No Reconocidos', [
  [
    "  ? `No encontré ${names.join(', ')} en el catálogo de alimentos 😕 Agrégalos desde la sección Alimentos y lo volvemos a intentar, o dime otros que tengas.`",
    [
      "  ? (lang === 'en'",
      "    ? `I couldn't find ${names.join(', ')} in the food catalog 😕 Add them from the Foods section and we'll try again, or tell me other ones you have.`",
      "    : `No encontré ${names.join(', ')} en el catálogo de alimentos 😕 Agrégalos desde la sección Alimentos y lo volvemos a intentar, o dime otros que tengas.`)",
    ].join('\n'),
  ],
  [
    "  : 'No pude reconocer los alimentos de tu nevera en el catálogo 😕 Revisa que estén bien registrados en la sección Alimentos.';",
    [
      "  : (lang === 'en'",
      "    ? \"I couldn't recognize the foods in your fridge in the catalog 😕 Check that they're registered correctly in the Foods section.\"",
      "    : 'No pude reconocer los alimentos de tu nevera en el catálogo 😕 Revisa que estén bien registrados en la sección Alimentos.');",
    ].join('\n'),
  ],
]);

localizeCode('Parsear Respuesta de Consulta', [
  [
    "|| 'No pude responder eso con la información de la receta.'",
    "|| (lang === 'en' ? \"I couldn't answer that with the information in the recipe.\" : 'No pude responder eso con la información de la receta.')",
  ],
]);

localizeCode('Parsear Respuesta de Chat', [
  [
    "|| '¡Hola! Dime qué tienes en la nevera y te armo una receta 🍳'",
    "|| (lang === 'en' ? \"Hi! Tell me what you have in the fridge and I'll put a recipe together 🍳\" : '¡Hola! Dime qué tienes en la nevera y te armo una receta 🍳')",
  ],
]);

localizeCode('Construir Respuesta Final', [
  [
    '`Te preparé: ${recipe?.title}`',
    "(lang === 'en' ? `Here's what I made for you: ${recipe?.title}` : `Te preparé: ${recipe?.title}`)",
  ],
  ["(j.message || 'Listo.')", "(j.message || (lang === 'en' ? 'Done.' : 'Listo.'))"],
]);

// Conserva si el archivo original terminaba con salto de línea.
const trailingNewline = original.endsWith('\n') ? '\n' : '';
writeFileSync(path, `${JSON.stringify(flow, null, 2)}${trailingNewline}`);
console.log('Listo: idioma agregado al flujo.');
