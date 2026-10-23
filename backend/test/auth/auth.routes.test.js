import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const strictLimiter = () => {};

mockAuthModule('modules/auth/auth.controller.js', [
  'forgotPasswordController', 'getAuthHealth', 'googleLink', 'googleLogin', 'guestLogin',
  'login', 'register', 'resendVerificationController', 'resetPasswordController', 'verifyEmailController',
]);
mockAuthModule('modules/auth/auth.validation.js', [
  'validateAuthHealthRequest', 'validateEmailOnlyRequest', 'validateResetPasswordRequest',
  'validateVerifyEmailRequest', 'validateGoogleLinkRequest', 'validateGoogleLoginRequest',
  'validateLoginRequest', 'validateRegisterRequest',
]);
function mockAuthModule(path, names) {
  mock.module(src(path), {
    namedExports: Object.fromEntries(names.map((name) => [name, () => {}])),
  });
}

mock.module(src('middleware/rateLimit.middleware.js'), {
  namedExports: { guestRateLimit: () => {}, strictAuthRateLimit: strictLimiter },
});

const { default: router } = await import(src('modules/auth/auth.routes.js'));

test('login y registro pasan por el límite estricto antes de validar', () => {
  for (const path of ['/login', '/register']) {
    const route = router.stack.find((layer) => layer.route?.path === path)?.route;
    assert.ok(route, `ruta ${path} debe existir`);
    assert.equal(route.stack[0].handle, strictLimiter);
  }
});
