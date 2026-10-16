import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';
import 'package:nutrilife/features/progress/presentation/screens/progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

class _RepoContador extends ProgressRepository {
  _RepoContador() : super(dio: Dio());

  int llamadas = 0;

  @override
  Future<ProgressData> fetchProgress({DateTime? now}) async {
    llamadas++;
    return const ProgressData(
      profile: {'name': 'Ana'},
      history: [],
      consumptionValidation: null,
      todayCalories: null,
    );
  }
}

void main() {
  testWidgets('ProgressScreen recarga cuando se registra una comida', (tester) async {
    // La tarjeta de hidratación lee SharedPreferences: sin mock no termina de cargar.
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _RepoContador();
    await tester.pumpWidget(l10nApp(Scaffold(body: ProgressScreen(repository: repo))));
    await tester.pumpAndSettle();
    expect(repo.llamadas, 1);

    MealLogState.instance.bump();
    await tester.pumpAndSettle();

    expect(repo.llamadas, 2);
  });
}
