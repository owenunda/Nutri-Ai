class ApiRoutes {
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authGoogle = '/auth/google';
  static const String authGoogleLink = '/auth/google/link';
  static const String authVerifyEmail = '/auth/verify-email';
  static const String authVerifyEmailResend = '/auth/verify-email/resend';
  static const String authPasswordForgot = '/auth/password/forgot';
  static const String authPasswordReset = '/auth/password/reset';
  static const String authHealth = '/auth/health';
  static const String userProfile = '/user/profile';
  static const String userAccount = '/user/account';
  static const String userPassword = '/user/password';
  static const String userPhysicalHistory = '/user/physical/history';
  static const String statsTodayCalories = '/stats/today-calories';
  static const String statsConsumptionValidation =
      '/stats/consumption-validation';
  static const String n8nChat = '/n8n/chat';
  static const String chatSessionClose = '/chat/session/close';
  static const String chatSessions = '/chat/sessions';
  static const String chatActiveSession = '/chat/session';
  static const String chatQuota = '/chat/quota';
  static String chatSessionMessages(int sessionId) =>
      '/chat/sessions/$sessionId/messages';
  static String chatSessionActivate(int sessionId) =>
      '/chat/sessions/$sessionId/activate';
  static const String fridge = '/fridge';
  static const String meals = '/meals';
  static String mealItems(int mealRecordId) => '/meals/$mealRecordId/items';
  static const String mealsDay = '/meals/day';
  static String mealItem(int detailId) => '/meals/items/$detailId';
  static String mealRecipeLog(int mealRecordId) => '/meals/$mealRecordId/recipe-log';
  static String mealRecipeLogById(int recipeLogId) => '/meals/recipe-logs/$recipeLogId';
  static const String statsWeek = '/stats/week';
  static const String userPhysical = '/user/physical';
  static const String hydration = '/hydration';
  static const String hydrationGlass = '/hydration/glass';
  static const String hydrationGlassUndo = '/hydration/glass/undo';
  static const String hydrationImport = '/hydration/import';
}
