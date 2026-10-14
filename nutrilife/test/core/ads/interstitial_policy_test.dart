import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/ads/interstitial_policy.dart';

void main() {
  final t0 = DateTime(2026, 10, 13, 9);

  test('no muestra antes del tercer registro', () {
    final policy = InterstitialPolicy();
    expect(policy.onMealLogged(t0), isFalse);
    expect(policy.onMealLogged(t0.add(const Duration(minutes: 1))), isFalse);
    expect(policy.onMealLogged(t0.add(const Duration(minutes: 2))), isTrue);
  });

  test('tras mostrar, vuelve a contar desde cero', () {
    final policy = InterstitialPolicy();
    policy.onMealLogged(t0);
    policy.onMealLogged(t0);
    expect(policy.onMealLogged(t0), isTrue);
    policy.markShown(t0);

    final later = t0.add(const Duration(minutes: 10));
    expect(policy.onMealLogged(later), isFalse);
    expect(policy.onMealLogged(later), isFalse);
    expect(policy.onMealLogged(later), isTrue);
  });

  test('respeta 3 minutos entre anuncios aunque haya 3 registros', () {
    final policy = InterstitialPolicy();
    for (var i = 0; i < 2; i++) {
      policy.onMealLogged(t0);
    }
    expect(policy.onMealLogged(t0), isTrue);
    policy.markShown(t0);

    final soon = t0.add(const Duration(minutes: 2));
    policy.onMealLogged(soon);
    policy.onMealLogged(soon);
    expect(policy.onMealLogged(soon), isFalse);

    // El registro que llegó antes de tiempo sigue contando: en cuanto pasan
    // los 3 minutos, el siguiente registro ya puede mostrarlo.
    expect(policy.onMealLogged(t0.add(const Duration(minutes: 3))), isTrue);
  });

  test('si el anuncio no se muestra, no reinicia el contador', () {
    final policy = InterstitialPolicy();
    policy.onMealLogged(t0);
    policy.onMealLogged(t0);
    expect(policy.onMealLogged(t0), isTrue);
    // Sin markShown (p. ej. el anuncio no había cargado).
    expect(policy.onMealLogged(t0.add(const Duration(seconds: 5))), isTrue);
  });
}
