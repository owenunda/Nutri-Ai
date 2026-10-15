// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NutriLife';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonErrorTimeout =>
      'La conexión con el servidor tardó demasiado. Inténtalo de nuevo.';

  @override
  String get commonErrorConnection =>
      'No se pudo conectar con el servidor. Revisa tu conexión a internet.';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileLanguageSystem => 'Usar el del teléfono';

  @override
  String get profileLanguageSheetTitle => 'Elige el idioma';

  @override
  String get commonBack => 'Volver';

  @override
  String get authBrandTagline => 'Tu camino inteligente hacia el bienestar.';

  @override
  String get authLoginTitle => 'Bienvenido de nuevo';

  @override
  String get authLoginSubtitle =>
      'Ingresa tus credenciales para acceder a tu espacio de bienestar.';

  @override
  String get authLoginEmailLabel => 'CORREO ELECTRONICO';

  @override
  String get authLoginPasswordLabel => 'CONTRASENA';

  @override
  String get authForgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get authPasswordUpdatedSignIn =>
      'Contraseña actualizada. Ya puedes iniciar sesión.';

  @override
  String get authLoginButton => 'Iniciar sesion';

  @override
  String get authLoginLoading => 'Iniciando...';

  @override
  String get authLoginOrContinueWith => 'O CONTINUA CON';

  @override
  String get authGoogleTermsPrefix => 'Al continuar con Google aceptas los ';

  @override
  String get authTermsOfService => 'Términos del Servicio';

  @override
  String get authTermsAnd => ' y la ';

  @override
  String get authPrivacyPolicy => 'Política de Privacidad';

  @override
  String get authLoginNoAccount => 'No tienes una cuenta? ';

  @override
  String get authLoginCreateOne => 'Crea una';

  @override
  String get authLoginSuccess => 'Inicio de sesión exitoso.';

  @override
  String get authErrorLogin => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String authErrorNetwork(String details) {
    return 'Error de red: $details';
  }

  @override
  String authErrorUnexpected(String details) {
    return 'Error: $details';
  }

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authRegisterSubtitle =>
      'Comienza tu camino hacia una alimentación inteligente.';

  @override
  String get authRegisterNameLabel => 'NOMBRE COMPLETO';

  @override
  String get authEmailLabel => 'CORREO ELECTRÓNICO';

  @override
  String get authPasswordLabel => 'CONTRASEÑA';

  @override
  String get authConfirmLabel => 'CONFIRMAR';

  @override
  String get authNameRequired => 'El nombre es obligatorio.';

  @override
  String get authRegisterTermsPrefix => 'Acepto los ';

  @override
  String get authRegisterSubmit => 'Registrarse';

  @override
  String get authRegisterSubmitting => 'Registrando...';

  @override
  String get authRegisterOrSignUpWith => 'O REGÍSTRATE CON';

  @override
  String get authRegisterHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get authRegisterSignIn => 'Iniciar sesión';

  @override
  String get authTermsRequired =>
      'Debes aceptar los términos del servicio y la política de privacidad.';

  @override
  String get authRegisterSnackDuplicateTitle => 'Correo ya registrado';

  @override
  String get authRegisterSnackWarningTitle => 'Falta confirmar';

  @override
  String get authRegisterSnackErrorTitle => 'Registro no completado';

  @override
  String get authEmailRequired => 'El correo electrónico es obligatorio.';

  @override
  String get authEmailInvalid => 'Ingresa un correo electrónico válido.';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authPasswordConfirmRequired => 'Confirma tu contraseña.';

  @override
  String get authPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get authForgotTitle => 'Recupera tu contraseña';

  @override
  String get authForgotSubtitle =>
      'Escribe el correo de tu cuenta y te enviaremos un código para crear una contraseña nueva.';

  @override
  String get authForgotSend => 'Enviar código';

  @override
  String get authForgotSending => 'Enviando...';

  @override
  String get authResetTitle => 'Nueva contraseña';

  @override
  String authResetSubtitle(String email) {
    return 'Si $email tiene una cuenta, te enviamos un código de 6 dígitos. Escríbelo y elige tu contraseña nueva.';
  }

  @override
  String get authCodeLabel => 'CÓDIGO';

  @override
  String get authNewPasswordLabel => 'CONTRASEÑA NUEVA';

  @override
  String get authSavePassword => 'Guardar contraseña';

  @override
  String get authSaving => 'Guardando...';

  @override
  String get authCodeResent => 'Te enviamos un código nuevo.';

  @override
  String get authSetPasswordTitle => 'Crea tu contraseña';

  @override
  String get authSetPasswordSubtitle =>
      '¡Ya estás dentro! Si quieres, crea una contraseña para entrar también con tu correo cuando no tengas Google a mano.';

  @override
  String get authSetPasswordSkip => 'Ahora no';

  @override
  String get authVerifyTitle => 'Verifica tu correo';

  @override
  String authVerifySubtitle(String email) {
    return 'Te enviamos un código de 6 dígitos a $email. Escríbelo aquí para activar tu cuenta.';
  }

  @override
  String get authVerifyButton => 'Verificar';

  @override
  String get authVerifying => 'Verificando...';

  @override
  String get authCodeInvalid => 'Escribe los 6 dígitos del código.';

  @override
  String get authResendCode => 'Reenviar código';

  @override
  String authResendCodeIn(int seconds) {
    return 'Reenviar código en $seconds s';
  }

  @override
  String get authLinkTitle => 'Vincula tu cuenta';

  @override
  String get authLinkSubtitle =>
      'Ya tienes una cuenta de NutriLife con este correo. Escribe tu contraseña para vincularla con Google; después podrás entrar de las dos formas.';

  @override
  String get authLinkPasswordRequired => 'Escribe tu contraseña.';

  @override
  String get authLinkButton => 'Vincular';

  @override
  String get authLinking => 'Vinculando...';

  @override
  String get authLinkPasswordUpdated =>
      'Contraseña actualizada. Escríbela para vincular tu cuenta.';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authLoginSuccessTitle => 'Iniciaste sesión con éxito';

  @override
  String get authLoginSuccessBody =>
      'Bienvenido de nuevo. Has ingresado correctamente a tu cuenta.';

  @override
  String get authOnboardingTitle => 'IA nutricional\npersonalizada';

  @override
  String get authOnboardingBody =>
      'Tu asistente nutricional inteligente te ayuda a mejorar tu alimentación según tus objetivos.';

  @override
  String get authDiscoverTitle => 'Descubre Alimentos';

  @override
  String get authDiscoverBody =>
      'Busca tus alimentos favoritos en la barra de búsqueda. Nuestra IA reconoce miles de ingredientes.';

  @override
  String get authAnalyzeTitle => 'Analiza tu Progreso';

  @override
  String get authAnalyzeBody =>
      'Mantente motivado con información detallada sobre tus hábitos. Revisa tus tendencias y celebra cada logro en tu camino.';

  @override
  String get authAnalyzeGoalReached => 'META CUMPLIDA';

  @override
  String get authFlowNext => 'Siguiente paso';

  @override
  String get authFlowStart => 'Comenzar';

  @override
  String get authFlowSkip => 'SALTAR';

  @override
  String get authFlowReviewTerms => 'REVISAR TÉRMINOS';

  @override
  String get authErrorRegister =>
      'No se pudo completar el registro. Inténtalo de nuevo.';

  @override
  String get authErrorVerifyEmail =>
      'No se pudo verificar tu correo. Inténtalo de nuevo.';

  @override
  String get authErrorResendCode =>
      'No se pudo reenviar el código. Inténtalo de nuevo.';

  @override
  String get authErrorSendCode =>
      'No se pudo enviar el código. Inténtalo de nuevo.';

  @override
  String get authErrorResetPassword =>
      'No se pudo cambiar tu contraseña. Inténtalo de nuevo.';

  @override
  String get authErrorSetPassword =>
      'No se pudo guardar tu contraseña. Inténtalo de nuevo.';

  @override
  String get authErrorGoogle =>
      'No se pudo iniciar sesión con Google. Inténtalo de nuevo.';

  @override
  String get authErrorGoogleNotConfigured =>
      'El inicio de sesión con Google no está configurado.';

  @override
  String get authErrorGoogleNoData =>
      'Google no devolvió tus datos. Inténtalo de nuevo.';

  @override
  String get commonUser => 'Usuario';

  @override
  String get setupProgressLabel => 'PROGRESO DE REGISTRO';

  @override
  String get setupSaveErrorTitle => 'No se pudo guardar';

  @override
  String get setupGoalHeading => 'Define tu objetivo';

  @override
  String get setupGoalSubtitle =>
      'Calcularemos tu plan según lo que\nquieras lograr.';

  @override
  String get setupGoalLoseTitle => 'Bajar de peso';

  @override
  String get setupGoalLoseSubtitle => 'Déficit calórico saludable';

  @override
  String get setupGoalMaintainTitle => 'Mantener peso';

  @override
  String get setupGoalMaintainSubtitle => 'Estabilidad y nutrición diaria';

  @override
  String get setupGoalGainTitle => 'Subir de peso';

  @override
  String get setupGoalGainSubtitle => 'Superávit para masa muscular';

  @override
  String get setupGoalPlanBadge => 'PLAN PERSONALIZADO';

  @override
  String get setupGoalCaloriesLabel => 'CALORÍAS DIARIAS RECOMENDADAS';

  @override
  String get setupGoalCaloriesNote =>
      'Basado en tu metabolismo basal y\nnivel de actividad actual.';

  @override
  String get setupGoalSaving => 'Guardando meta...';

  @override
  String get setupGoalStart => 'Empieza tu meta';

  @override
  String get setupGoalSaveError =>
      'No se pudo guardar tu meta. Inténtalo de nuevo.';

  @override
  String get setupProfileHeading => 'Completa tu perfil';

  @override
  String get setupProfileSubtitle =>
      'Estos datos nos ayudan a personalizar tu\nplan nutricional.';

  @override
  String get setupAgeLabel => 'EDAD';

  @override
  String get setupWeightLabel => 'PESO (KG)';

  @override
  String get setupHeightLabel => 'ALTURA (CM)';

  @override
  String get setupSexLabel => 'SEXO';

  @override
  String get setupSexMale => 'Hombre';

  @override
  String get setupSexFemale => 'Mujer';

  @override
  String get setupUnitYears => 'años';

  @override
  String get setupPrecisionTitle => 'Precisión NutriLife';

  @override
  String get setupPrecisionBody =>
      'Tu metabolismo basal se calculará\nautomáticamente.';

  @override
  String get setupProfileSaving => 'Guardando...';

  @override
  String get setupProfileSave => 'Guardar perfil';

  @override
  String get setupAgeRequired => 'La edad es obligatoria.';

  @override
  String get setupAgeInvalid => 'Ingresa una edad válida.';

  @override
  String get setupAgeTooYoung => 'Debes tener al menos 16 años.';

  @override
  String get setupWeightRequired => 'El peso es obligatorio.';

  @override
  String get setupWeightInvalid => 'Ingresa un peso válido.';

  @override
  String get setupWeightOutOfRange => 'Selecciona un peso válido.';

  @override
  String get setupHeightRequired => 'La altura es obligatoria.';

  @override
  String get setupHeightInvalid => 'Ingresa una altura válida.';

  @override
  String get setupHeightOutOfRange =>
      'La altura debe estar entre 1.50 cm y 2.50 cm.';

  @override
  String get setupSexRequired => 'Selecciona tu sexo para continuar.';

  @override
  String get setupSnackMissingTitle => 'Falta un dato';

  @override
  String get setupProfileSaveError =>
      'No se pudo guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get setupErrorNothingToSave => 'No hay datos para guardar.';

  @override
  String get setupErrorSave =>
      'No se pudo guardar la información. Inténtalo de nuevo.';

  @override
  String get commonNavHome => 'Inicio';

  @override
  String get commonNavFoods => 'Alimentos';

  @override
  String get commonNavAi => 'IA';

  @override
  String get commonNavProgress => 'Progreso';

  @override
  String get commonNavProfile => 'Perfil';

  @override
  String get homeSummaryLabel => 'RESUMEN';

  @override
  String homeGreeting(String name) {
    return 'Hola $name';
  }

  @override
  String get homeAiCardTitle => 'Pregúntale a la IA qué comer.';

  @override
  String get homeAiCardSubtitle =>
      'Ideas de comidas personalizadas según tus metas.';

  @override
  String homeAddToMeal(String meal) {
    return 'Agregar a $meal';
  }

  @override
  String get homeTodayMealsTitle => 'Comidas de hoy';

  @override
  String get homeViewHistory => 'Ver historial';

  @override
  String get homeTodayCaloriesTitle => 'Calorías de hoy';

  @override
  String homeTodayCaloriesTarget(String kcal) {
    return 'Objetivo: $kcal kcal';
  }

  @override
  String get homeTodayCaloriesTotal => 'Total consumido';

  @override
  String get homeTodayCaloriesConsumed => 'consumidas';

  @override
  String get homeGoalLoading => 'Cargando tu objetivo diario...';

  @override
  String get homeGoalError => 'No se pudo cargar tu objetivo diario.';

  @override
  String get homeGoalIncomplete =>
      'Completa tu perfil para calcular tu objetivo diario.';

  @override
  String homeGoalRemaining(String kcal) {
    return 'Te faltan $kcal kcal para cumplir tu objetivo de hoy.';
  }

  @override
  String homeGoalExceeded(String kcal) {
    return 'Te excediste por $kcal kcal de tu objetivo diario.';
  }

  @override
  String get homeGoalReached => '¡Has alcanzado tu objetivo diario!';

  @override
  String get mealsTypeBreakfast => 'Desayuno';

  @override
  String get mealsTypeLunch => 'Almuerzo';

  @override
  String get mealsTypeDinner => 'Cena';

  @override
  String get mealsTypeSnack => 'Snack';

  @override
  String get mealsNotLoggedYet => 'Aún no registrada';

  @override
  String mealsPortionsOne(String amount) {
    return '$amount porción';
  }

  @override
  String mealsPortionsOther(String amount) {
    return '$amount porciones';
  }

  @override
  String get mealsErrorAddFood => 'No se pudo registrar la comida';

  @override
  String get mealsErrorAddRecipe => 'No se pudo registrar la receta';

  @override
  String get mealsErrorDeleteRecipe => 'No se pudo borrar la receta';

  @override
  String get mealsErrorDeleteItem => 'No se pudo borrar';

  @override
  String get mealsErrorLoadDay => 'No se pudieron cargar tus comidas';

  @override
  String get mealsHistoryTitle => 'Historial de comidas';

  @override
  String get mealsPickDate => 'Elegir fecha';

  @override
  String get mealsPreviousDay => 'Día anterior';

  @override
  String get mealsNextDay => 'Día siguiente';

  @override
  String get mealsToday => 'Hoy';

  @override
  String get mealsYesterday => 'Ayer';

  @override
  String mealsDateLabel(String weekday, int day, String month) {
    return '$weekday $day $month';
  }

  @override
  String mealsAddedTo(String meal, int kcal) {
    return 'Agregado a $meal · $kcal kcal';
  }

  @override
  String mealsRegisteredIn(String meal, int kcal) {
    return 'Registrado en $meal · $kcal kcal';
  }

  @override
  String get mealsUndo => 'Deshacer';

  @override
  String get mealsUndoFailed => 'No se pudo deshacer';

  @override
  String mealsKcalPerUnit(int kcal, String unit) {
    return '$kcal kcal por $unit';
  }

  @override
  String get mealsLess => 'Menos';

  @override
  String get mealsMore => 'Más';

  @override
  String mealsDetailTitle(String meal, int kcal) {
    return '$meal · $kcal kcal';
  }

  @override
  String get mealsOtherFoods => 'OTROS ALIMENTOS';

  @override
  String get mealsDeleteRecipeTitle => '¿Borrar receta?';

  @override
  String mealsDeleteRecipeBody(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sus $count ingredientes',
      one: 'su ingrediente',
    );
    return 'Se quitará \"$title\" con $_temp0 de esta comida.';
  }

  @override
  String get mealsDelete => 'Borrar';

  @override
  String get mealsDeleteRecipe => 'Borrar receta';

  @override
  String get mealsViewRecipe => 'Ver receta';

  @override
  String mealsDeleteItem(String name) {
    return 'Borrar $name';
  }

  @override
  String get mealsRegisterNoIngredients =>
      'Esta receta no trae ingredientes para registrar';

  @override
  String get mealsRegisterTitle => 'Registrar comida';

  @override
  String get mealsLessPortions => 'Menos porciones';

  @override
  String get mealsMorePortions => 'Más porciones';

  @override
  String mealsCalculatingCalories(int servings) {
    return 'Calculando calorías… · la receta rinde $servings';
  }

  @override
  String mealsRecipeYield(int kcal, int servings) {
    return '$kcal kcal · la receta rinde $servings';
  }

  @override
  String get mealsLoadFoodsError =>
      'No pudimos cargar los alimentos de la receta. Intenta de nuevo.';

  @override
  String mealsRegisterIn(String meal) {
    return 'Registrar en $meal';
  }
}
