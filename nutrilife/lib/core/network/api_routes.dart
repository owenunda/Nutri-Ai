class ApiRoutes {
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authHealth = '/auth/health';
  static const String userProfile = '/user/profile';
  static const String userPhysicalHistory = '/user/physical/history';
  static const String statsTodayCalories = '/stats/today-calories';
  static const String statsConsumptionValidation =
      '/stats/consumption-validation';
  static const String n8nChat = '/n8n/chat';
  static const String chatSessionClose = '/chat/session/close';
  static const String chatSessions = '/chat/sessions';
  static const String chatActiveSession = '/chat/session';
  static String chatSessionMessages(int sessionId) =>
      '/chat/sessions/$sessionId/messages';
  static String chatSessionActivate(int sessionId) =>
      '/chat/sessions/$sessionId/activate';
  static const String fridge = '/fridge';
}
