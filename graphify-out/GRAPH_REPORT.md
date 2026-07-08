# Graph Report - .  (2026-07-08)

## Corpus Check
- 209 files · ~74,914 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1338 nodes · 2033 edges · 91 communities (65 shown, 26 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 52 edges (avg confidence: 0.83)
- Token cost: 219,585 input · 0 output

## Community Hubs (Navigation)
- Windows Runner Boilerplate
- Auth Feature (Flutter)
- Fridge & Auth Backend
- Profile Feature (Flutter)
- Chatbot & Nutrition UI
- Setup Feature (Flutter)
- iOS/macOS Runner Boilerplate
- Profile Screens (Flutter)
- Progress Feature (Flutter)
- Setup Flow Screens
- Chatbot Feature (Flutter)
- Progress Tracking UI
- Backend Config & AI Utils
- Auth Screens (Flutter)
- Chatbot Data Models
- Chat Backend Module
- Core Widgets & Routes
- Progress/Profile/Auth Mix
- Profile Repository (Flutter)
- Linux Runner Boilerplate
- Chatbot Presentation Layer
- Backend Package Dependencies
- Recipe Backend Module
- Home Feature (Flutter)
- Food Backend Module
- User Backend Module
- Flutter Docs & Linux Build
- Core Services (Flutter)
- Auth Repository (Flutter)
- Nutrition Feature (Flutter)
- Setup & Nutrition Mix
- Chatbot/Auth/Profile Mix
- Backend Patterns & Docker Docs
- Auth ViewModel (Flutter)
- Meal Backend Module
- Core Theme (Flutter)
- App Entry Point
- Chatbot Widgets (Flutter)
- Auth/Chatbot/Home Mix
- Chatbot Controllers
- Windows Runner Utils
- Nutrition Data Layer
- Chatbot Screens (Flutter)
- Stats Backend Module
- Web Manifest (Flutter)
- Auth Validation (Flutter)
- Auth Service (Flutter)
- Core Widgets (Flutter)
- Chatbot Repository
- Core Services (Flutter) 2
- Backend Patterns Skill Doc
- Backend Patterns Skill Doc 2
- Home Screens (Flutter)
- Core Theme (Flutter) 2
- Flutter Design Docs
- Home Widgets (Flutter)
- Backend Patterns Skill Doc 3
- Progress/Auth Mix
- Backend Patterns Skill Doc 4
- Backend Patterns Skill Doc 5
- Android App Config
- iOS Workflow & README
- Flutter Lint Config
- Core Widgets (Flutter) 2
- Flutter Docs
- Auth Feature (Flutter) 2
- Chatbot Feature (Flutter) 2
- Chatbot Feature (Flutter) 3
- Setup Feature (Flutter) 2
- Setup Feature (Flutter) 3
- ADB Reverse Script
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Backend Patterns Doc Fragment
- Isolated Node
- Git Workflow Doc
- Isolated Node
- Mascot GIF Asset
- Logo PNG Asset
- iOS Runner
- Root README

## God Nodes (most connected - your core abstractions)
1. `successResponse()` - 47 edges
2. `AppError` - 23 edges
3. `Win32Window` - 22 edges
4. `authenticateToken()` - 19 edges
5. `MessageHandler` - 12 edges
6. `pool` - 11 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `MessageHandler` - 9 edges

## Surprising Connections (you probably didn't know these)
- `authenticate middleware function` --semantically_similar_to--> `authenticateToken()`  [INFERRED] [semantically similar]
  .agents/skills/nodejs-backend-patterns/references/details.md → backend/src/middleware/auth.middleware.js
- `Layered Architecture pattern (Controller-Service-Repository)` --semantically_similar_to--> `NutriAI Backend README (architecture & modules)`  [INFERRED] [semantically similar]
  .agents/skills/nodejs-backend-patterns/references/details.md → backend/README.md
- `ApiResponse helper class` --semantically_similar_to--> `API Response Contract documentation`  [INFERRED] [semantically similar]
  .agents/skills/nodejs-backend-patterns/references/advanced-patterns.md → backend/documentation/respuesta_api.md
- `authenticateToken()` --implements--> `AI Module API (/api/v1/ai/recipe)`  [INFERRED]
  backend/src/middleware/auth.middleware.js → backend/src/modules/ai/ai.swagger.yaml
- `authenticateToken()` --implements--> `Food Module API (CRUD)`  [INFERRED]
  backend/src/middleware/auth.middleware.js → backend/src/modules/food/food.swagger.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Layered Architecture Flow: Controller -> Service -> Repository (mirrors backend module design)** — agents_skills_nodejs_backend_patterns_references_details_usercontroller, agents_skills_nodejs_backend_patterns_references_details_userservice, agents_skills_nodejs_backend_patterns_references_details_userrepository, backend_readme [INFERRED 0.85]
- **AppError-based Custom Error Class Hierarchy** — agents_skills_nodejs_backend_patterns_references_details_apperror, agents_skills_nodejs_backend_patterns_references_details_validationerror, agents_skills_nodejs_backend_patterns_references_details_notfounderror, agents_skills_nodejs_backend_patterns_references_details_unauthorizederror, agents_skills_nodejs_backend_patterns_references_details_forbiddenerror, agents_skills_nodejs_backend_patterns_references_details_conflicterror [EXTRACTED 1.00]
- **Standardized API Response Contract Pattern** — agents_skills_nodejs_backend_patterns_references_advanced_patterns_apiresponse, backend_documentation_respuesta_api, backend_src_utils_response [INFERRED 0.85]
- **Flutter desktop (Linux/Windows) CMake build pipeline sharing the single Flutter project manifest** — nutriapp_pubspec, nutriapp_linux_cmakelists, nutriapp_linux_flutter_cmakelists, nutriapp_windows_cmakelists, nutriapp_windows_flutter_cmakelists [INFERRED 0.85]
- **Digital Sanctuary design system components implementing glassmorphism and tonal layering for AI-forward surfaces** — nutriapp_lib_docs_design_digital_sanctuary, nutriapp_lib_docs_design_aura_fab, nutriapp_lib_docs_design_glass_gradient_rule, nutriapp_lib_docs_design_tonal_layering, nutriapp_lib_docs_design_no_line_rule [EXTRACTED 0.90]
- **Recommended NutriAI architecture stack: Clean Architecture, Feature First, Riverpod, go_router** — nutriapp_lib_docs_estructura_archivos_clean_architecture, nutriapp_lib_docs_estructura_archivos_feature_first, nutriapp_lib_docs_estructura_archivos_riverpod, nutriapp_lib_docs_estructura_archivos_go_router [EXTRACTED 0.90]

## Communities (91 total, 26 thin omitted)

### Community 0 - "Windows Runner Boilerplate"
Cohesion: 0.06
Nodes (53): RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+45 more)

### Community 1 - "Auth Feature (Flutter)"
Cohesion: 0.04
Nodes (54): ../../data/auth_repository.dart, _acceptedTerms, _authRepository, background, body, build, color, _confirmPasswordController (+46 more)

### Community 2 - "Fridge & Auth Backend"
Cohesion: 0.10
Nodes (37): getAuthHealth(), login(), register(), createUser(), findUserByEmail(), getAuthRepositoryStatus(), getDefaultRoleAndPlanIds(), router (+29 more)

### Community 3 - "Profile Feature (Flutter)"
Cohesion: 0.05
Nodes (45): _, ../../data/profile_repository.dart, _ageController, _ageOptions, _backendGoal, build, children, _ConfigCard (+37 more)

### Community 4 - "Chatbot & Nutrition UI"
Cohesion: 0.05
Nodes (42): bool get, ChangeNotifier, dart:async, ../../data/chat_repository.dart, ../../data/food_repository.dart, ../../data/models/chat_message_model.dart, ../../data/models/food_model.dart, ChatMessageModel (+34 more)

### Community 5 - "Setup Feature (Flutter)"
Cohesion: 0.05
Nodes (44): GlobalKey, goal_setup_screen.dart, MaterialPageRoute, build, _ageController, _ageOptions, build, child (+36 more)

### Community 6 - "iOS/macOS Runner Boilerplate"
Cohesion: 0.06
Nodes (28): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS, FlutterPluginRegistry (+20 more)

### Community 7 - "Profile Screens (Flutter)"
Cohesion: 0.05
Nodes (41): _, edit_profile_screen.dart, Future, build, createState, _formatHeight, _formatProfileNumber, goal (+33 more)

### Community 8 - "Progress Feature (Flutter)"
Cohesion: 0.05
Nodes (41): ../../data/progress_repository.dart, accent, _blue, buffer, build, child, createState, currentWeight (+33 more)

### Community 9 - "Setup Flow Screens"
Cohesion: 0.05
Nodes (36): ../../data/setup_repository.dart, double get, _activityFactor, age, backendGoal, build, calories, color (+28 more)

### Community 10 - "Chatbot Feature (Flutter)"
Cohesion: 0.06
Nodes (35): Animation, ../controllers/chat_view_model.dart, Duration, _BotTextBubble, build, _ChatBubble, child, color (+27 more)

### Community 11 - "Progress Tracking UI"
Cohesion: 0.06
Nodes (35): _activityFactor, _calculateDailyLimitFromProfile, _calorieAdjustmentRatio, consumptionValidation, _dio, _extractFriendlyMessage, _fallbackMessage, fetchProgress (+27 more)

### Community 12 - "Backend Config & AI Utils"
Cohesion: 0.13
Nodes (20): ApiResponse helper class, API Response Format section, API Response Contract documentation, app, config, options, swaggerSpec, pool (+12 more)

### Community 13 - "Auth Screens (Flutter)"
Cohesion: 0.06
Nodes (33): auth_flow_navigator.dart, ../../../../core/services/auth_service.dart, _BrandHeader, controller, _CreateAccountPrompt, createState, dispose, _emailController (+25 more)

### Community 14 - "Chatbot Data Models"
Cohesion: 0.06
Nodes (31): ../../data/models/recipe_model.dart, build, color, createState, _currentPage, _dark, dispose, _expandSummary (+23 more)

### Community 15 - "Chat Backend Module"
Cohesion: 0.15
Nodes (24): addMessageController(), closeSessionController(), createSessionController(), getActiveSessionController(), getSessionsController(), updateConversationStateController(), addMessageRepository(), closeSessionRepository() (+16 more)

### Community 16 - "Core Widgets & Routes"
Cohesion: 0.07
Nodes (26): ../features/auth/auth_routes.dart, ../features/home/home_routes.dart, ApiRoutes, authHealth, authLogin, authRegister, chatSessionClose, chatSessions (+18 more)

### Community 17 - "Progress/Profile/Auth Mix"
Cohesion: 0.07
Nodes (29): _BrandFooter, _FieldLabel, _GlowCircle, _RegisterCard, _RegisterField, _GoalPill, _LogoutButton, _NutritionGoalSelector (+21 more)

### Community 18 - "Profile Repository (Flutter)"
Cohesion: 0.07
Nodes (28): age, copyWith, createdAt, _dio, email, _extractFriendlyMessage, _fallbackMessage, fromJson (+20 more)

### Community 19 - "Linux Runner Boilerplate"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, MyApplicationClass (+14 more)

### Community 20 - "Chatbot Presentation Layer"
Cohesion: 0.07
Nodes (26): channel, chefReason, description, difficulty, estimatedCalories, foodId, fromMap, ingredients (+18 more)

### Community 21 - "Backend Package Dependencies"
Cohesion: 0.08
Nodes (24): author, dependencies, axios, bcrypt, cors, dotenv, express, jsonwebtoken (+16 more)

### Community 22 - "Recipe Backend Module"
Cohesion: 0.21
Nodes (20): checkFoodsExist(), addIngredientsToRecipe(), createRecipe(), getAllRecipes(), getRecipeById(), handleRecipeAction(), updateRecipeStatus(), addIngredientsToRecipeRepository() (+12 more)

### Community 23 - "Home Feature (Flutter)"
Cohesion: 0.10
Nodes (21): ../../../auth/presentation/screens/login_screen.dart, ../../../../core/widgets/custom_bottom_nav_bar.dart, ../../../../features/chatbot/presentation/screens/ai_chat_view.dart, build, _buildHomeTab, _buildProfileTab, createState, _currentTab (+13 more)

### Community 24 - "Food Backend Module"
Cohesion: 0.18
Nodes (16): createFood(), deleteFood(), getAllFoods(), getFoodHealth(), matchFoods(), updateFood(), router, createFood() (+8 more)

### Community 25 - "User Backend Module"
Cohesion: 0.24
Nodes (14): createPhysical(), getPhysicalHistoryController(), getProfile(), updateProfile(), createPhysicalRecord(), findPhysicalHistoryByUserId(), findUserProfileById(), updateUserProfileData() (+6 more)

### Community 26 - "Flutter Docs & Linux Build"
Cohesion: 0.15
Nodes (19): DESIGN.md - Design System Document: The Mindful Alchemist, Digital Sanctuary (creative north star concept), The Editorial Voice typography (Plus Jakarta Sans display + Inter body), Intentional Asymmetry (editorial, weighted layout principle to break the template look), Organic Precision (blend of AI intelligence and human wellness), NutriAI - Estructura de Archivos (architecture/file structure doc), Clean Architecture simplificada (recommended architectural pattern), Feature First module organization pattern (+11 more)

### Community 27 - "Core Services (Flutter)"
Cohesion: 0.11
Nodes (17): Color, double?, IconData, build, endColor, foregroundColor, height, icon (+9 more)

### Community 28 - "Auth Repository (Flutter)"
Cohesion: 0.12
Nodes (16): analyze_progress_screen.dart, ../../../../core/widgets/primary_button.dart, discover_foods_screen.dart, login_screen.dart, AuthFlowNavigator, _AuthFlowNavigatorState, build, createState (+8 more)

### Community 29 - "Nutrition Feature (Flutter)"
Cohesion: 0.12
Nodes (16): ../controllers/foods_view_model.dart, FormState, build, _buildFoodItemCard, _buildFoodsContent, createState, dispose, FoodsScreen (+8 more)

### Community 30 - "Setup & Nutrition Mix"
Cohesion: 0.12
Nodes (15): ../../../core/network/dio_client.dart, Dio, models/food_model.dart, createFood, _dio, FoodRepository, getFoods, _dio (+7 more)

### Community 31 - "Chatbot/Auth/Profile Mix"
Cohesion: 0.18
Nodes (17): AnalyzeProgressScreen, _AnalyzeProgressScreenState, _LoginPanel, _LoginPanelState, AiChatView, _AiChatViewState, _AnimatedAppear, _AnimatedAppearState (+9 more)

### Community 32 - "Backend Patterns & Docker Docs"
Cohesion: 0.19
Nodes (15): authenticate middleware function, Layered Architecture pattern (Controller-Service-Repository), docker-compose api service, docker-compose db (postgres) service, authenticateToken middleware documentation, NutriAI Backend README (architecture & modules), authenticateToken(), AI Module API (/api/v1/ai/recipe) (+7 more)

### Community 33 - "Auth ViewModel (Flutter)"
Cohesion: 0.13
Nodes (14): ../../../core/network/api_routes.dart, Exception, AuthException, AuthRepository, _dio, _extractFriendlyMessage, _fallbackMessage, message (+6 more)

### Community 34 - "Meal Backend Module"
Cohesion: 0.34
Nodes (10): addMealItems(), addMealRecipes(), createMeal(), addItemsToMealRepository(), createMealRecordRepository(), findMealRecordByUserAndDate(), addItemsToMealService(), addRecipesToMealService() (+2 more)

### Community 35 - "Core Theme (Flutter)"
Cohesion: 0.15
Nodes (11): ../constants/api_base_url.dart, ../network/api_routes.dart, ../network/dio_client.dart, authToken, DioClient, instance, AuthService, login (+3 more)

### Community 36 - "App Entry Point"
Cohesion: 0.15
Nodes (12): core/services/session_service.dart, features/auth/presentation/screens/auth_flow_navigator.dart, features/auth/presentation/screens/login_screen.dart, features/home/presentation/screens/dashboard_screen.dart, build, hasSeenOnboarding, home, main (+4 more)

### Community 37 - "Chatbot Widgets (Flutter)"
Cohesion: 0.15
Nodes (12): ../../data/models/chat_session_model.dart, List, build, ChatHistoryDrawer, _DrawerHeader, _EmptyState, _formatDate, isLoading (+4 more)

### Community 38 - "Auth/Chatbot/Home Mix"
Cohesion: 0.15
Nodes (9): build, DiscoverFoodsScreen, build, OnboardingScreen, build, ChatWelcomeHeader, build, HomeHeader (+1 more)

### Community 39 - "Chatbot Controllers"
Cohesion: 0.18
Nodes (11): FocusNode, build, ChatInputField, _ChatInputFieldState, _controller, createState, dispose, _focusNode (+3 more)

### Community 40 - "Windows Runner Utils"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 41 - "Nutrition Data Layer"
Cohesion: 0.17
Nodes (11): int?, baseUnit, caloriesPerUnit, createdByUserId, foodId, FoodModel, fromJson, isActive (+3 more)

### Community 42 - "Chatbot Screens (Flutter)"
Cohesion: 0.17
Nodes (11): models/chat_session_model.dart, models/recipe_model.dart, ChatRepository, ChatResponse, closeSession, _dio, getSessions, _parseResponse (+3 more)

### Community 43 - "Stats Backend Module"
Cohesion: 0.38
Nodes (7): getConsumptionValidation(), getTodayCalories(), getTodayConsumptionCalories(), getUserNutritionalData(), router, getTodayCaloriesService(), validateConsumptionService()

### Community 44 - "Web Manifest (Flutter)"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 45 - "Auth Validation (Flutter)"
Cohesion: 0.20
Nodes (9): AnimationController, build, _chartAnimationController, createState, dispose, initState, paint, progress (+1 more)

### Community 46 - "Auth Service (Flutter)"
Cohesion: 0.22
Nodes (9): core/theme/app_theme.dart, ../../../home/presentation/screens/dashboard_screen.dart, Map, build, createState, initState, LoginSuccessScreen, _LoginSuccessScreenState (+1 more)

### Community 47 - "Core Widgets (Flutter)"
Cohesion: 0.22
Nodes (8): dart:convert, clear, _keyToken, _keyUser, save, SessionService, package:shared_preferences/shared_preferences.dart, static const

### Community 48 - "Chatbot Repository"
Cohesion: 0.25
Nodes (7): DateTime?, active, ChatSessionModel, createdAt, fromMap, recipeTitle, sessionId

### Community 49 - "Core Services (Flutter) 2"
Cohesion: 0.25
Nodes (7): AppTheme, background, onPrimary, primaryEnd, primaryStart, surface, static const Color

### Community 50 - "Backend Patterns Skill Doc"
Cohesion: 0.43
Nodes (7): AuthService (JWT auth), DI Container class, Authentication & Authorization section, Dependency Injection pattern (Pattern 2), UserController class, UserRepository class, UserService class

### Community 51 - "Backend Patterns Skill Doc 2"
Cohesion: 0.33
Nodes (7): AppError base class, ConflictError class, errorHandler global middleware, ForbiddenError class, NotFoundError class, UnauthorizedError class, ValidationError class

### Community 53 - "Home Screens (Flutter)"
Cohesion: 0.29
Nodes (6): build, description, emoji, isLogged, MealCard, title

### Community 54 - "Core Theme (Flutter) 2"
Cohesion: 0.33
Nodes (5): build, _buildCenterItem, _buildNavItem, CustomBottomNavBar, selectedIndex

### Community 55 - "Flutter Design Docs"
Cohesion: 0.33
Nodes (6): The Ghost Border Fallback (15% opacity outline_variant when contrast is lacking), Input Fields component (no bottom line, filled background), The No-Line Rule (borders forbidden for sectioning; use background tonal shifts instead), Modern Nutrition Cards component, Tonal Layering (elevation via color instead of drop shadows), Progress Bars (The "Vitals" Bar) component

### Community 56 - "Home Widgets (Flutter)"
Cohesion: 0.40
Nodes (4): AiSuggestionCard, build, onTap, VoidCallback

### Community 57 - "Backend Patterns Skill Doc 3"
Cohesion: 0.50
Nodes (4): MongoDB Mongoose connectDB pattern, OrderService (transaction pattern), PostgreSQL Connection Pool pattern, Database Patterns section

### Community 58 - "Progress/Auth Mix"
Cohesion: 0.50
Nodes (4): CustomPainter, ProgressChartPainter, _InsightChartPainter, _WeightHistoryPainter

### Community 59 - "Backend Patterns Skill Doc 4"
Cohesion: 0.67
Nodes (3): Cacheable decorator, CacheService (Redis), Caching Strategies section

### Community 60 - "Backend Patterns Skill Doc 5"
Cohesion: 0.67
Nodes (3): details.md (reference doc), nodejs-backend-patterns Skill, javascript-testing-patterns Skill (referenced)

## Ambiguous Edges - Review These
- `DI Container class` → `AuthService (JWT auth)`  [AMBIGUOUS]
  .agents/skills/nodejs-backend-patterns/references/advanced-patterns.md · relation: references
- `iOS Build GitHub Actions workflow` → `nutriapp Flutter README`  [AMBIGUOUS]
  .github/workflows/ios-build.yml · relation: conceptually_related_to
- `Riverpod state management recommendation` → `pubspec.yaml (nutriapp Flutter project manifest)`  [AMBIGUOUS]
  nutriapp/pubspec.yaml · relation: shares_data_with

## Knowledge Gaps
- **655 isolated node(s):** `name`, `version`, `description`, `main`, `start` (+650 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `DI Container class` and `AuthService (JWT auth)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `iOS Build GitHub Actions workflow` and `nutriapp Flutter README`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Riverpod state management recommendation` and `pubspec.yaml (nutriapp Flutter project manifest)`?**
  _Edge tagged AMBIGUOUS (relation: shares_data_with) - confidence is low._
- **Why does `AppError` connect `Backend Config & AI Utils` to `Fridge & Auth Backend`, `Meal Backend Module`, `Stats Backend Module`, `Chat Backend Module`, `Recipe Backend Module`, `Food Backend Module`, `User Backend Module`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `RecipeModel` connect `Chatbot & Nutrition UI` to `Chatbot Screens (Flutter)`, `Chatbot Presentation Layer`, `Chatbot Data Models`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `successResponse()` connect `Recipe Backend Module` to `Fridge & Auth Backend`, `Meal Backend Module`, `Stats Backend Module`, `Backend Config & AI Utils`, `Chat Backend Module`, `Food Backend Module`, `User Backend Module`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `name`, `version`, `description` to the rest of the system?**
  _664 weakly-connected nodes found - possible documentation gaps or missing edges._