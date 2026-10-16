import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  validatePasswordBody,
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
