import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  calorieRange,
  currentCalorieStreak,
  bestCalorieStreak,
  goalKind,
  isGoalDay,
} from '../../src/modules/stats/calorieStreak.js';

test('goalKind reconoce el objetivo en español y en inglés', () => {
  assert.equal(goalKind('Perder peso'), 'lose');
  assert.equal(goalKind('bajar'), 'lose');
  assert.equal(goalKind('lose'), 'lose');
  assert.equal(goalKind('Ganar músculo'), 'gain');
  assert.equal(goalKind('subir'), 'gain');
  assert.equal(goalKind('gain'), 'gain');
  assert.equal(goalKind('maintain'), 'maintain');
  assert.equal(goalKind(null), 'maintain');
});

test('el rango depende del objetivo', () => {
  assert.deepEqual(calorieRange('lose', 2000), { min: 1400, max: 2000 });
  assert.deepEqual(calorieRange('maintain', 2000), { min: 1700, max: 2300 });
  assert.deepEqual(calorieRange('gain', 2000), { min: 2000, max: 2600 });
});

test('un día cuenta solo dentro del rango, bordes incluidos', () => {
  const range = calorieRange('lose', 2000);
  assert.equal(isGoalDay(1400, range), true);
  assert.equal(isGoalDay(2000, range), true);
  assert.equal(isGoalDay(1399, range), false);
  assert.equal(isGoalDay(2001, range), false);
  assert.equal(isGoalDay(0, range), false);
});

test('para subir, comer por debajo de la meta no cuenta', () => {
  const range = calorieRange('gain', 2000);
  assert.equal(isGoalDay(1800, range), false);
  assert.equal(isGoalDay(2400, range), true);
});

const range = calorieRange('lose', 2000);

test('racha actual: cuenta hasta hoy si hoy ya está en rango', () => {
  const history = { '2026-10-16': 1800, '2026-10-17': 1900, '2026-10-18': 1500 };
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 3);
});

test('racha actual: hoy por debajo del mínimo no la corta, sigue desde ayer', () => {
  const history = { '2026-10-16': 1800, '2026-10-17': 1900, '2026-10-18': 300 };
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 2);
});

test('racha actual: hoy sin registros sigue desde ayer', () => {
  const history = { '2026-10-16': 1800, '2026-10-17': 1900 };
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 2);
});

test('racha actual: pasarse hoy del máximo la corta', () => {
  const history = { '2026-10-16': 1800, '2026-10-17': 1900, '2026-10-18': 2600 };
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 0);
});

test('racha actual: un día sin registros en medio la corta', () => {
  const history = { '2026-10-14': 1800, '2026-10-15': 1800, '2026-10-17': 1900 };
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 1);
});

test('racha actual: no tiene tope de 7 días', () => {
  const history = {};
  for (let d = 1; d <= 18; d++) history[`2026-10-${String(d).padStart(2, '0')}`] = 1800;
  assert.equal(currentCalorieStreak(history, '2026-10-18', range), 18);
});

test('mejor racha: la más larga de toda la historia, cruzando meses', () => {
  const history = {
    '2026-09-29': 1800, '2026-09-30': 1800, '2026-10-01': 1800, '2026-10-02': 1800,
    '2026-10-03': 2500,
    '2026-10-04': 1800, '2026-10-05': 1800,
  };
  assert.equal(bestCalorieStreak(history, range), 4);
});

test('mejor racha: sin días en rango es 0', () => {
  assert.equal(bestCalorieStreak({ '2026-10-01': 100 }, range), 0);
  assert.equal(bestCalorieStreak({}, range), 0);
});
