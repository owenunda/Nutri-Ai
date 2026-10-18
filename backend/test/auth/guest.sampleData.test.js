import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { buildGuestSampleData, GUEST_PROFILE, GUEST_TTL_MS } = await import(src('modules/auth/guest.sampleData.js'));

test('la cuenta dura 24 horas', () => {
  assert.equal(GUEST_TTL_MS, 24 * 60 * 60 * 1000);
});

test('agua de los últimos 7 días, de hace 6 días a hoy, dentro de 1..4 vasos', () => {
  const { water } = buildGuestSampleData('2026-10-18', [1]);
  assert.equal(water.length, 7);
  assert.equal(water[0].day, '2026-10-12');
  assert.equal(water[6].day, '2026-10-18');
  assert.ok(water.every(({ glasses }) => glasses >= 1 && glasses <= 4));
});

test('tres registros de peso con la altura del perfil, el último hoy', () => {
  const { physical } = buildGuestSampleData('2026-10-18', [1]);
  assert.deepEqual(physical.map((p) => p.day), ['2026-10-12', '2026-10-15', '2026-10-18']);
  assert.ok(physical.every((p) => p.height === GUEST_PROFILE.height));
  assert.ok(physical[0].weight > physical[2].weight);
});

test('desayuno, almuerzo y cena cada día, rotando los alimentos', () => {
  const { meals } = buildGuestSampleData('2026-10-18', [10, 20]);
  assert.equal(meals.length, 7);
  assert.deepEqual(meals[0].items.map((i) => i.mealType), ['BREAKFAST', 'LUNCH', 'DINNER']);
  assert.deepEqual(meals[0].items.map((i) => i.foodId), [10, 20, 10]);
  assert.deepEqual(meals[1].items.map((i) => i.foodId), [20, 10, 20]);
  assert.ok(meals.flatMap((m) => m.items).every((i) => i.quantity === 1));
});

test('sin alimentos en el catálogo no hay comidas', () => {
  assert.deepEqual(buildGuestSampleData('2026-10-18', []).meals, []);
});

test('cruza el fin de mes', () => {
  const { water } = buildGuestSampleData('2026-11-02', [1]);
  assert.equal(water[0].day, '2026-10-27');
});
