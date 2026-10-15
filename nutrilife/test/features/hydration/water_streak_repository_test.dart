import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda el progreso diario y calcula rachas consecutivas', () async {
    final repository = WaterStreakRepository(accountId: 'user@example.com');
    final firstDay = DateTime(2026, 10, 12);

    var snapshot = await repository.load(now: firstDay);
    expect(snapshot.glassesToday, 0);
    expect(snapshot.currentStreak, 0);

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
      snapshot = await repository.addGlass(now: firstDay);
    }
    expect(snapshot.glassesToday, WaterStreakRepository.dailyGoal);
    expect(snapshot.goalCompleted, isTrue);
    expect(snapshot.currentStreak, 1);
    expect(snapshot.bestStreak, 1);

    final nextDay = DateTime(2026, 10, 13);
    snapshot = await repository.load(now: nextDay);
    expect(snapshot.glassesToday, 0);
    expect(snapshot.currentStreak, 1);

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
      snapshot = await repository.addGlass(now: nextDay);
    }
    expect(snapshot.currentStreak, 2);
    expect(snapshot.bestStreak, 2);

    snapshot = await repository.load(now: DateTime(2026, 10, 15));
    expect(snapshot.glassesToday, 0);
    expect(snapshot.currentStreak, 0);
    expect(snapshot.bestStreak, 2);
  });

  test('limita el conteo a cuatro y permite deshacer vasos', () async {
    final repository = WaterStreakRepository(accountId: 'user@example.com');
    final today = DateTime(2026, 10, 14);

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal + 2; glass++) {
      await repository.addGlass(now: today);
    }
    var snapshot = await repository.load(now: today);
    expect(snapshot.glassesToday, WaterStreakRepository.dailyGoal);

    snapshot = await repository.undoGlass(now: today);
    expect(snapshot.glassesToday, WaterStreakRepository.dailyGoal - 1);
    expect(snapshot.goalCompleted, isFalse);

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
      snapshot = await repository.undoGlass(now: today);
    }
    expect(snapshot.glassesToday, 0);
  });

  test('mantiene historiales separados por cuenta', () async {
    final firstAccount = WaterStreakRepository(accountId: 'one@example.com');
    final secondAccount = WaterStreakRepository(accountId: 'two@example.com');
    final today = DateTime(2026, 10, 14);

    await firstAccount.addGlass(now: today);

    expect((await firstAccount.load(now: today)).glassesToday, 1);
    expect((await secondAccount.load(now: today)).glassesToday, 0);
  });

  test(
    'migra historiales guardados con la meta anterior de cinco vasos',
    () async {
      SharedPreferences.setMockInitialValues({
        'water_streak_v1_user%40example.com': '{"2026-10-12":5}',
      });
      final repository = WaterStreakRepository(accountId: 'user@example.com');

      final snapshot = await repository.load(now: DateTime(2026, 10, 12));
      final preferences = await SharedPreferences.getInstance();

      expect(snapshot.glassesToday, WaterStreakRepository.dailyGoal);
      expect(snapshot.currentStreak, 1);
      expect(snapshot.totalGlasses, WaterStreakRepository.dailyGoal);
      expect(
        preferences.getString('water_streak_v1_user%40example.com'),
        '{"2026-10-12":4}',
      );
    },
  );
}
