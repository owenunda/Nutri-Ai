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
