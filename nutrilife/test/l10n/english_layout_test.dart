import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:nutrilife/features/hydration/presentation/screens/water_streak_screen.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/theme/app_theme.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/auth_flow_navigator.dart';
import 'package:nutrilife/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/link_google_account_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/login_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/register_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/set_password_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/chatbot/presentation/screens/ai_chat_view.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/fridge_picker_sheet.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/recipe_card_widget.dart';
import 'package:nutrilife/features/home/presentation/screens/dashboard_screen.dart';
import 'package:nutrilife/features/legal/data/legal_documents.dart';
import 'package:nutrilife/features/legal/presentation/screens/legal_document_screen.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/presentation/screens/meal_history_screen.dart';
import 'package:nutrilife/features/meals/presentation/widgets/add_food_sheet.dart';
import 'package:nutrilife/features/meals/presentation/widgets/meal_detail_sheet.dart';
import 'package:nutrilife/features/meals/presentation/widgets/register_recipe_sheet.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/all_foods_screen.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/foods_screen.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';
import 'package:nutrilife/features/profile/data/profile_repository.dart';
import 'package:nutrilife/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:nutrilife/features/profile/presentation/screens/profile_screen.dart';
import 'package:nutrilife/features/profile/presentation/widgets/language_sheet.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';
import 'package:nutrilife/features/progress/presentation/screens/progress_screen.dart';
import 'package:nutrilife/features/progress/presentation/widgets/register_weight_sheet.dart';
import 'package:nutrilife/features/setup/presentation/screens/goal_setup_screen.dart';
import 'package:nutrilife/features/setup/presentation/screens/profile_setup_screen.dart';
import 'package:nutrilife/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Revisión de layout en inglés: arma las pantallas principales en un teléfono
/// de 375x812, con la tipografía real de la app y el tamaño de texto normal,
/// y falla si algo desborda. El test de Flutter falla solo ante cualquier
/// excepción de render (RenderFlex overflow incluido), por eso los tests no
/// necesitan `expect` propios más allá de ver que la pantalla se armó.

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

/// Responde siempre `{success: true, data: {}}` a cualquier petición.
class _EmptyAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': <String, Object?>{}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _fakeDio() =>
    Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = _EmptyAdapter();

/// Carga las tipografías de la app: la fuente de test (Ahem) ocupa mucho más
/// que Inter / Plus Jakarta Sans y daría desbordes que en el teléfono no existen.
Future<void> _loadAppFonts() async {
  Future<void> load(String family, String asset) async {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$asset'));
    await loader.load();
  }

  await load('Inter', 'Inter-Variable.ttf');
  await load('PlusJakartaSans', 'PlusJakartaSans-Variable.ttf');
}

/// Teléfono de 375x812 con el tamaño de texto normal.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// La app en inglés con el tema real.
Widget _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

Future<void> _show(
  WidgetTester tester,
  Widget home, {
  bool settle = true,
}) async {
  _phone(tester);
  await tester.pumpWidget(_app(home));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Abre una hoja inferior desde un botón y espera a que termine de subir.
Future<void> _showSheet(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open,
) async {
  _phone(tester);
  await tester.pumpWidget(
    _app(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('open sheet'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
}

/// Corta el árbol de widgets y los timers antes de terminar el test.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

// ---------------------------------------------------------------------------
// Datos de prueba
// ---------------------------------------------------------------------------

final _profile = UserProfile(
  name: 'Alexandra Montgomery',
  email: 'alexandra.montgomery@example.com',
  age: 30,
  weight: 70,
  height: 170,
  goal: 'Perder peso',
  sex: 'Mujer',
  plan: 'Free',
  createdAt: DateTime(2024, 5, 1),
  hasPassword: true,
);

const _profileJson = {
  'success': true,
  'data': {
    'name': 'Alexandra Montgomery',
    'email': 'alexandra.montgomery@example.com',
    'age': 30,
    'weight': 70,
    'height': 170,
    'goal': 'Perder peso',
    'plan': 'Free',
    'createdAt': '2024-05-01T00:00:00.000Z',
    'hasPassword': true,
  },
};

class _ProfileAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_profileJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FoodModel _food(int id, String name, {String unit = '100 G', bool global = true}) =>
    FoodModel(
      foodId: id,
      name: name,
      caloriesPerUnit: 96,
      baseUnit: unit,
      isGlobal: global,
      isActive: true,
    );

final _foods = [
  _food(1, 'Tilapia'),
  _food(2, 'Banana', unit: '1 UNIDAD'),
  _food(3, 'Rice', unit: '1 TAZA'),
  _food(4, 'Milk', unit: '100 ML'),
  _food(5, 'Chicken breast', unit: '1 PORCIÓN'),
  _food(6, 'My own recipe', global: false),
];

class _FoodRepo extends FoodRepository {
  @override
  Future<List<FoodModel>> getFoods() async => [..._foods];
}

class _DayRepo extends MealRepository {
  _DayRepo({this.withMeals = true});
  final bool withMeals;

  @override
  Future<DayMeals> getDay(String date) async {
    if (!withMeals) return DayMeals.empty(date);
    return DayMeals.fromJson({
      'date': date,
      'totalCalories': 1240,
      'meals': {
        'BREAKFAST': {
          'totalCalories': 320,
          'items': [
            {
              'detailId': 1,
              'foodId': 2,
              'name': 'Banana',
              'baseUnit': '1 UNIDAD',
              'quantity': 2,
              'calories': 200,
            },
            {
              'detailId': 2,
              'foodId': 3,
              'name': 'Rice',
              'baseUnit': '1 TAZA',
              'quantity': 0.5,
              'calories': 120,
            },
          ],
        },
        'LUNCH': {
          'totalCalories': 520,
          'items': [
            {
              'detailId': 3,
              'foodId': 1,
              'name': 'Tilapia',
              'baseUnit': '100 G',
              'quantity': 1.5,
              'calories': 520,
            },
          ],
        },
      },
    });
  }
}

class _ProgressRepo extends ProgressRepository {
  _ProgressRepo() : super(dio: Dio());

  @override
  Future<ProgressData> fetchProgress({DateTime? now}) async {
    return ProgressData(
      profile: {
        'name': 'Alexandra Montgomery',
        'goal': 'Perder peso',
        'weight': 72.5,
        'height': 170,
      },
      history: [
        PhysicalRecord(
          weight: 72.5,
          height: 170,
          recordDate: DateTime(2026, 10, 12),
        ),
        PhysicalRecord(
          weight: 74.0,
          height: 170,
          recordDate: DateTime(2026, 10, 5),
        ),
      ],
      consumptionValidation: {
        'dailyLimit': 2000,
        'totalConsumed': 2450,
        'status': 'EXCEDIDO',
      },
      todayCalories: null,
    );
  }
}

const _recipe = RecipeModel(
  title: 'Banana oatmeal bowl',
  summary: 'A quick, filling breakfast.',
  chefReason: 'Because you have oats and bananas.',
  mealType: 'desayuno',
  difficulty: 'Fácil',
  preparationTimeMinutes: 10,
  servings: 2,
  estimatedCalories: 320,
  tips: ['Use ripe bananas.'],
  steps: [
    RecipeStep(step: 1, description: 'Cook the oats.'),
    RecipeStep(step: 2, description: 'Add the banana.'),
  ],
  ingredients: [
    RecipeIngredient(foodId: 2, quantity: 2),
    RecipeIngredient(foodId: 3, quantity: 1),
  ],
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(_loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.instance.httpClientAdapter = _EmptyAdapter();
  });

  group('Auth en inglés a 375x812', () {
    testWidgets('login', (tester) async {
      await _show(tester, const LoginScreen());
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('register', (tester) async {
      await _show(tester, const RegisterScreen());
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('onboarding: las tres páginas', (tester) async {
      await _show(tester, const AuthFlowNavigator(), settle: false);
      // Título de cada página en inglés: confirma que el swipe sí avanza.
      const titles = ['Discover Foods', 'Personalized', 'Track Your Progress'];
      for (var page = 0; page < 3; page++) {
        expect(find.byType(AuthFlowNavigator), findsOneWidget);
        expect(find.textContaining(titles[page]), findsOneWidget);
        if (page < 2) {
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pump(const Duration(milliseconds: 800));
        }
      }
      await _unmount(tester);
    });

    testWidgets('olvidé mi contraseña', (tester) async {
      await _show(tester, ForgotPasswordScreen(repository: AuthRepository(dio: _fakeDio())));
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('restablecer contraseña', (tester) async {
      await _show(
        tester,
        ResetPasswordScreen(
          email: 'alexandra.montgomery@example.com',
          repository: AuthRepository(dio: _fakeDio()),
        ),
      );
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('verificar correo', (tester) async {
      await _show(
        tester,
        VerifyEmailScreen(
          email: 'alexandra.montgomery@example.com',
          repository: AuthRepository(dio: _fakeDio()),
          onVerified: (_, _) {},
        ),
        settle: false,
      );
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('vincular cuenta de Google', (tester) async {
      await _show(
        tester,
        LinkGoogleAccountScreen(
          idToken: 'token',
          repository: AuthRepository(dio: _fakeDio()),
          onLinked: (_, _) {},
        ),
      );
      expect(find.byType(LinkGoogleAccountScreen), findsOneWidget);
    });

    testWidgets('crear contraseña', (tester) async {
      await _show(
        tester,
        SetPasswordScreen(
          nextScreen: () => const SizedBox(),
          repository: AuthRepository(dio: _fakeDio()),
        ),
      );
      expect(find.byType(SetPasswordScreen), findsOneWidget);
    });
  });

  group('Setup en inglés a 375x812', () {
    testWidgets('perfil', (tester) async {
      await _show(tester, const ProfileSetupScreen());
      expect(find.text('Complete your profile'), findsOneWidget);
    });

    testWidgets('objetivo', (tester) async {
      await _show(tester, const GoalSetupScreen());
      expect(find.text('Set your goal'), findsOneWidget);
    });
  });

  group('Inicio en inglés a 375x812', () {
    testWidgets('dashboard: pestañas de inicio, alimentos, chat, progreso y perfil',
        (tester) async {
      DioClient.instance.httpClientAdapter = _ProfileAdapter();
      await _show(
        tester,
        const DashboardScreen(user: {'name': 'Alexandra Montgomery'}),
        settle: false,
      );
      expect(find.byType(DashboardScreen), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('historial de comidas con comidas', (tester) async {
      await _show(
        tester,
        MealHistoryScreen(
          repository: _DayRepo(),
          clock: () => DateTime(2026, 10, 12, 9),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('historial de comidas vacío', (tester) async {
      await _show(
        tester,
        MealHistoryScreen(
          repository: _DayRepo(withMeals: false),
          clock: () => DateTime(2026, 10, 12, 9),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('detalle de una comida', (tester) async {
      final day = await _DayRepo().getDay('2026-10-12');
      await _showSheet(
        tester,
        (context) => showMealDetailSheet(
          context,
          day.of(MealType.breakfast),
          repository: _DayRepo(),
        ),
      );
      expect(find.text('Banana'), findsWidgets);
    });
  });

  group('Alimentos en inglés a 375x812', () {
    testWidgets('pantalla de alimentos', (tester) async {
      await _show(
        tester,
        FoodsScreen(
          foodRepository: _FoodRepo(),
          mealRepository: _DayRepo(),
        ),
      );
      expect(find.byType(FoodsScreen), findsOneWidget);
    });

    testWidgets('todos los alimentos', (tester) async {
      await _show(
        tester,
        AllFoodsScreen(
          foods: _foods,
          foodRepository: _FoodRepo(),
          fridgeRepository: FridgeRepository(dio: _fakeDio()),
          showFridge: true,
        ),
      );
      expect(find.byType(AllFoodsScreen), findsOneWidget);
      expect(find.text('My fridge'), findsOneWidget);
    });

    testWidgets('hoja para añadir un alimento', (tester) async {
      await _showSheet(
        tester,
        (context) => showAddFoodSheet(
          context,
          _foods[1],
          repository: _DayRepo(),
          clock: () => DateTime(2026, 10, 12, 13),
        ),
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('selector de la nevera', (tester) async {
      await _showSheet(
        tester,
        (context) => FridgePickerSheet.show(
          context,
          repository: FridgeRepository(dio: _fakeDio()),
          foodRepository: _FoodRepo(),
        ),
      );
      expect(find.byType(FridgePickerSheet), findsOneWidget);
    });
  });

  group('Chat en inglés a 375x812', () {
    testWidgets('estado vacío con bienvenida', (tester) async {
      await _show(tester, const Scaffold(body: AiChatView()), settle: false);
      expect(find.byType(AiChatView), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('tarjeta de receta y hoja para registrarla', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: Column(
                  children: [
                    const RecipeCardWidget(recipe: _recipe),
                    TextButton(
                      onPressed: () => showRegisterRecipeSheet(
                        context,
                        _recipe,
                        repository: _DayRepo(),
                        foodRepository: _FoodRepo(),
                        clock: () => DateTime(2026, 10, 12, 13),
                      ),
                      child: const Text('open sheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('open sheet'));
      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('Hidratación en inglés a 375x812', () {
    testWidgets('racha de agua con la meta cumplida y su celebración', (tester) async {
      await _show(tester, const WaterStreakScreen(accountId: 'layout@example.com'));
      expect(find.text('Water streak'), findsOneWidget);
      for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
        await tester.ensureVisible(find.byKey(const ValueKey('add-water-glass')));
        await tester.tap(find.byKey(const ValueKey('add-water-glass')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Water goal reached!'), findsOneWidget);
    });
  });

  group('Progreso, perfil y legales en inglés a 375x812', () {
    testWidgets('progreso', (tester) async {
      await _show(tester, Scaffold(body: ProgressScreen(repository: _ProgressRepo())));
      expect(find.byType(ProgressScreen), findsOneWidget);
    });

    testWidgets('hoja para registrar el peso', (tester) async {
      await _showSheet(
        tester,
        (context) => showRegisterWeightSheet(
          context,
          lastWeight: 80,
          height: 175,
          repository: _ProgressRepo(),
        ),
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('perfil', (tester) async {
      await _show(
        tester,
        ProfileScreen(
          userName: 'Alexandra Montgomery',
          onLogout: () {},
          repository: ProfileRepository(
            dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
              ..httpClientAdapter = _ProfileAdapter(),
          ),
        ),
      );
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('editar perfil', (tester) async {
      await _show(tester, EditProfileScreen(profile: _profile));
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('premium', (tester) async {
      await _show(tester, const PremiumScreen());
      expect(find.text('NutriLife Premium'), findsOneWidget);
    });

    testWidgets('términos y condiciones', (tester) async {
      await _show(tester, LegalDocumentScreen(document: LegalDocumentsEn.terms));
      expect(find.text('Terms and Conditions'), findsOneWidget);
    });

    testWidgets('política de privacidad', (tester) async {
      await _show(tester, LegalDocumentScreen(document: LegalDocumentsEn.privacy));
      expect(find.byType(LegalDocumentScreen), findsOneWidget);
    });

    testWidgets('hoja de idioma', (tester) async {
      await _showSheet(tester, (context) => showLanguageSheet(context));
      expect(find.text('English'), findsOneWidget);
    });
  });
}
