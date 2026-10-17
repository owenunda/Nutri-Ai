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
  String get commonRetry => 'Reintentar';

  @override
  String get commonContinue => 'Continuar';

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

  @override
  String get nutritionAddFridgeTitle => 'Agregar a mi nevera';

  @override
  String get nutritionLogConsumedTitle => 'Registrar consumido';

  @override
  String get nutritionAddFridgeSubtitle =>
      'Lo guardarás en tu nevera para que la IA pueda sugerirlo al chatear.';

  @override
  String get nutritionLogConsumedSubtitle =>
      'Se registrará como consumido en la comida que elijas para que el conteo de calorías sea correcto.';

  @override
  String get nutritionFoodNameLabel => 'Nombre del alimento';

  @override
  String get nutritionFoodNameHint => 'Ej. Banana';

  @override
  String get nutritionFoodNameRequired => 'Por favor ingresa un nombre';

  @override
  String get nutritionSimilarFoodExists =>
      'Ya existe un alimento parecido. Elige uno para usarlo:';

  @override
  String nutritionUseFood(String name) {
    return 'Usar $name';
  }

  @override
  String get nutritionChange => 'Cambiar';

  @override
  String get nutritionCaloriesLabel => 'Calorías (Kcal)';

  @override
  String get nutritionCaloriesHint => 'Ej. 105';

  @override
  String get nutritionCaloriesRequired => 'Ingresa calorías';

  @override
  String get nutritionMustBePositive => 'Debe ser > 0';

  @override
  String get nutritionPortionLabel => 'Porción';

  @override
  String get nutritionAmountHaveLabel => 'Cantidad que tienes';

  @override
  String get nutritionAmountConsumedLabel => 'Cantidad consumida';

  @override
  String get nutritionAmountRequired => 'Ingresa cantidad';

  @override
  String get nutritionAmountLabel => 'Cantidad';

  @override
  String get nutritionUnitLabel => 'Unidad';

  @override
  String get nutritionMealOfDay => 'Comida del día';

  @override
  String get nutritionSaving => 'Guardando...';

  @override
  String get nutritionSaveInFridge => 'Guardar en nevera';

  @override
  String get nutritionSaveInMyFridge => 'Guardar en mi nevera';

  @override
  String get nutritionLogConsumption => 'Registrar consumo';

  @override
  String get nutritionGenericError => 'Error';

  @override
  String get nutritionErrorNoFoodId =>
      'No se pudo obtener el identificador del alimento. Inténtalo de nuevo.';

  @override
  String get nutritionErrorRegisterFailed =>
      'No se pudo completar el registro. Inténtalo de nuevo.';

  @override
  String get nutritionDoneTitle => '¡Listo!';

  @override
  String get nutritionDoneFridge => 'Tu alimento ya está en la nevera.';

  @override
  String get nutritionDoneConsumed => 'Tu consumo quedó registrado.';

  @override
  String get nutritionAddAnotherFridge => 'Agregar otro a mi nevera';

  @override
  String get nutritionLogAnother => 'Registrar otro consumo';

  @override
  String get nutritionFridgeTitle => 'Mi nevera';

  @override
  String get nutritionFridgeSubtitle =>
      'Lo que tienes en casa. La IA lo sugiere primero cuando lo adjuntas al chat.';

  @override
  String get nutritionHowItWorks => '¿Cómo funciona?';

  @override
  String get nutritionCommonTitle => 'Comunes';

  @override
  String get nutritionManualEntryTitle => 'Entrada manual';

  @override
  String get nutritionHelpFridgeBody =>
      'Alimentos que tienes guardados. Al adjuntarlos al chat, la IA los prioriza.';

  @override
  String get nutritionHelpCommonBody =>
      'Catálogo general de NutriLife para cuando no encuentras lo que buscas.';

  @override
  String get nutritionHelpManualBody =>
      'Elige entre \"A mi nevera\" (a tu nevera) o \"Lo consumí\" (alimento registrado, sin guardar).';

  @override
  String get nutritionGotIt => 'Entendido';

  @override
  String get nutritionCustomTitle => 'Agregar personalizado';

  @override
  String get nutritionCustomBody =>
      '¿No encuentras tu alimento? Agrégalo y elige si lo tienes en casa o solo lo registraste.';

  @override
  String get nutritionToFridge => 'A mi nevera';

  @override
  String get nutritionIAteIt => 'Lo consumí';

  @override
  String get nutritionSavedSubtitle => 'Lo que tienes guardado';

  @override
  String get nutritionCatalogSubtitle => 'Catálogo de NutriLife';

  @override
  String get nutritionSeeAllItems => 'Ver todo';

  @override
  String get nutritionSeeAllFoods => 'Ver todos';

  @override
  String get nutritionSeeLess => 'Ver menos';

  @override
  String nutritionResultsCount(int count) {
    return 'Resultados ($count)';
  }

  @override
  String get nutritionTip =>
      'Tip: agregar primero lo que tienes en tu nevera (no lo que comiste fuera) ayuda a la IA a sugerirte recetas con lo que ya está en casa.';

  @override
  String nutritionNoResults(String query) {
    return 'No encontramos \"$query\". Prueba con otro nombre o agrégalo desde \"Entrada manual\".';
  }

  @override
  String get nutritionNoCommonFoods => 'No hay alimentos comunes cargados.';

  @override
  String nutritionFoodAddedToFridge(String food) {
    return '$food agregado a tu nevera';
  }

  @override
  String nutritionFoodLoggedIn(String food, String meal) {
    return '$food registrado en $meal';
  }

  @override
  String get nutritionErrorAdd => 'No se pudo agregar';

  @override
  String get nutritionErrorLog => 'No se pudo registrar';

  @override
  String nutritionBulkResult(int ok, int total) {
    return '$ok/$total procesados correctamente.';
  }

  @override
  String nutritionBulkResultWithFailed(int ok, int total, String names) {
    return '$ok/$total procesados correctamente. Fallaron: $names';
  }

  @override
  String get nutritionAskMealTitle => '¿En qué comida?';

  @override
  String get nutritionAskMealBody =>
      'Se registrará como consumido en la comida seleccionada para todos los alimentos marcados.';

  @override
  String get nutritionActions => 'Acciones';

  @override
  String get nutritionClearSelection => 'Quitar selección';

  @override
  String nutritionSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos seleccionados',
      one: '1 alimento seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get nutritionEmptyFridgeTitle => 'Tu nevera está vacía';

  @override
  String get nutritionEmptyFridgeBody =>
      'Agrega lo que tienes en casa desde \"Entrada manual\" para que la IA pueda sugerírtelo en el chat.';

  @override
  String get nutritionAllFoodsTitle => 'Todos los alimentos';

  @override
  String nutritionItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems',
      one: '1 ítem',
    );
    return '$_temp0';
  }

  @override
  String nutritionFoodsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos',
      one: '1 alimento',
    );
    return '$_temp0';
  }

  @override
  String get nutritionFridgeEmptyAll =>
      'Tu nevera está vacía. Agrega alimentos desde \"Entrada manual\" o desde la pestaña Comunes.';

  @override
  String nutritionEditAmount(String name) {
    return 'Editar cantidad de $name';
  }

  @override
  String nutritionFridgeItemRemoved(String name) {
    return '$name se quitó de tu nevera';
  }

  @override
  String nutritionFridgeAmountUpdated(String name) {
    return 'Cantidad de $name actualizada';
  }

  @override
  String get nutritionRemoveFoodTitle => 'Quitar alimento';

  @override
  String nutritionRemoveFoodBody(String name) {
    return '¿Quieres quitar $name de tu nevera? Ya no aparecerá entre tus alimentos disponibles.';
  }

  @override
  String get nutritionRemove => 'Quitar';

  @override
  String get nutritionAmountGreaterThanZero =>
      'Ingresa una cantidad mayor que 0';

  @override
  String nutritionCantSubtractMore(String quantity) {
    return 'No puedes descontar más de lo que tienes ($quantity).';
  }

  @override
  String nutritionAvailable(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String nutritionAdjustLabel(String unit) {
    return 'Cantidad para sumar o descontar ($unit)';
  }

  @override
  String nutritionNewTotalLabel(String unit) {
    return 'Cantidad total nueva ($unit)';
  }

  @override
  String get nutritionSubtract => 'Descontar';

  @override
  String get nutritionIncrease => 'Aumentar';

  @override
  String get nutritionSaveExactAmount => 'Guardar cantidad exacta';

  @override
  String get nutritionRemoveFromFridge => 'Quitar de la nevera';

  @override
  String get nutritionSearchHint => 'Busca más de 100,000 alimentos...';

  @override
  String get nutritionClearSearch => 'Borrar búsqueda';

  @override
  String get nutritionUnitOne => '1 unidad';

  @override
  String get nutritionUnitServing => '1 porción';

  @override
  String get nutritionUnitCup => '1 taza';

  @override
  String get nutritionUnitTablespoon => '1 cucharada';

  @override
  String get nutritionUnitSlice => '1 rebanada';

  @override
  String nutritionCountUnit(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount unidades',
      one: '1 unidad',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountServing(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount porciones',
      one: '1 porción',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountCup(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount tazas',
      one: '1 taza',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountTablespoon(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount cucharadas',
      one: '1 cucharada',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountSlice(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount rebanadas',
      one: '1 rebanada',
    );
    return '$_temp0';
  }

  @override
  String get nutritionErrorServerConnection =>
      'Error de conexión con el servidor';

  @override
  String get nutritionErrorLoadFoods => 'Error al obtener alimentos';

  @override
  String nutritionErrorUnexpectedLoadFoods(String error) {
    return 'Ocurrió un error inesperado al obtener los alimentos: $error';
  }

  @override
  String get nutritionErrorRegisterFood => 'Error al registrar el alimento';

  @override
  String get nutritionErrorRegisterFoodServer =>
      'Error al registrar el alimento en el servidor';

  @override
  String nutritionErrorUnexpectedRegisterFood(String error) {
    return 'Ocurrió un error inesperado al registrar el alimento: $error';
  }

  @override
  String get nutritionErrorLoadFridge => 'Error al obtener la nevera';

  @override
  String nutritionErrorUnexpectedLoadFridge(String error) {
    return 'Ocurrió un error inesperado al obtener la nevera: $error';
  }

  @override
  String get nutritionErrorAddToFridge => 'No se pudo agregar a la nevera';

  @override
  String nutritionErrorAddToFridgeDetail(String error) {
    return 'No se pudo agregar a la nevera: $error';
  }

  @override
  String get nutritionErrorUpdateAmount => 'No se pudo actualizar la cantidad';

  @override
  String nutritionErrorUpdateAmountDetail(String error) {
    return 'No se pudo actualizar la cantidad: $error';
  }

  @override
  String get nutritionErrorRemoveFromFridge => 'No se pudo quitar de la nevera';

  @override
  String nutritionErrorRemoveFromFridgeDetail(String error) {
    return 'No se pudo quitar de la nevera: $error';
  }

  @override
  String nutritionUnitNameUnit(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'unidades',
      one: 'unidad',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameServing(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'porciones',
      one: 'porción',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tazas',
      one: 'taza',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameTablespoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cucharadas',
      one: 'cucharada',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rebanadas',
      one: 'rebanada',
    );
    return '$_temp0';
  }

  @override
  String get commonDone => 'Listo';

  @override
  String get chatHistoryBarrierLabel => 'Cerrar historial';

  @override
  String get chatWaitForReply => 'Espera a que el chef termine de responder';

  @override
  String get chatDeleteTitle => 'Eliminar chat';

  @override
  String get chatDeleteConfirm =>
      '¿Seguro que quieres eliminar esta conversación?';

  @override
  String get chatDeleteButton => 'Eliminar';

  @override
  String get chatTooltipHistory => 'Historial';

  @override
  String get chatTooltipNewChat => 'Nueva conversación';

  @override
  String get chatWelcomeTitle => '¿Cómo puedo ayudarte hoy?';

  @override
  String get chatWelcomeSubtitle =>
      'Pídeme recetas, consejos de nutrición o planes de alimentación.';

  @override
  String get chatInputHint => 'Mensaje a NutriLife...';

  @override
  String chatRateLimitExhausted(int seconds) {
    return 'Límite alcanzado · reintenta en ${seconds}s';
  }

  @override
  String chatRateLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count mensajes este minuto',
      one: 'Te queda 1 mensaje este minuto',
    );
    return '$_temp0';
  }

  @override
  String get chatRateLimitReplyMinute =>
      'Espera un momento, alcanzaste el límite de mensajes por minuto';

  @override
  String chatRateLimitReplyMinutes(int minutes) {
    return 'Espera unos $minutes minutos, alcanzaste el límite de mensajes';
  }

  @override
  String get chatGenericError =>
      'Lo siento, ocurrió un error. Intenta de nuevo.';

  @override
  String get chatHistoryTitle => 'Conversaciones';

  @override
  String get chatHistoryEmpty => 'Sin conversaciones aún';

  @override
  String get chatSessionFallbackTitle => 'Conversación';

  @override
  String get chatSessionActive => 'Activa';

  @override
  String chatHistoryToday(String time) {
    return 'Hoy, $time';
  }

  @override
  String chatHistoryYesterday(String time) {
    return 'Ayer, $time';
  }

  @override
  String chatHistoryDate(int day, String month) {
    return '$day $month';
  }

  @override
  String chatStepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasos',
      one: '1 paso',
    );
    return '$_temp0';
  }

  @override
  String chatStepNumber(int number) {
    return 'Paso $number';
  }

  @override
  String get chatStepByStep => 'Paso a paso';

  @override
  String get chatViewStepByStep => 'Ver paso a paso';

  @override
  String get chatChefTip => 'Tip del chef';

  @override
  String chatServingsShort(int count) {
    return '$count PORC.';
  }

  @override
  String chatServingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porciones',
      one: '1 porción',
    );
    return '$_temp0';
  }

  @override
  String get chatSeeMore => 'Ver más';

  @override
  String get chatSeeLess => 'Ver menos';

  @override
  String get chatViewFullRecipe => 'Ver receta completa';

  @override
  String get chatLogMeal => 'Registrar comida';

  @override
  String chatStepProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get chatTipsTab => 'Tips';

  @override
  String get chatPrevious => 'Anterior';

  @override
  String get chatNext => 'Siguiente';

  @override
  String get chatSwipeHint => 'Desliza para continuar';

  @override
  String get chatChefTips => 'Tips del chef';

  @override
  String get chatPickerTitle => 'Agregar alimentos';

  @override
  String get chatPickerIntro =>
      'Mi nevera: lo que tienes en casa. Comunes: catálogo general.';

  @override
  String get chatPickerTabFridge => 'Mi nevera';

  @override
  String get chatPickerTabCommon => 'Comunes';

  @override
  String get chatPickerSearchFridge => 'Buscar en tu nevera';

  @override
  String get chatPickerSearchCommon => 'Buscar en comunes';

  @override
  String chatPickerAddCount(int count) {
    return 'Agregar $count al mensaje';
  }

  @override
  String get chatPickerErrorTitle => 'No pudimos leer tu nevera';

  @override
  String get chatPickerNoResults => 'Sin resultados';

  @override
  String chatPickerNoResultsFridge(String query) {
    return 'No encontramos \"$query\" en tu nevera.';
  }

  @override
  String chatPickerNoResultsCommon(String query) {
    return 'No encontramos \"$query\" en los alimentos comunes.';
  }

  @override
  String chatPickerSeeInFridge(int count) {
    return 'Ver en Mi nevera ($count)';
  }

  @override
  String chatPickerSeeInCommon(int count) {
    return 'Ver en Comunes ($count)';
  }

  @override
  String get chatPickerCommonEmptyTitle => 'Sin alimentos comunes';

  @override
  String get chatPickerCommonEmptyBody =>
      'No pudimos cargar el catálogo. Intenta de nuevo más tarde.';

  @override
  String get chatPickerFridgeEmptyTitle => 'Tu nevera está vacía';

  @override
  String get chatPickerFridgeEmptyBody =>
      'Agrega alimentos desde la pestaña Alimentos o elige de Comunes.';

  @override
  String get chatPickerNoAmount => 'Sin cantidad';

  @override
  String get chatErrorTimeout =>
      'El chef se está tomando su tiempo. Intenta de nuevo.';

  @override
  String get chatErrorServerConnection => 'Error de conexión con el servidor';

  @override
  String get chatErrorUnexpectedResponse => 'Respuesta inesperada del servidor';

  @override
  String chatErrorReadReply(String error) {
    return 'No se pudo leer la respuesta del chef: $error';
  }

  @override
  String get chatErrorLoadHistory => 'Error al obtener el historial';

  @override
  String chatErrorUnexpected(String error) {
    return 'Ocurrió un error inesperado: $error';
  }

  @override
  String get chatErrorLoadSession => 'Error al obtener la sesión';

  @override
  String get chatErrorLoadConversation => 'Error al cargar la conversación';

  @override
  String get chatErrorOpenConversation => 'Error al abrir la conversación';

  @override
  String get chatErrorCloseSession => 'Error al cerrar la sesión';

  @override
  String get chatNoReply => 'Sin respuesta';

  @override
  String get progressKicker => 'PROGRESO SEMANAL';

  @override
  String progressGreeting(String name) {
    return 'Buen progreso,\n$name!';
  }

  @override
  String progressGoalPill(String goal) {
    return 'Meta:\n$goal';
  }

  @override
  String get progressGoalLose => 'Bajar peso';

  @override
  String get progressGoalGain => 'Subir peso';

  @override
  String get progressGoalMaintain => 'Mantener peso';

  @override
  String get progressGoalNone => 'Sin meta';

  @override
  String get progressStatusNoData => 'Sin datos';

  @override
  String get progressStatusExceeded => 'EXCEDIDO';

  @override
  String get progressErrorTitle => 'No se pudo cargar tu progreso';

  @override
  String get progressErrorLoadShort => 'No se pudo cargar tu progreso.';

  @override
  String get progressErrorLoad =>
      'No se pudo cargar tu progreso. Inténtalo de nuevo.';

  @override
  String get progressErrorLoadDailyGoal =>
      'No se pudo cargar tu meta diaria. Inténtalo de nuevo.';

  @override
  String get progressErrorSaveWeight => 'No se pudo guardar tu peso.';

  @override
  String get progressErrorInvalidData =>
      'El servidor respondió con datos inválidos.';

  @override
  String get progressErrorLoadInfo => 'No se pudo cargar la información.';

  @override
  String get progressRetry => 'Intentar de nuevo';

  @override
  String get progressWeightSummaryTitle => 'Resumen de peso';

  @override
  String progressWeightDown(String amount) {
    return 'Tu peso bajó\n$amount desde el registro anterior';
  }

  @override
  String progressWeightUp(String amount) {
    return 'Tu peso subió\n$amount desde el registro anterior';
  }

  @override
  String progressWeightChanged(String amount) {
    return 'Tu peso cambió\n$amount desde el registro anterior';
  }

  @override
  String get progressCurrentWeight => 'Peso actual';

  @override
  String get progressNoRecord => 'Sin registro';

  @override
  String get progressCompareHint =>
      'Comparado con tu registro físico anterior.';

  @override
  String get progressAddAnotherHint =>
      'Registra otro peso más adelante para ver tu evolución.';

  @override
  String get progressRegisterWeight => 'Registrar peso';

  @override
  String get progressSummaryWeek => 'Resumen de la semana';

  @override
  String get progressSummaryNutrition => 'Resumen nutricional';

  @override
  String get progressTodayCaloriesTitle => 'Calorías de hoy';

  @override
  String get progressKcalConsumed => 'kcal consumidas';

  @override
  String progressKcalOfLimit(String limit) {
    return 'de $limit kcal';
  }

  @override
  String get progressCompleteDataHint =>
      'Completa tus datos físicos y tu meta para calcular tu límite diario.';

  @override
  String progressGoalAndRemaining(String limit, String remaining) {
    return 'Meta diaria: $limit kcal. Te quedan $remaining kcal disponibles hoy.';
  }

  @override
  String get progressHistoryTitle => 'Historial de peso';

  @override
  String get progressHistoryNoCurrent => 'Sin peso actual';

  @override
  String progressHistoryCurrent(String weight) {
    return '${weight}kg Actual';
  }

  @override
  String get progressHistoryEmpty => 'Aún no tienes historial físico.';

  @override
  String get progressAxisStart => 'INICIO';

  @override
  String get progressAxisToday => 'HOY';

  @override
  String get progressTileConsumed => 'CONSUMIDAS';

  @override
  String get progressTileLoggedToday => 'Registradas hoy';

  @override
  String get progressTileDailyGoal => 'META DIARIA';

  @override
  String get progressTileRemaining => 'RESTANTES';

  @override
  String get progressTileStatus => 'ESTADO';

  @override
  String get progressTileDailyAverage => 'PROMEDIO DIARIO';

  @override
  String get progressTileDaysOnTarget => 'DÍAS EN META';

  @override
  String get progressTileWeekTotal => 'TOTAL SEMANA';

  @override
  String progressDaysOfSeven(int count) {
    return '$count de 7';
  }

  @override
  String get progressWeekTitle => 'Consumo semanal';

  @override
  String progressWeekAverage(String average) {
    return 'Promedio diario · $average kcal';
  }

  @override
  String progressWeekAverageOnTarget(String average, int days) {
    return 'Promedio diario · $average kcal · $days de 7 días en tu meta';
  }

  @override
  String progressWeekOnTargetBadge(int days) {
    return '$days/7 en meta';
  }

  @override
  String progressWeekDaySelected(String weekday, int day, String kcal) {
    return '$weekday $day · $kcal kcal';
  }

  @override
  String get progressCompleteProfile => 'Completa tu perfil';

  @override
  String get progressSheetHintNoLast => 'Escribe tu peso o ajústalo con − y +';

  @override
  String progressSheetLastEntry(String weight) {
    return 'Último registro: $weight kg';
  }

  @override
  String get progressSheetSame => 'Igual que el último';

  @override
  String progressSheetIncrease(String weight) {
    return '+$weight kg desde el último';
  }

  @override
  String progressSheetDecrease(String weight) {
    return '−$weight kg desde el último';
  }

  @override
  String get progressSheetSubtract => 'Restar 0,1 kg';

  @override
  String get progressSheetAdd => 'Sumar 0,1 kg';

  @override
  String get progressSheetHeightLabel => 'Altura (cm)';

  @override
  String get progressSheetWeightRangeError =>
      'El peso debe estar entre 30 y 300 kg';

  @override
  String get progressSheetHeightRequired => 'Ingresa tu altura en cm';

  @override
  String get progressSheetSave => 'Guardar peso';

  @override
  String get profileLoadError => 'No se pudo cargar tu perfil.';

  @override
  String get profileLoadErrorRetry =>
      'No se pudo cargar tu perfil. Inténtalo de nuevo.';

  @override
  String get profileUpdateError => 'No se pudo actualizar tu perfil.';

  @override
  String get profileUpdateErrorRetry =>
      'No se pudo actualizar tu perfil. Inténtalo de nuevo.';

  @override
  String get profileDeleteError => 'No se pudo eliminar tu cuenta.';

  @override
  String get profileDeleteErrorRetry =>
      'No se pudo eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String get profileDeleteWrongPassword => 'La contraseña no es correcta.';

  @override
  String get profileDeleteGoogleMismatch =>
      'Esa cuenta de Google no corresponde a este perfil.';

  @override
  String get profileDeleteGoogleFailed =>
      'No se pudo confirmar con Google. Inténtalo de nuevo.';

  @override
  String get profileMemberDefault => 'Miembro de NutriLife';

  @override
  String profileMemberSince(String year) {
    return 'Miembro desde $year';
  }

  @override
  String profileMemberPlan(String plan) {
    return 'Miembro $plan';
  }

  @override
  String profileMemberPlanSince(String plan, String year) {
    return 'Miembro $plan desde $year';
  }

  @override
  String get profileStatAge => 'EDAD';

  @override
  String get profileStatWeight => 'PESO';

  @override
  String get profileStatHeight => 'ALTURA';

  @override
  String get profileGoalHeading => 'Objetivo nutricional';

  @override
  String get profileGoalActive => 'ACTIVO';

  @override
  String get profileGoalPillLose => 'Bajar peso';

  @override
  String get profileGoalPillMaintain => 'Mantener';

  @override
  String get profileGoalPillGain => 'Subir masa';

  @override
  String get profileSettingsHeading => 'Ajustes y recordatorios';

  @override
  String get premiumTitle => 'NutriLife Premium';

  @override
  String get profilePremiumSubtitle => 'Planes y beneficios';

  @override
  String get profileRemindersTitle => 'Recordatorios de comida';

  @override
  String get profileRemindersSubtitle => 'Alertas diarias para 4 comidas';

  @override
  String get profileNotificationsTitle => 'Configuración de notificaciones';

  @override
  String get profileNotificationsSubtitle => 'Push, correo y SMS';

  @override
  String get profileConfigTitle => 'Configuración';

  @override
  String get profileConfigSubtitle => 'Edad, altura, sexo, objetivo y correo';

  @override
  String get profileLegalHeading => 'Legal';

  @override
  String get profileTermsTitle => 'Términos y condiciones';

  @override
  String get profileTermsSubtitle => 'Reglas de uso de NutriLife';

  @override
  String get profilePrivacyTitle => 'Política de privacidad';

  @override
  String get profilePrivacySubtitle => 'Cómo tratamos tus datos';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileLoadErrorTitle => 'No pudimos cargar tu perfil';

  @override
  String get profileRetry => 'Intentar de nuevo';

  @override
  String get profileDeleteDone => 'Tu cuenta y tus datos fueron eliminados.';

  @override
  String get profileDeleteDialogTitle => '¿Eliminar tu cuenta?';

  @override
  String get profileDeleteDialogBody =>
      'Se borrarán para siempre tu perfil, historial de peso, comidas, nevera, recetas y conversaciones. Esta acción no se puede deshacer.';

  @override
  String get profileDeletePasswordRequired =>
      'Escribe tu contraseña para confirmar.';

  @override
  String get profileDeletePasswordLabel => 'Contraseña';

  @override
  String get profileDeleteGoogleHint =>
      'Para confirmar, elige tu cuenta de Google.';

  @override
  String get profileDeleting => 'Eliminando...';

  @override
  String get profileDeleteConfirm => 'Eliminar';

  @override
  String get profileDeleteConfirmGoogle => 'Confirmar con Google';

  @override
  String get profileEditHeading => 'Datos nutricionales';

  @override
  String get profileEditSubtitle =>
      'Actualiza tus datos para que NutriLife ajuste mejor tu plan.';

  @override
  String get profileEditAge => 'Edad';

  @override
  String get profileEditYearsUnit => 'años';

  @override
  String get profileEditHeight => 'Altura';

  @override
  String get profileEditWeight => 'Peso';

  @override
  String get profileEditSex => 'Sexo';

  @override
  String get profileEditGoal => 'Objetivo';

  @override
  String get profileEditAccountHeading => 'Cuenta';

  @override
  String get profileEditEmail => 'Email';

  @override
  String get profileEditEmailMissing => 'Correo no disponible';

  @override
  String get profileEditSaving => 'Guardando...';

  @override
  String get profileEditSave => 'Guardar cambios';

  @override
  String get profileEditSelectAll =>
      'Selecciona todos los datos para continuar.';

  @override
  String get profileEditHeightInvalid =>
      'Selecciona una altura válida entre 1.50 cm y 2.50 cm.';

  @override
  String get profileEditWeightDialogTitle => 'Vas a actualizar tu peso';

  @override
  String get profileEditWeightDialogBody =>
      'Este cambio puede afectar tus ajustes actuales, como tu meta calórica diaria y tu plan nutricional. NutriLife recalculará tus objetivos con el nuevo valor.';

  @override
  String get premiumSubtitle => 'Lleva tu alimentación al siguiente nivel';

  @override
  String get premiumBenefitChat => 'Chef IA sin límite de mensajes';

  @override
  String get premiumBenefitProgress => 'Historial de progreso completo';

  @override
  String get premiumBenefitPlans => 'Planes de comida semanales';

  @override
  String get premiumBenefitRecipes => 'Recetas guardadas sin límite';

  @override
  String get premiumPlanYearly => 'Anual';

  @override
  String get premiumPlanMonthly => 'Mensual';

  @override
  String premiumPricePerYear(String price) {
    return '$price / año';
  }

  @override
  String premiumPricePerMonth(String price) {
    return '$price / mes';
  }

  @override
  String get premiumSaveBadge => 'Ahorra 50%';

  @override
  String get premiumStartTrial => 'Empezar 7 días gratis';

  @override
  String get premiumRestore => 'Restaurar compras';

  @override
  String get premiumTerms => 'Términos';

  @override
  String get premiumPaymentsSoon => 'Los pagos llegan pronto';

  @override
  String get premiumPromoTitle => 'Desbloquea tu progreso completo';

  @override
  String legalLastUpdated(String date) {
    return 'Última actualización: $date';
  }

  @override
  String get hydrationKicker => 'HIDRATACIÓN';

  @override
  String get hydrationLoadErrorTap =>
      'No se pudo cargar. Toca para reintentar.';

  @override
  String get hydrationLoadingToday => 'Cargando avance de hoy...';

  @override
  String get hydrationDrinkWater => 'Beber agua';

  @override
  String hydrationGlassesTodayLine(int glasses, int goal, String status) {
    return '$glasses/$goal vasos hoy · $status';
  }

  @override
  String get hydrationTagline => 'Un pequeño hábito, un gran avance';

  @override
  String hydrationStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Racha $days días',
      one: 'Racha 1 día',
    );
    return '$_temp0';
  }

  @override
  String get hydrationScreenTitle => 'Racha de agua';

  @override
  String get hydrationLoadError => 'No pudimos cargar tu racha de agua.';

  @override
  String get hydrationTodayChallenge => 'Tu reto de hoy';

  @override
  String get hydrationChallengeDone => 'Reto completado';

  @override
  String get hydrationLogGlass => 'Registrar un vaso';

  @override
  String get hydrationUndoGlass => 'Deshacer último vaso';

  @override
  String hydrationSaveError(String error) {
    return 'No se pudo guardar el cambio: $error';
  }

  @override
  String hydrationRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Te faltan $remaining vasos para completar el reto.',
      one: 'Te falta 1 vaso para completar el reto.',
    );
    return '$_temp0';
  }

  @override
  String hydrationGoalNote(int goal) {
    return 'Meta del reto: $goal vasos al día. Ajusta tu hidratación a tus necesidades.';
  }

  @override
  String get hydrationCurrentStreakKicker => 'RACHA ACTUAL';

  @override
  String hydrationDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String hydrationBestStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mejor racha: $days días',
      one: 'Mejor racha: 1 día',
    );
    return '$_temp0';
  }

  @override
  String get hydrationDialogue0 => '¡Hola! ¿Me ayudas a llenar mi vasito hoy?';

  @override
  String get hydrationDialogue1 => '¡Gracias! Cada vasito cuenta.';

  @override
  String get hydrationDialogue2 => '¡Qué bien! Ya vamos avanzando juntos.';

  @override
  String get hydrationDialogue3 => '¡Vamos muy bien! Un poquito más.';

  @override
  String get hydrationDialogue4 => '¡Casi lo logramos! Un vasito más.';

  @override
  String get hydrationDialogueDone =>
      '¡Lo hicimos! Mañana seguimos cuidando el hábito.';

  @override
  String get hydrationCelebrationImage => 'Nutria celebrando con serpentinas';

  @override
  String get hydrationGoalReached => '¡Meta de agua cumplida!';

  @override
  String get hydrationCelebrationBody =>
      '¡La nutria está celebrando contigo! Cada día estás construyendo un gran hábito.';

  @override
  String get hydrationCelebrationOk => '¡Qué bien!';

  @override
  String get hydrationDrinkingOtter => 'Nutria tomando agua';

  @override
  String get hydrationStatsTitle => 'Tu hidratación';

  @override
  String get hydrationEveryGlassCounts => 'Cada vaso suma';

  @override
  String get hydrationGlassesLogged => 'Vasos registrados';

  @override
  String get hydrationScientistOtter => 'Nutria científica de NutriLife';

  @override
  String get hydrationStatCurrentStreak => 'racha actual';

  @override
  String get hydrationStatBestStreak => 'mejor racha';

  @override
  String get hydrationStatTotalGlasses => 'vasos totales';

  @override
  String get hydrationLast7Days => 'Últimos 7 días';

  @override
  String hydrationGoalsMet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metas cumplidas',
      one: '1 meta cumplida',
    );
    return '$_temp0';
  }

  @override
  String hydrationDisclaimer(int goal) {
    return 'Meta diaria: $goal vasos · Registro personal, no consejo médico.';
  }

  @override
  String get hydrationStatsLoadError =>
      'No se pudieron cargar tus estadísticas de agua.';

  @override
  String get hydrationWeekdayInitials => 'L,M,X,J,V,S,D';

  @override
  String get hydrationErrorInvalidHistory =>
      'El historial de hidratación no es válido.';

  @override
  String get hydrationErrorInvalidData =>
      'El historial de hidratación contiene datos no válidos.';

  @override
  String get hydrationErrorUpdate =>
      'No se pudo actualizar el historial de hidratación.';

  @override
  String get hydrationErrorSave =>
      'No se pudo guardar el historial de hidratación.';

  @override
  String get profileStreaksTitle => 'TUS RACHAS';

  @override
  String get profileStreaksCalorieGoal => 'Objetivo calórico';

  @override
  String get profileStreaksHydration => 'Hidratación';

  @override
  String profileStreaksCalorieError(String error) {
    return 'No pudimos cargar las calorías: $error';
  }

  @override
  String get profileStreaksNoWeekData =>
      'Aún no hay datos semanales para calcular esta racha.';

  @override
  String get profileStreaksCalorieNote =>
      'Racha calórica calculada con los últimos 7 días disponibles.';

  @override
  String profileStreaksDays(String value) {
    return '$value días';
  }

  @override
  String profileStreaksCurrentBest(String best) {
    return 'actual · mejor 7d $best';
  }

  @override
  String get profileStreaksLoadError => 'No se pudieron cargar tus rachas.';

  @override
  String get progressSectionCalories => 'CALORÍAS';

  @override
  String get progressSectionCaloriesSubtitle =>
      'Tu consumo frente a la meta diaria';

  @override
  String get progressWeekUnavailable =>
      'Aún no hay suficientes datos para mostrar la semana.';

  @override
  String get progressSectionHydrationSubtitle =>
      'Un hábito complementario, día a día';

  @override
  String get progressHydrationCardTitle => 'Vasos de agua · últimos 7 días';

  @override
  String chatQuotaRemaining(int remaining, int limit) {
    return '$remaining de $limit mensajes hoy';
  }

  @override
  String chatQuotaExhaustedTitle(int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Usaste tus $limit mensajes de hoy',
      one: 'Usaste tu mensaje de hoy',
    );
    return '$_temp0';
  }

  @override
  String get chatQuotaExhaustedGeneric => 'Usaste tus mensajes de hoy';

  @override
  String get chatQuotaFairUseTitle => 'Llegaste al límite de uso justo de hoy';

  @override
  String chatQuotaResetsAt(String time) {
    return 'Se reinician a las $time';
  }

  @override
  String get chatQuotaGoPremium => 'Hazte Premium';

  @override
  String get chatQuotaReply =>
      'Por hoy ya usaste tus mensajes conmigo. Vuelve mañana o hazte Premium para seguir cocinando juntos.';

  @override
  String get chatQuotaFairUseReply =>
      'Hoy hablamos muchísimo. Descansemos y seguimos mañana.';

  @override
  String profilePremiumActiveUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Activo hasta el $dateString';
  }

  @override
  String get profilePremiumActiveForever => 'Activo sin vencimiento';
}
