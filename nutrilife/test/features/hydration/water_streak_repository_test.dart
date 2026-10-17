import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_hydration_server.dart';

WaterStreakRepository _repo(FakeHydrationServer server, {String account = 'user@example.com'}) =>
    WaterStreakRepository(
      accountId: account,
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = server,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda el progreso diario y calcula rachas consecutivas', () async {
    final repository = _repo(FakeHydrationServer());
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
    final repository = _repo(FakeHydrationServer());
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

  test('cada cuenta ve su propio historial del servidor', () async {
    final first = _repo(FakeHydrationServer(), account: 'one@example.com');
    final second = _repo(FakeHydrationServer(), account: 'two@example.com');
    final today = DateTime(2026, 10, 14);

    await first.addGlass(now: today);

    expect((await first.load(now: today)).glassesToday, 1);
    expect((await second.load(now: today)).glassesToday, 0);
  });

  test('sube una vez el historial guardado en el teléfono y lo borra', () async {
    SharedPreferences.setMockInitialValues({
      'water_streak_v1_user%40example.com': '{"2026-10-11":4,"2026-10-12":5,"mal":2}',
    });
    final server = FakeHydrationServer();
    final repository = _repo(server);

    final snapshot = await repository.load(now: DateTime(2026, 10, 12));
    final preferences = await SharedPreferences.getInstance();

    expect(server.history, {'2026-10-11': 4, '2026-10-12': 4});
    expect(snapshot.currentStreak, 2);
    expect(preferences.getString('water_streak_v1_user%40example.com'), isNull);

    await repository.load(now: DateTime(2026, 10, 12));
    expect(server.requests.where((r) => r.path == '/hydration/import'), hasLength(1));
  });

  test('si el import falla, el historial local se queda para reintentar', () async {
    SharedPreferences.setMockInitialValues({
      'water_streak_v1_user%40example.com': '{"2026-10-12":3}',
    });
    final server = FakeHydrationServer()..failing = true;

    await expectLater(_repo(server).load(now: DateTime(2026, 10, 12)), throwsException);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('water_streak_v1_user%40example.com'), isNotNull);
  });
}
