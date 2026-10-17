import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  validatePasswordBody,
  validatePlanBody,
  validateRoleBody,
} from '../../src/modules/admin/admin.validation.js';

const run = (validator, body) => {
  let nextArg = 'not-called';
  validator({ body }, {}, (arg) => {
    nextArg = arg;
  });
  return nextArg;
};

test('contraseña de 6 caracteres o más pasa', () => {
  assert.equal(run(validatePasswordBody, { password: 'abc123' }), undefined);
});

for (const body of [{}, { password: '' }, { password: 'abc12' }, { password: 123456 }, undefined]) {
  test(`contraseña inválida ${JSON.stringify(body)} responde 400`, () => {
    const error = run(validatePasswordBody, body);

    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'password');
  });
}

for (const role of ['ADMIN', 'USER']) {
  test(`rol ${role} pasa`, () => {
    assert.equal(run(validateRoleBody, { role }), undefined);
  });
}

for (const body of [{}, { role: 'admin' }, { role: 'ROOT' }, undefined]) {
  test(`rol inválido ${JSON.stringify(body)} responde 400`, () => {
    const error = run(validateRoleBody, body);

    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'role');
  });
}

for (const body of [
  { plan: 'FREE' },
  { plan: 'PRO', duration: '7d' },
  { plan: 'PRO', duration: '12m' },
  { plan: 'PRO', duration: 'forever' },
]) {
  test(`plan ${JSON.stringify(body)} pasa`, () => {
    assert.equal(run(validatePlanBody, body), undefined);
  });
}

for (const body of [{ plan: 'PRO' }, { plan: 'PRO', duration: '2w' }, { plan: 'PRO', duration: 'constructor' }]) {
  test(`PRO sin duración válida ${JSON.stringify(body)} responde 400`, () => {
    const error = run(validatePlanBody, body);

    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'duration');
  });
}

for (const body of [{}, { plan: 'GOLD', duration: '7d' }, undefined]) {
  test(`plan inválido ${JSON.stringify(body)} responde 400`, () => {
    const error = run(validatePlanBody, body);

    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'plan');
  });
}
