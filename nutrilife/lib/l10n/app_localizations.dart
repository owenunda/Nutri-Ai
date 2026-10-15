import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'NutriLife'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La conexión con el servidor tardó demasiado. Inténtalo de nuevo.'**
  String get commonErrorTimeout;

  /// No description provided for @commonErrorConnection.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servidor. Revisa tu conexión a internet.'**
  String get commonErrorConnection;

  /// No description provided for @profileLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Usar el del teléfono'**
  String get profileLanguageSystem;

  /// No description provided for @profileLanguageSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma'**
  String get profileLanguageSheetTitle;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @authBrandTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu camino inteligente hacia el bienestar.'**
  String get authBrandTagline;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus credenciales para acceder a tu espacio de bienestar.'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'CORREO ELECTRONICO'**
  String get authLoginEmailLabel;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'CONTRASENA'**
  String get authLoginPasswordLabel;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPasswordLink;

  /// No description provided for @authPasswordUpdatedSignIn.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Ya puedes iniciar sesión.'**
  String get authPasswordUpdatedSignIn;

  /// No description provided for @authLoginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesion'**
  String get authLoginButton;

  /// No description provided for @authLoginLoading.
  ///
  /// In es, this message translates to:
  /// **'Iniciando...'**
  String get authLoginLoading;

  /// No description provided for @authLoginOrContinueWith.
  ///
  /// In es, this message translates to:
  /// **'O CONTINUA CON'**
  String get authLoginOrContinueWith;

  /// No description provided for @authGoogleTermsPrefix.
  ///
  /// In es, this message translates to:
  /// **'Al continuar con Google aceptas los '**
  String get authGoogleTermsPrefix;

  /// No description provided for @authTermsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos del Servicio'**
  String get authTermsOfService;

  /// No description provided for @authTermsAnd.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get authTermsAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get authPrivacyPolicy;

  /// No description provided for @authLoginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'No tienes una cuenta? '**
  String get authLoginNoAccount;

  /// No description provided for @authLoginCreateOne.
  ///
  /// In es, this message translates to:
  /// **'Crea una'**
  String get authLoginCreateOne;

  /// No description provided for @authLoginSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión exitoso.'**
  String get authLoginSuccess;

  /// No description provided for @authErrorLogin.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Inténtalo de nuevo.'**
  String get authErrorLogin;

  /// No description provided for @authErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de red: {details}'**
  String authErrorNetwork(String details);

  /// No description provided for @authErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error: {details}'**
  String authErrorUnexpected(String details);

  /// No description provided for @authRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Comienza tu camino hacia una alimentación inteligente.'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterNameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE COMPLETO'**
  String get authRegisterNameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'CORREO ELECTRÓNICO'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'CONTRASEÑA'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR'**
  String get authConfirmLabel;

  /// No description provided for @authNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio.'**
  String get authNameRequired;

  /// No description provided for @authRegisterTermsPrefix.
  ///
  /// In es, this message translates to:
  /// **'Acepto los '**
  String get authRegisterTermsPrefix;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get authRegisterSubmit;

  /// No description provided for @authRegisterSubmitting.
  ///
  /// In es, this message translates to:
  /// **'Registrando...'**
  String get authRegisterSubmitting;

  /// No description provided for @authRegisterOrSignUpWith.
  ///
  /// In es, this message translates to:
  /// **'O REGÍSTRATE CON'**
  String get authRegisterOrSignUpWith;

  /// No description provided for @authRegisterHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get authRegisterHaveAccount;

  /// No description provided for @authRegisterSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authRegisterSignIn;

  /// No description provided for @authTermsRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar los términos del servicio y la política de privacidad.'**
  String get authTermsRequired;

  /// No description provided for @authRegisterSnackDuplicateTitle.
  ///
  /// In es, this message translates to:
  /// **'Correo ya registrado'**
  String get authRegisterSnackDuplicateTitle;

  /// No description provided for @authRegisterSnackWarningTitle.
  ///
  /// In es, this message translates to:
  /// **'Falta confirmar'**
  String get authRegisterSnackWarningTitle;

  /// No description provided for @authRegisterSnackErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro no completado'**
  String get authRegisterSnackErrorTitle;

  /// No description provided for @authEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es obligatorio.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordConfirmRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña.'**
  String get authPasswordConfirmRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get authPasswordMismatch;

  /// No description provided for @authForgotTitle.
  ///
  /// In es, this message translates to:
  /// **'Recupera tu contraseña'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo de tu cuenta y te enviaremos un código para crear una contraseña nueva.'**
  String get authForgotSubtitle;

  /// No description provided for @authForgotSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get authForgotSend;

  /// No description provided for @authForgotSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get authForgotSending;

  /// No description provided for @authResetTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Si {email} tiene una cuenta, te enviamos un código de 6 dígitos. Escríbelo y elige tu contraseña nueva.'**
  String authResetSubtitle(String email);

  /// No description provided for @authCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'CÓDIGO'**
  String get authCodeLabel;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'CONTRASEÑA NUEVA'**
  String get authNewPasswordLabel;

  /// No description provided for @authSavePassword.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña'**
  String get authSavePassword;

  /// No description provided for @authSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get authSaving;

  /// No description provided for @authCodeResent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un código nuevo.'**
  String get authCodeResent;

  /// No description provided for @authSetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu contraseña'**
  String get authSetPasswordTitle;

  /// No description provided for @authSetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¡Ya estás dentro! Si quieres, crea una contraseña para entrar también con tu correo cuando no tengas Google a mano.'**
  String get authSetPasswordSubtitle;

  /// No description provided for @authSetPasswordSkip.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get authSetPasswordSkip;

  /// No description provided for @authVerifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo'**
  String get authVerifyTitle;

  /// No description provided for @authVerifySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un código de 6 dígitos a {email}. Escríbelo aquí para activar tu cuenta.'**
  String authVerifySubtitle(String email);

  /// No description provided for @authVerifyButton.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get authVerifyButton;

  /// No description provided for @authVerifying.
  ///
  /// In es, this message translates to:
  /// **'Verificando...'**
  String get authVerifying;

  /// No description provided for @authCodeInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe los 6 dígitos del código.'**
  String get authCodeInvalid;

  /// No description provided for @authResendCode.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get authResendCode;

  /// No description provided for @authResendCodeIn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código en {seconds} s'**
  String authResendCodeIn(int seconds);

  /// No description provided for @authLinkTitle.
  ///
  /// In es, this message translates to:
  /// **'Vincula tu cuenta'**
  String get authLinkTitle;

  /// No description provided for @authLinkSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una cuenta de NutriLife con este correo. Escribe tu contraseña para vincularla con Google; después podrás entrar de las dos formas.'**
  String get authLinkSubtitle;

  /// No description provided for @authLinkPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get authLinkPasswordRequired;

  /// No description provided for @authLinkButton.
  ///
  /// In es, this message translates to:
  /// **'Vincular'**
  String get authLinkButton;

  /// No description provided for @authLinking.
  ///
  /// In es, this message translates to:
  /// **'Vinculando...'**
  String get authLinking;

  /// No description provided for @authLinkPasswordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Escríbela para vincular tu cuenta.'**
  String get authLinkPasswordUpdated;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authLoginSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciaste sesión con éxito'**
  String get authLoginSuccessTitle;

  /// No description provided for @authLoginSuccessBody.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo. Has ingresado correctamente a tu cuenta.'**
  String get authLoginSuccessBody;

  /// No description provided for @authOnboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'IA nutricional\npersonalizada'**
  String get authOnboardingTitle;

  /// No description provided for @authOnboardingBody.
  ///
  /// In es, this message translates to:
  /// **'Tu asistente nutricional inteligente te ayuda a mejorar tu alimentación según tus objetivos.'**
  String get authOnboardingBody;

  /// No description provided for @authDiscoverTitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre Alimentos'**
  String get authDiscoverTitle;

  /// No description provided for @authDiscoverBody.
  ///
  /// In es, this message translates to:
  /// **'Busca tus alimentos favoritos en la barra de búsqueda. Nuestra IA reconoce miles de ingredientes.'**
  String get authDiscoverBody;

  /// No description provided for @authAnalyzeTitle.
  ///
  /// In es, this message translates to:
  /// **'Analiza tu Progreso'**
  String get authAnalyzeTitle;

  /// No description provided for @authAnalyzeBody.
  ///
  /// In es, this message translates to:
  /// **'Mantente motivado con información detallada sobre tus hábitos. Revisa tus tendencias y celebra cada logro en tu camino.'**
  String get authAnalyzeBody;

  /// No description provided for @authAnalyzeGoalReached.
  ///
  /// In es, this message translates to:
  /// **'META CUMPLIDA'**
  String get authAnalyzeGoalReached;

  /// No description provided for @authFlowNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente paso'**
  String get authFlowNext;

  /// No description provided for @authFlowStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get authFlowStart;

  /// No description provided for @authFlowSkip.
  ///
  /// In es, this message translates to:
  /// **'SALTAR'**
  String get authFlowSkip;

  /// No description provided for @authFlowReviewTerms.
  ///
  /// In es, this message translates to:
  /// **'REVISAR TÉRMINOS'**
  String get authFlowReviewTerms;

  /// No description provided for @authErrorRegister.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el registro. Inténtalo de nuevo.'**
  String get authErrorRegister;

  /// No description provided for @authErrorVerifyEmail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu correo. Inténtalo de nuevo.'**
  String get authErrorVerifyEmail;

  /// No description provided for @authErrorResendCode.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reenviar el código. Inténtalo de nuevo.'**
  String get authErrorResendCode;

  /// No description provided for @authErrorSendCode.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el código. Inténtalo de nuevo.'**
  String get authErrorSendCode;

  /// No description provided for @authErrorResetPassword.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar tu contraseña. Inténtalo de nuevo.'**
  String get authErrorResetPassword;

  /// No description provided for @authErrorSetPassword.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu contraseña. Inténtalo de nuevo.'**
  String get authErrorSetPassword;

  /// No description provided for @authErrorGoogle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google. Inténtalo de nuevo.'**
  String get authErrorGoogle;

  /// No description provided for @authErrorGoogleNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con Google no está configurado.'**
  String get authErrorGoogleNotConfigured;

  /// No description provided for @authErrorGoogleNoData.
  ///
  /// In es, this message translates to:
  /// **'Google no devolvió tus datos. Inténtalo de nuevo.'**
  String get authErrorGoogleNoData;

  /// No description provided for @commonUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get commonUser;

  /// No description provided for @setupProgressLabel.
  ///
  /// In es, this message translates to:
  /// **'PROGRESO DE REGISTRO'**
  String get setupProgressLabel;

  /// No description provided for @setupSaveErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar'**
  String get setupSaveErrorTitle;

  /// No description provided for @setupGoalHeading.
  ///
  /// In es, this message translates to:
  /// **'Define tu objetivo'**
  String get setupGoalHeading;

  /// No description provided for @setupGoalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Calcularemos tu plan según lo que\nquieras lograr.'**
  String get setupGoalSubtitle;

  /// No description provided for @setupGoalLoseTitle.
  ///
  /// In es, this message translates to:
  /// **'Bajar de peso'**
  String get setupGoalLoseTitle;

  /// No description provided for @setupGoalLoseSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Déficit calórico saludable'**
  String get setupGoalLoseSubtitle;

  /// No description provided for @setupGoalMaintainTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantener peso'**
  String get setupGoalMaintainTitle;

  /// No description provided for @setupGoalMaintainSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estabilidad y nutrición diaria'**
  String get setupGoalMaintainSubtitle;

  /// No description provided for @setupGoalGainTitle.
  ///
  /// In es, this message translates to:
  /// **'Subir de peso'**
  String get setupGoalGainTitle;

  /// No description provided for @setupGoalGainSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Superávit para masa muscular'**
  String get setupGoalGainSubtitle;

  /// No description provided for @setupGoalPlanBadge.
  ///
  /// In es, this message translates to:
  /// **'PLAN PERSONALIZADO'**
  String get setupGoalPlanBadge;

  /// No description provided for @setupGoalCaloriesLabel.
  ///
  /// In es, this message translates to:
  /// **'CALORÍAS DIARIAS RECOMENDADAS'**
  String get setupGoalCaloriesLabel;

  /// No description provided for @setupGoalCaloriesNote.
  ///
  /// In es, this message translates to:
  /// **'Basado en tu metabolismo basal y\nnivel de actividad actual.'**
  String get setupGoalCaloriesNote;

  /// No description provided for @setupGoalSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando meta...'**
  String get setupGoalSaving;

  /// No description provided for @setupGoalStart.
  ///
  /// In es, this message translates to:
  /// **'Empieza tu meta'**
  String get setupGoalStart;

  /// No description provided for @setupGoalSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu meta. Inténtalo de nuevo.'**
  String get setupGoalSaveError;

  /// No description provided for @setupProfileHeading.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get setupProfileHeading;

  /// No description provided for @setupProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estos datos nos ayudan a personalizar tu\nplan nutricional.'**
  String get setupProfileSubtitle;

  /// No description provided for @setupAgeLabel.
  ///
  /// In es, this message translates to:
  /// **'EDAD'**
  String get setupAgeLabel;

  /// No description provided for @setupWeightLabel.
  ///
  /// In es, this message translates to:
  /// **'PESO (KG)'**
  String get setupWeightLabel;

  /// No description provided for @setupHeightLabel.
  ///
  /// In es, this message translates to:
  /// **'ALTURA (CM)'**
  String get setupHeightLabel;

  /// No description provided for @setupSexLabel.
  ///
  /// In es, this message translates to:
  /// **'SEXO'**
  String get setupSexLabel;

  /// No description provided for @setupSexMale.
  ///
  /// In es, this message translates to:
  /// **'Hombre'**
  String get setupSexMale;

  /// No description provided for @setupSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Mujer'**
  String get setupSexFemale;

  /// No description provided for @setupUnitYears.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get setupUnitYears;

  /// No description provided for @setupPrecisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Precisión NutriLife'**
  String get setupPrecisionTitle;

  /// No description provided for @setupPrecisionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu metabolismo basal se calculará\nautomáticamente.'**
  String get setupPrecisionBody;

  /// No description provided for @setupProfileSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get setupProfileSaving;

  /// No description provided for @setupProfileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get setupProfileSave;

  /// No description provided for @setupAgeRequired.
  ///
  /// In es, this message translates to:
  /// **'La edad es obligatoria.'**
  String get setupAgeRequired;

  /// No description provided for @setupAgeInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una edad válida.'**
  String get setupAgeInvalid;

  /// No description provided for @setupAgeTooYoung.
  ///
  /// In es, this message translates to:
  /// **'Debes tener al menos 16 años.'**
  String get setupAgeTooYoung;

  /// No description provided for @setupWeightRequired.
  ///
  /// In es, this message translates to:
  /// **'El peso es obligatorio.'**
  String get setupWeightRequired;

  /// No description provided for @setupWeightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un peso válido.'**
  String get setupWeightInvalid;

  /// No description provided for @setupWeightOutOfRange.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un peso válido.'**
  String get setupWeightOutOfRange;

  /// No description provided for @setupHeightRequired.
  ///
  /// In es, this message translates to:
  /// **'La altura es obligatoria.'**
  String get setupHeightRequired;

  /// No description provided for @setupHeightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una altura válida.'**
  String get setupHeightInvalid;

  /// No description provided for @setupHeightOutOfRange.
  ///
  /// In es, this message translates to:
  /// **'La altura debe estar entre 1.50 cm y 2.50 cm.'**
  String get setupHeightOutOfRange;

  /// No description provided for @setupSexRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu sexo para continuar.'**
  String get setupSexRequired;

  /// No description provided for @setupSnackMissingTitle.
  ///
  /// In es, this message translates to:
  /// **'Falta un dato'**
  String get setupSnackMissingTitle;

  /// No description provided for @setupProfileSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu perfil. Inténtalo de nuevo.'**
  String get setupProfileSaveError;

  /// No description provided for @setupErrorNothingToSave.
  ///
  /// In es, this message translates to:
  /// **'No hay datos para guardar.'**
  String get setupErrorNothingToSave;

  /// No description provided for @setupErrorSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la información. Inténtalo de nuevo.'**
  String get setupErrorSave;

  /// No description provided for @commonNavHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get commonNavHome;

  /// No description provided for @commonNavFoods.
  ///
  /// In es, this message translates to:
  /// **'Alimentos'**
  String get commonNavFoods;

  /// No description provided for @commonNavAi.
  ///
  /// In es, this message translates to:
  /// **'IA'**
  String get commonNavAi;

  /// No description provided for @commonNavProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get commonNavProgress;

  /// No description provided for @commonNavProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get commonNavProfile;

  /// No description provided for @homeSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN'**
  String get homeSummaryLabel;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeAiCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Pregúntale a la IA qué comer.'**
  String get homeAiCardTitle;

  /// No description provided for @homeAiCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ideas de comidas personalizadas según tus metas.'**
  String get homeAiCardSubtitle;

  /// No description provided for @homeAddToMeal.
  ///
  /// In es, this message translates to:
  /// **'Agregar a {meal}'**
  String homeAddToMeal(String meal);

  /// No description provided for @homeTodayMealsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comidas de hoy'**
  String get homeTodayMealsTitle;

  /// No description provided for @homeViewHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get homeViewHistory;

  /// No description provided for @homeTodayCaloriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Calorías de hoy'**
  String get homeTodayCaloriesTitle;

  /// No description provided for @homeTodayCaloriesTarget.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {kcal} kcal'**
  String homeTodayCaloriesTarget(String kcal);

  /// No description provided for @homeTodayCaloriesTotal.
  ///
  /// In es, this message translates to:
  /// **'Total consumido'**
  String get homeTodayCaloriesTotal;

  /// No description provided for @homeTodayCaloriesConsumed.
  ///
  /// In es, this message translates to:
  /// **'consumidas'**
  String get homeTodayCaloriesConsumed;

  /// No description provided for @homeGoalLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu objetivo diario...'**
  String get homeGoalLoading;

  /// No description provided for @homeGoalError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu objetivo diario.'**
  String get homeGoalError;

  /// No description provided for @homeGoalIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil para calcular tu objetivo diario.'**
  String get homeGoalIncomplete;

  /// No description provided for @homeGoalRemaining.
  ///
  /// In es, this message translates to:
  /// **'Te faltan {kcal} kcal para cumplir tu objetivo de hoy.'**
  String homeGoalRemaining(String kcal);

  /// No description provided for @homeGoalExceeded.
  ///
  /// In es, this message translates to:
  /// **'Te excediste por {kcal} kcal de tu objetivo diario.'**
  String homeGoalExceeded(String kcal);

  /// No description provided for @homeGoalReached.
  ///
  /// In es, this message translates to:
  /// **'¡Has alcanzado tu objetivo diario!'**
  String get homeGoalReached;

  /// No description provided for @mealsTypeBreakfast.
  ///
  /// In es, this message translates to:
  /// **'Desayuno'**
  String get mealsTypeBreakfast;

  /// No description provided for @mealsTypeLunch.
  ///
  /// In es, this message translates to:
  /// **'Almuerzo'**
  String get mealsTypeLunch;

  /// No description provided for @mealsTypeDinner.
  ///
  /// In es, this message translates to:
  /// **'Cena'**
  String get mealsTypeDinner;

  /// No description provided for @mealsTypeSnack.
  ///
  /// In es, this message translates to:
  /// **'Snack'**
  String get mealsTypeSnack;

  /// No description provided for @mealsNotLoggedYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no registrada'**
  String get mealsNotLoggedYet;

  /// No description provided for @mealsPortionsOne.
  ///
  /// In es, this message translates to:
  /// **'{amount} porción'**
  String mealsPortionsOne(String amount);

  /// No description provided for @mealsPortionsOther.
  ///
  /// In es, this message translates to:
  /// **'{amount} porciones'**
  String mealsPortionsOther(String amount);

  /// No description provided for @mealsErrorAddFood.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la comida'**
  String get mealsErrorAddFood;

  /// No description provided for @mealsErrorAddRecipe.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la receta'**
  String get mealsErrorAddRecipe;

  /// No description provided for @mealsErrorDeleteRecipe.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la receta'**
  String get mealsErrorDeleteRecipe;

  /// No description provided for @mealsErrorDeleteItem.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar'**
  String get mealsErrorDeleteItem;

  /// No description provided for @mealsErrorLoadDay.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus comidas'**
  String get mealsErrorLoadDay;

  /// No description provided for @mealsHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de comidas'**
  String get mealsHistoryTitle;

  /// No description provided for @mealsPickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get mealsPickDate;

  /// No description provided for @mealsPreviousDay.
  ///
  /// In es, this message translates to:
  /// **'Día anterior'**
  String get mealsPreviousDay;

  /// No description provided for @mealsNextDay.
  ///
  /// In es, this message translates to:
  /// **'Día siguiente'**
  String get mealsNextDay;

  /// No description provided for @mealsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get mealsToday;

  /// No description provided for @mealsYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get mealsYesterday;

  /// No description provided for @mealsDateLabel.
  ///
  /// In es, this message translates to:
  /// **'{weekday} {day} {month}'**
  String mealsDateLabel(String weekday, int day, String month);

  /// No description provided for @mealsAddedTo.
  ///
  /// In es, this message translates to:
  /// **'Agregado a {meal} · {kcal} kcal'**
  String mealsAddedTo(String meal, int kcal);

  /// No description provided for @mealsRegisteredIn.
  ///
  /// In es, this message translates to:
  /// **'Registrado en {meal} · {kcal} kcal'**
  String mealsRegisteredIn(String meal, int kcal);

  /// No description provided for @mealsUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get mealsUndo;

  /// No description provided for @mealsUndoFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo deshacer'**
  String get mealsUndoFailed;

  /// No description provided for @mealsKcalPerUnit.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal por {unit}'**
  String mealsKcalPerUnit(int kcal, String unit);

  /// No description provided for @mealsLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get mealsLess;

  /// No description provided for @mealsMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get mealsMore;

  /// No description provided for @mealsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'{meal} · {kcal} kcal'**
  String mealsDetailTitle(String meal, int kcal);

  /// No description provided for @mealsOtherFoods.
  ///
  /// In es, this message translates to:
  /// **'OTROS ALIMENTOS'**
  String get mealsOtherFoods;

  /// No description provided for @mealsDeleteRecipeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar receta?'**
  String get mealsDeleteRecipeTitle;

  /// No description provided for @mealsDeleteRecipeBody.
  ///
  /// In es, this message translates to:
  /// **'Se quitará \"{title}\" con {count, plural, =1{su ingrediente} other{sus {count} ingredientes}} de esta comida.'**
  String mealsDeleteRecipeBody(String title, int count);

  /// No description provided for @mealsDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get mealsDelete;

  /// No description provided for @mealsDeleteRecipe.
  ///
  /// In es, this message translates to:
  /// **'Borrar receta'**
  String get mealsDeleteRecipe;

  /// No description provided for @mealsViewRecipe.
  ///
  /// In es, this message translates to:
  /// **'Ver receta'**
  String get mealsViewRecipe;

  /// No description provided for @mealsDeleteItem.
  ///
  /// In es, this message translates to:
  /// **'Borrar {name}'**
  String mealsDeleteItem(String name);

  /// No description provided for @mealsRegisterNoIngredients.
  ///
  /// In es, this message translates to:
  /// **'Esta receta no trae ingredientes para registrar'**
  String get mealsRegisterNoIngredients;

  /// No description provided for @mealsRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar comida'**
  String get mealsRegisterTitle;

  /// No description provided for @mealsLessPortions.
  ///
  /// In es, this message translates to:
  /// **'Menos porciones'**
  String get mealsLessPortions;

  /// No description provided for @mealsMorePortions.
  ///
  /// In es, this message translates to:
  /// **'Más porciones'**
  String get mealsMorePortions;

  /// No description provided for @mealsCalculatingCalories.
  ///
  /// In es, this message translates to:
  /// **'Calculando calorías… · la receta rinde {servings}'**
  String mealsCalculatingCalories(int servings);

  /// No description provided for @mealsRecipeYield.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal · la receta rinde {servings}'**
  String mealsRecipeYield(int kcal, int servings);

  /// No description provided for @mealsLoadFoodsError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los alimentos de la receta. Intenta de nuevo.'**
  String get mealsLoadFoodsError;

  /// No description provided for @mealsRegisterIn.
  ///
  /// In es, this message translates to:
  /// **'Registrar en {meal}'**
  String mealsRegisterIn(String meal);

  /// No description provided for @nutritionAddFridgeTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar a mi nevera'**
  String get nutritionAddFridgeTitle;

  /// No description provided for @nutritionLogConsumedTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar consumido'**
  String get nutritionLogConsumedTitle;

  /// No description provided for @nutritionAddFridgeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo guardarás en tu nevera para que la IA pueda sugerirlo al chatear.'**
  String get nutritionAddFridgeSubtitle;

  /// No description provided for @nutritionLogConsumedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se registrará como consumido en la comida que elijas para que el conteo de calorías sea correcto.'**
  String get nutritionLogConsumedSubtitle;

  /// No description provided for @nutritionFoodNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del alimento'**
  String get nutritionFoodNameLabel;

  /// No description provided for @nutritionFoodNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Banana'**
  String get nutritionFoodNameHint;

  /// No description provided for @nutritionFoodNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un nombre'**
  String get nutritionFoodNameRequired;

  /// No description provided for @nutritionSimilarFoodExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un alimento parecido. Elige uno para usarlo:'**
  String get nutritionSimilarFoodExists;

  /// No description provided for @nutritionUseFood.
  ///
  /// In es, this message translates to:
  /// **'Usar {name}'**
  String nutritionUseFood(String name);

  /// No description provided for @nutritionChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get nutritionChange;

  /// No description provided for @nutritionCaloriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Calorías (Kcal)'**
  String get nutritionCaloriesLabel;

  /// No description provided for @nutritionCaloriesHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 105'**
  String get nutritionCaloriesHint;

  /// No description provided for @nutritionCaloriesRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa calorías'**
  String get nutritionCaloriesRequired;

  /// No description provided for @nutritionMustBePositive.
  ///
  /// In es, this message translates to:
  /// **'Debe ser > 0'**
  String get nutritionMustBePositive;

  /// No description provided for @nutritionPortionLabel.
  ///
  /// In es, this message translates to:
  /// **'Porción'**
  String get nutritionPortionLabel;

  /// No description provided for @nutritionAmountHaveLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad que tienes'**
  String get nutritionAmountHaveLabel;

  /// No description provided for @nutritionAmountConsumedLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad consumida'**
  String get nutritionAmountConsumedLabel;

  /// No description provided for @nutritionAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa cantidad'**
  String get nutritionAmountRequired;

  /// No description provided for @nutritionAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get nutritionAmountLabel;

  /// No description provided for @nutritionUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get nutritionUnitLabel;

  /// No description provided for @nutritionMealOfDay.
  ///
  /// In es, this message translates to:
  /// **'Comida del día'**
  String get nutritionMealOfDay;

  /// No description provided for @nutritionSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get nutritionSaving;

  /// No description provided for @nutritionSaveInFridge.
  ///
  /// In es, this message translates to:
  /// **'Guardar en nevera'**
  String get nutritionSaveInFridge;

  /// No description provided for @nutritionSaveInMyFridge.
  ///
  /// In es, this message translates to:
  /// **'Guardar en mi nevera'**
  String get nutritionSaveInMyFridge;

  /// No description provided for @nutritionLogConsumption.
  ///
  /// In es, this message translates to:
  /// **'Registrar consumo'**
  String get nutritionLogConsumption;

  /// No description provided for @nutritionGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get nutritionGenericError;

  /// No description provided for @nutritionErrorNoFoodId.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el identificador del alimento. Inténtalo de nuevo.'**
  String get nutritionErrorNoFoodId;

  /// No description provided for @nutritionErrorRegisterFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el registro. Inténtalo de nuevo.'**
  String get nutritionErrorRegisterFailed;

  /// No description provided for @nutritionDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Listo!'**
  String get nutritionDoneTitle;

  /// No description provided for @nutritionDoneFridge.
  ///
  /// In es, this message translates to:
  /// **'Tu alimento ya está en la nevera.'**
  String get nutritionDoneFridge;

  /// No description provided for @nutritionDoneConsumed.
  ///
  /// In es, this message translates to:
  /// **'Tu consumo quedó registrado.'**
  String get nutritionDoneConsumed;

  /// No description provided for @nutritionAddAnotherFridge.
  ///
  /// In es, this message translates to:
  /// **'Agregar otro a mi nevera'**
  String get nutritionAddAnotherFridge;

  /// No description provided for @nutritionLogAnother.
  ///
  /// In es, this message translates to:
  /// **'Registrar otro consumo'**
  String get nutritionLogAnother;

  /// No description provided for @nutritionDoneButton.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get nutritionDoneButton;

  /// No description provided for @nutritionFridgeTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi nevera'**
  String get nutritionFridgeTitle;

  /// No description provided for @nutritionFridgeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que tienes en casa. La IA lo sugiere primero cuando lo adjuntas al chat.'**
  String get nutritionFridgeSubtitle;

  /// No description provided for @nutritionHowItWorks.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona?'**
  String get nutritionHowItWorks;

  /// No description provided for @nutritionCommonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunes'**
  String get nutritionCommonTitle;

  /// No description provided for @nutritionManualEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrada manual'**
  String get nutritionManualEntryTitle;

  /// No description provided for @nutritionHelpFridgeBody.
  ///
  /// In es, this message translates to:
  /// **'Alimentos que tienes guardados. Al adjuntarlos al chat, la IA los prioriza.'**
  String get nutritionHelpFridgeBody;

  /// No description provided for @nutritionHelpCommonBody.
  ///
  /// In es, this message translates to:
  /// **'Catálogo general de NutriLife para cuando no encuentras lo que buscas.'**
  String get nutritionHelpCommonBody;

  /// No description provided for @nutritionHelpManualBody.
  ///
  /// In es, this message translates to:
  /// **'Elige entre \"lo tengo\" (a tu nevera) o \"lo consumí\" (alimento registrado, sin guardar).'**
  String get nutritionHelpManualBody;

  /// No description provided for @nutritionGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get nutritionGotIt;

  /// No description provided for @nutritionCustomTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar personalizado'**
  String get nutritionCustomTitle;

  /// No description provided for @nutritionCustomBody.
  ///
  /// In es, this message translates to:
  /// **'¿No encuentras tu alimento? Agrégalo y elige si lo tienes en casa o solo lo registraste.'**
  String get nutritionCustomBody;

  /// No description provided for @nutritionToFridge.
  ///
  /// In es, this message translates to:
  /// **'A mi nevera'**
  String get nutritionToFridge;

  /// No description provided for @nutritionIAteIt.
  ///
  /// In es, this message translates to:
  /// **'Lo consumí'**
  String get nutritionIAteIt;

  /// No description provided for @nutritionSavedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que tienes guardado'**
  String get nutritionSavedSubtitle;

  /// No description provided for @nutritionCatalogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de NutriLife'**
  String get nutritionCatalogSubtitle;

  /// No description provided for @nutritionSeeAllItems.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get nutritionSeeAllItems;

  /// No description provided for @nutritionSeeAllFoods.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get nutritionSeeAllFoods;

  /// No description provided for @nutritionSeeLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get nutritionSeeLess;

  /// No description provided for @nutritionResultsCount.
  ///
  /// In es, this message translates to:
  /// **'Resultados ({count})'**
  String nutritionResultsCount(int count);

  /// No description provided for @nutritionTip.
  ///
  /// In es, this message translates to:
  /// **'Tip: agregar primero lo que tienes en tu nevera (no lo que comiste fuera) ayuda a la IA a sugerirte recetas con lo que ya está en casa.'**
  String get nutritionTip;

  /// No description provided for @nutritionNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos \"{query}\". Prueba con otro nombre o agrégalo desde \"Entrada manual\".'**
  String nutritionNoResults(String query);

  /// No description provided for @nutritionNoCommonFoods.
  ///
  /// In es, this message translates to:
  /// **'No hay alimentos comunes cargados.'**
  String get nutritionNoCommonFoods;

  /// No description provided for @nutritionFoodAddedToFridge.
  ///
  /// In es, this message translates to:
  /// **'{food} agregado a tu nevera'**
  String nutritionFoodAddedToFridge(String food);

  /// No description provided for @nutritionFoodLoggedIn.
  ///
  /// In es, this message translates to:
  /// **'{food} registrado en {meal}'**
  String nutritionFoodLoggedIn(String food, String meal);

  /// No description provided for @nutritionErrorAdd.
  ///
  /// In es, this message translates to:
  /// **'No se pudo agregar'**
  String get nutritionErrorAdd;

  /// No description provided for @nutritionErrorLog.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar'**
  String get nutritionErrorLog;

  /// No description provided for @nutritionBulkResult.
  ///
  /// In es, this message translates to:
  /// **'{ok}/{total} procesados correctamente.'**
  String nutritionBulkResult(int ok, int total);

  /// No description provided for @nutritionBulkResultWithFailed.
  ///
  /// In es, this message translates to:
  /// **'{ok}/{total} procesados correctamente. Fallaron: {names}'**
  String nutritionBulkResultWithFailed(int ok, int total, String names);

  /// No description provided for @nutritionAskMealTitle.
  ///
  /// In es, this message translates to:
  /// **'¿En qué comida?'**
  String get nutritionAskMealTitle;

  /// No description provided for @nutritionAskMealBody.
  ///
  /// In es, this message translates to:
  /// **'Se registrará como consumido en la comida seleccionada para todos los alimentos marcados.'**
  String get nutritionAskMealBody;

  /// No description provided for @nutritionActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get nutritionActions;

  /// No description provided for @nutritionClearSelection.
  ///
  /// In es, this message translates to:
  /// **'Quitar selección'**
  String get nutritionClearSelection;

  /// No description provided for @nutritionSelectedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 alimento seleccionado} other{{count} alimentos seleccionados}}'**
  String nutritionSelectedCount(int count);

  /// No description provided for @nutritionEmptyFridgeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nevera está vacía'**
  String get nutritionEmptyFridgeTitle;

  /// No description provided for @nutritionEmptyFridgeBody.
  ///
  /// In es, this message translates to:
  /// **'Agrega lo que tienes en casa desde \"Entrada manual\" para que la IA pueda sugerírtelo en el chat.'**
  String get nutritionEmptyFridgeBody;

  /// No description provided for @nutritionAllFoodsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todos los alimentos'**
  String get nutritionAllFoodsTitle;

  /// No description provided for @nutritionItemsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 ítem} other{{count} ítems}}'**
  String nutritionItemsCount(int count);

  /// No description provided for @nutritionFoodsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 alimento} other{{count} alimentos}}'**
  String nutritionFoodsCount(int count);

  /// No description provided for @nutritionFridgeEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Tu nevera está vacía. Agrega alimentos desde \"Entrada manual\" o desde la pestaña Comunes.'**
  String get nutritionFridgeEmptyAll;

  /// No description provided for @nutritionEditAmount.
  ///
  /// In es, this message translates to:
  /// **'Editar cantidad de {name}'**
  String nutritionEditAmount(String name);

  /// No description provided for @nutritionFridgeItemRemoved.
  ///
  /// In es, this message translates to:
  /// **'{name} se quitó de tu nevera'**
  String nutritionFridgeItemRemoved(String name);

  /// No description provided for @nutritionFridgeAmountUpdated.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de {name} actualizada'**
  String nutritionFridgeAmountUpdated(String name);

  /// No description provided for @nutritionRemoveFoodTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar alimento'**
  String get nutritionRemoveFoodTitle;

  /// No description provided for @nutritionRemoveFoodBody.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres quitar {name} de tu nevera? Ya no aparecerá entre tus alimentos disponibles.'**
  String nutritionRemoveFoodBody(String name);

  /// No description provided for @nutritionRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get nutritionRemove;

  /// No description provided for @nutritionAmountGreaterThanZero.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una cantidad mayor que 0'**
  String get nutritionAmountGreaterThanZero;

  /// No description provided for @nutritionCantSubtractMore.
  ///
  /// In es, this message translates to:
  /// **'No puedes descontar más de lo que tienes ({quantity}).'**
  String nutritionCantSubtractMore(String quantity);

  /// No description provided for @nutritionAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible: {amount}'**
  String nutritionAvailable(String amount);

  /// No description provided for @nutritionAdjustLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad para sumar o descontar ({unit})'**
  String nutritionAdjustLabel(String unit);

  /// No description provided for @nutritionNewTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad total nueva ({unit})'**
  String nutritionNewTotalLabel(String unit);

  /// No description provided for @nutritionSubtract.
  ///
  /// In es, this message translates to:
  /// **'Descontar'**
  String get nutritionSubtract;

  /// No description provided for @nutritionIncrease.
  ///
  /// In es, this message translates to:
  /// **'Aumentar'**
  String get nutritionIncrease;

  /// No description provided for @nutritionSaveExactAmount.
  ///
  /// In es, this message translates to:
  /// **'Guardar cantidad exacta'**
  String get nutritionSaveExactAmount;

  /// No description provided for @nutritionRemoveFromFridge.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la nevera'**
  String get nutritionRemoveFromFridge;

  /// No description provided for @nutritionSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Busca más de 100,000 alimentos...'**
  String get nutritionSearchHint;

  /// No description provided for @nutritionClearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get nutritionClearSearch;

  /// No description provided for @nutritionUnitOne.
  ///
  /// In es, this message translates to:
  /// **'1 unidad'**
  String get nutritionUnitOne;

  /// No description provided for @nutritionUnitServing.
  ///
  /// In es, this message translates to:
  /// **'1 porción'**
  String get nutritionUnitServing;

  /// No description provided for @nutritionUnitCup.
  ///
  /// In es, this message translates to:
  /// **'1 taza'**
  String get nutritionUnitCup;

  /// No description provided for @nutritionUnitTablespoon.
  ///
  /// In es, this message translates to:
  /// **'1 cucharada'**
  String get nutritionUnitTablespoon;

  /// No description provided for @nutritionUnitSlice.
  ///
  /// In es, this message translates to:
  /// **'1 rebanada'**
  String get nutritionUnitSlice;

  /// No description provided for @nutritionCountUnit.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 unidad} other{{amount} unidades}}'**
  String nutritionCountUnit(num count, String amount);

  /// No description provided for @nutritionCountServing.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 porción} other{{amount} porciones}}'**
  String nutritionCountServing(num count, String amount);

  /// No description provided for @nutritionCountCup.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 taza} other{{amount} tazas}}'**
  String nutritionCountCup(num count, String amount);

  /// No description provided for @nutritionCountTablespoon.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cucharada} other{{amount} cucharadas}}'**
  String nutritionCountTablespoon(num count, String amount);

  /// No description provided for @nutritionCountSlice.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 rebanada} other{{amount} rebanadas}}'**
  String nutritionCountSlice(num count, String amount);

  /// No description provided for @nutritionErrorServerConnection.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión con el servidor'**
  String get nutritionErrorServerConnection;

  /// No description provided for @nutritionErrorLoadFoods.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener alimentos'**
  String get nutritionErrorLoadFoods;

  /// No description provided for @nutritionErrorUnexpectedLoadFoods.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado al obtener los alimentos: {error}'**
  String nutritionErrorUnexpectedLoadFoods(String error);

  /// No description provided for @nutritionErrorRegisterFood.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar el alimento'**
  String get nutritionErrorRegisterFood;

  /// No description provided for @nutritionErrorRegisterFoodServer.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar el alimento en el servidor'**
  String get nutritionErrorRegisterFoodServer;

  /// No description provided for @nutritionErrorUnexpectedRegisterFood.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado al registrar el alimento: {error}'**
  String nutritionErrorUnexpectedRegisterFood(String error);

  /// No description provided for @nutritionErrorLoadFridge.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener la nevera'**
  String get nutritionErrorLoadFridge;

  /// No description provided for @nutritionErrorUnexpectedLoadFridge.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado al obtener la nevera: {error}'**
  String nutritionErrorUnexpectedLoadFridge(String error);

  /// No description provided for @nutritionErrorAddToFridge.
  ///
  /// In es, this message translates to:
  /// **'No se pudo agregar a la nevera'**
  String get nutritionErrorAddToFridge;

  /// No description provided for @nutritionErrorAddToFridgeDetail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo agregar a la nevera: {error}'**
  String nutritionErrorAddToFridgeDetail(String error);

  /// No description provided for @nutritionErrorUpdateAmount.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la cantidad'**
  String get nutritionErrorUpdateAmount;

  /// No description provided for @nutritionErrorUpdateAmountDetail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la cantidad: {error}'**
  String nutritionErrorUpdateAmountDetail(String error);

  /// No description provided for @nutritionErrorRemoveFromFridge.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar de la nevera'**
  String get nutritionErrorRemoveFromFridge;

  /// No description provided for @nutritionErrorRemoveFromFridgeDetail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar de la nevera: {error}'**
  String nutritionErrorRemoveFromFridgeDetail(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
