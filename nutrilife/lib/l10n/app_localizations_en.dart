// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NutriLife';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonClose => 'Close';

  @override
  String get commonErrorTimeout =>
      'The server took too long to respond. Please try again.';

  @override
  String get commonErrorConnection =>
      'We couldn\'t reach the server. Check your internet connection.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageSystem => 'Use phone language';

  @override
  String get profileLanguageSheetTitle => 'Choose a language';

  @override
  String get commonBack => 'Back';

  @override
  String get authBrandTagline => 'Your smart path to well-being.';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle =>
      'Enter your credentials to get into your well-being space.';

  @override
  String get authLoginEmailLabel => 'EMAIL';

  @override
  String get authLoginPasswordLabel => 'PASSWORD';

  @override
  String get authForgotPasswordLink => 'Forgot your password?';

  @override
  String get authPasswordUpdatedSignIn =>
      'Password updated. You can sign in now.';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authLoginLoading => 'Signing in...';

  @override
  String get authLoginOrContinueWith => 'OR CONTINUE WITH';

  @override
  String get authGoogleTermsPrefix =>
      'By continuing with Google, you accept the ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authTermsAnd => ' and the ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authLoginNoAccount => 'Don\'t have an account? ';

  @override
  String get authLoginCreateOne => 'Create one';

  @override
  String get authLoginSuccess => 'Login successful.';

  @override
  String get authErrorLogin => 'We couldn\'t sign you in. Please try again.';

  @override
  String authErrorNetwork(String details) {
    return 'Network error: $details';
  }

  @override
  String authErrorUnexpected(String details) {
    return 'Error: $details';
  }

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle =>
      'Start your journey toward smarter eating.';

  @override
  String get authRegisterNameLabel => 'FULL NAME';

  @override
  String get authEmailLabel => 'EMAIL';

  @override
  String get authPasswordLabel => 'PASSWORD';

  @override
  String get authConfirmLabel => 'CONFIRM';

  @override
  String get authNameRequired => 'Name is required.';

  @override
  String get authRegisterTermsPrefix => 'I accept the ';

  @override
  String get authRegisterSubmit => 'Sign up';

  @override
  String get authRegisterSubmitting => 'Signing up...';

  @override
  String get authRegisterOrSignUpWith => 'OR SIGN UP WITH';

  @override
  String get authRegisterHaveAccount => 'Already have an account?';

  @override
  String get authRegisterSignIn => 'Sign in';

  @override
  String get authTermsRequired =>
      'You need to accept the terms of service and the privacy policy.';

  @override
  String get authRegisterSnackDuplicateTitle => 'Email already registered';

  @override
  String get authRegisterSnackWarningTitle => 'Confirmation needed';

  @override
  String get authRegisterSnackErrorTitle => 'Sign-up not completed';

  @override
  String get authEmailRequired => 'Email is required.';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordRequired => 'Password is required.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authPasswordConfirmRequired => 'Confirm your password.';

  @override
  String get authPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get authForgotTitle => 'Recover your password';

  @override
  String get authForgotSubtitle =>
      'Enter your account email and we\'ll send you a code to create a new password.';

  @override
  String get authForgotSend => 'Send code';

  @override
  String get authForgotSending => 'Sending...';

  @override
  String get authResetTitle => 'New password';

  @override
  String authResetSubtitle(String email) {
    return 'If $email has an account, we sent a 6-digit code. Enter it and choose your new password.';
  }

  @override
  String get authCodeLabel => 'CODE';

  @override
  String get authNewPasswordLabel => 'NEW PASSWORD';

  @override
  String get authSavePassword => 'Save password';

  @override
  String get authSaving => 'Saving...';

  @override
  String get authCodeResent => 'We\'ve sent you a new code.';

  @override
  String get authSetPasswordTitle => 'Create your password';

  @override
  String get authSetPasswordSubtitle =>
      'You\'re in! If you like, create a password so you can also sign in with your email when Google isn\'t handy.';

  @override
  String get authSetPasswordSkip => 'Not now';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String authVerifySubtitle(String email) {
    return 'We sent a 6-digit code to $email. Enter it here to activate your account.';
  }

  @override
  String get authVerifyButton => 'Verify';

  @override
  String get authVerifying => 'Verifying...';

  @override
  String get authCodeInvalid => 'Enter the 6-digit code.';

  @override
  String get authResendCode => 'Resend code';

  @override
  String authResendCodeIn(int seconds) {
    return 'Resend code in $seconds s';
  }

  @override
  String get authLinkTitle => 'Link your account';

  @override
  String get authLinkSubtitle =>
      'You already have a NutriLife account with this email. Enter your password to link it with Google; after that you\'ll be able to sign in either way.';

  @override
  String get authLinkPasswordRequired => 'Enter your password.';

  @override
  String get authLinkButton => 'Link';

  @override
  String get authLinking => 'Linking...';

  @override
  String get authLinkPasswordUpdated =>
      'Password updated. Enter it to link your account.';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authLoginSuccessTitle => 'You signed in successfully';

  @override
  String get authLoginSuccessBody =>
      'Welcome back. You\'re now signed in to your account.';

  @override
  String get authOnboardingTitle => 'Personalized\nnutrition AI';

  @override
  String get authOnboardingBody =>
      'Your smart nutrition assistant helps you eat better, based on your goals.';

  @override
  String get authDiscoverTitle => 'Discover Foods';

  @override
  String get authDiscoverBody =>
      'Look up your favorite foods in the search bar. Our AI recognizes thousands of ingredients.';

  @override
  String get authAnalyzeTitle => 'Track Your Progress';

  @override
  String get authAnalyzeBody =>
      'Stay motivated with detailed insights into your habits. Review your trends and celebrate every win along the way.';

  @override
  String get authAnalyzeGoalReached => 'GOAL REACHED';

  @override
  String get authFlowNext => 'Next step';

  @override
  String get authFlowStart => 'Let\'s go';

  @override
  String get authFlowSkip => 'SKIP';

  @override
  String get authFlowReviewTerms => 'REVIEW TERMS';

  @override
  String get authErrorRegister =>
      'We couldn\'t complete your sign-up. Please try again.';

  @override
  String get authErrorVerifyEmail =>
      'We couldn\'t verify your email. Please try again.';

  @override
  String get authErrorResendCode =>
      'We couldn\'t resend the code. Please try again.';

  @override
  String get authErrorSendCode =>
      'We couldn\'t send the code. Please try again.';

  @override
  String get authErrorResetPassword =>
      'We couldn\'t change your password. Please try again.';

  @override
  String get authErrorSetPassword =>
      'We couldn\'t save your password. Please try again.';

  @override
  String get authErrorGoogle =>
      'We couldn\'t sign you in with Google. Please try again.';

  @override
  String get authErrorGoogleNotConfigured => 'Google sign-in is not set up.';

  @override
  String get authErrorGoogleNoData =>
      'Google didn\'t return your details. Please try again.';

  @override
  String get commonUser => 'User';

  @override
  String get setupProgressLabel => 'SIGN-UP PROGRESS';

  @override
  String get setupSaveErrorTitle => 'Couldn\'t save';

  @override
  String get setupGoalHeading => 'Set your goal';

  @override
  String get setupGoalSubtitle =>
      'We\'ll build your plan around what\nyou want to achieve.';

  @override
  String get setupGoalLoseTitle => 'Lose weight';

  @override
  String get setupGoalLoseSubtitle => 'A healthy calorie deficit';

  @override
  String get setupGoalMaintainTitle => 'Maintain weight';

  @override
  String get setupGoalMaintainSubtitle => 'Stability and everyday nutrition';

  @override
  String get setupGoalGainTitle => 'Gain weight';

  @override
  String get setupGoalGainSubtitle => 'A surplus to build muscle';

  @override
  String get setupGoalPlanBadge => 'PERSONALIZED PLAN';

  @override
  String get setupGoalCaloriesLabel => 'RECOMMENDED DAILY CALORIES';

  @override
  String get setupGoalCaloriesNote =>
      'Based on your basal metabolic rate and\ncurrent activity level.';

  @override
  String get setupGoalSaving => 'Saving your goal...';

  @override
  String get setupGoalStart => 'Start your goal';

  @override
  String get setupGoalSaveError =>
      'We couldn\'t save your goal. Please try again.';

  @override
  String get setupProfileHeading => 'Complete your profile';

  @override
  String get setupProfileSubtitle =>
      'This info helps us personalize your\nnutrition plan.';

  @override
  String get setupAgeLabel => 'AGE';

  @override
  String get setupWeightLabel => 'WEIGHT (KG)';

  @override
  String get setupHeightLabel => 'HEIGHT (CM)';

  @override
  String get setupSexLabel => 'SEX';

  @override
  String get setupSexMale => 'Male';

  @override
  String get setupSexFemale => 'Female';

  @override
  String get setupUnitYears => 'years';

  @override
  String get setupPrecisionTitle => 'NutriLife precision';

  @override
  String get setupPrecisionBody =>
      'Your basal metabolic rate will be\ncalculated automatically.';

  @override
  String get setupProfileSaving => 'Saving...';

  @override
  String get setupProfileSave => 'Save profile';

  @override
  String get setupAgeRequired => 'Your age is required.';

  @override
  String get setupAgeInvalid => 'Enter a valid age.';

  @override
  String get setupAgeTooYoung => 'You must be at least 16 years old.';

  @override
  String get setupWeightRequired => 'Your weight is required.';

  @override
  String get setupWeightInvalid => 'Enter a valid weight.';

  @override
  String get setupWeightOutOfRange => 'Select a valid weight.';

  @override
  String get setupHeightRequired => 'Your height is required.';

  @override
  String get setupHeightInvalid => 'Enter a valid height.';

  @override
  String get setupHeightOutOfRange =>
      'Height must be between 1.50 cm and 2.50 cm.';

  @override
  String get setupSexRequired => 'Select your sex to continue.';

  @override
  String get setupSnackMissingTitle => 'Missing info';

  @override
  String get setupProfileSaveError =>
      'We couldn\'t save your profile. Please try again.';

  @override
  String get setupErrorNothingToSave => 'There\'s nothing to save.';

  @override
  String get setupErrorSave => 'We couldn\'t save your info. Please try again.';

  @override
  String get commonNavHome => 'Home';

  @override
  String get commonNavFoods => 'Foods';

  @override
  String get commonNavAi => 'AI';

  @override
  String get commonNavProgress => 'Progress';

  @override
  String get commonNavProfile => 'Profile';

  @override
  String get homeSummaryLabel => 'SUMMARY';

  @override
  String homeGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get homeAiCardTitle => 'Ask the AI what to eat.';

  @override
  String get homeAiCardSubtitle => 'Meal ideas tailored to your goals.';

  @override
  String homeAddToMeal(String meal) {
    return 'Add to $meal';
  }

  @override
  String get homeTodayMealsTitle => 'Today\'s meals';

  @override
  String get homeViewHistory => 'View history';

  @override
  String get homeTodayCaloriesTitle => 'Today\'s calories';

  @override
  String homeTodayCaloriesTarget(String kcal) {
    return 'Goal: $kcal kcal';
  }

  @override
  String get homeTodayCaloriesTotal => 'Total consumed';

  @override
  String get homeTodayCaloriesConsumed => 'consumed';

  @override
  String get homeGoalLoading => 'Loading your daily goal...';

  @override
  String get homeGoalError => 'We couldn\'t load your daily goal.';

  @override
  String get homeGoalIncomplete =>
      'Complete your profile to calculate your daily goal.';

  @override
  String homeGoalRemaining(String kcal) {
    return 'You have $kcal kcal left to reach today\'s goal.';
  }

  @override
  String homeGoalExceeded(String kcal) {
    return 'You went $kcal kcal over your daily goal.';
  }

  @override
  String get homeGoalReached => 'You\'ve reached your daily goal!';

  @override
  String get mealsTypeBreakfast => 'Breakfast';

  @override
  String get mealsTypeLunch => 'Lunch';

  @override
  String get mealsTypeDinner => 'Dinner';

  @override
  String get mealsTypeSnack => 'Snack';

  @override
  String get mealsNotLoggedYet => 'Not logged yet';

  @override
  String mealsPortionsOne(String amount) {
    return '$amount serving';
  }

  @override
  String mealsPortionsOther(String amount) {
    return '$amount servings';
  }

  @override
  String get mealsErrorAddFood => 'Couldn\'t log the meal';

  @override
  String get mealsErrorAddRecipe => 'Couldn\'t log the recipe';

  @override
  String get mealsErrorDeleteRecipe => 'Couldn\'t delete the recipe';

  @override
  String get mealsErrorDeleteItem => 'Couldn\'t delete it';

  @override
  String get mealsErrorLoadDay => 'Couldn\'t load your meals';

  @override
  String get mealsHistoryTitle => 'Meal history';

  @override
  String get mealsPickDate => 'Pick a date';

  @override
  String get mealsPreviousDay => 'Previous day';

  @override
  String get mealsNextDay => 'Next day';

  @override
  String get mealsToday => 'Today';

  @override
  String get mealsYesterday => 'Yesterday';

  @override
  String mealsDateLabel(String weekday, int day, String month) {
    return '$weekday, $month $day';
  }

  @override
  String mealsAddedTo(String meal, int kcal) {
    return 'Added to $meal · $kcal kcal';
  }

  @override
  String mealsRegisteredIn(String meal, int kcal) {
    return 'Added to $meal · $kcal kcal';
  }

  @override
  String get mealsUndo => 'Undo';

  @override
  String get mealsUndoFailed => 'Couldn\'t undo';

  @override
  String mealsKcalPerUnit(int kcal, String unit) {
    return '$kcal kcal per $unit';
  }

  @override
  String get mealsLess => 'Less';

  @override
  String get mealsMore => 'More';

  @override
  String mealsDetailTitle(String meal, int kcal) {
    return '$meal · $kcal kcal';
  }

  @override
  String get mealsOtherFoods => 'OTHER FOODS';

  @override
  String get mealsDeleteRecipeTitle => 'Delete recipe?';

  @override
  String mealsDeleteRecipeBody(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'its $count ingredients',
      one: 'its ingredient',
    );
    return '\"$title\" will be removed from this meal along with $_temp0.';
  }

  @override
  String get mealsDelete => 'Delete';

  @override
  String get mealsDeleteRecipe => 'Delete recipe';

  @override
  String get mealsViewRecipe => 'View recipe';

  @override
  String mealsDeleteItem(String name) {
    return 'Delete $name';
  }

  @override
  String get mealsRegisterNoIngredients =>
      'This recipe has no ingredients to log';

  @override
  String get mealsRegisterTitle => 'Log meal';

  @override
  String get mealsLessPortions => 'Fewer servings';

  @override
  String get mealsMorePortions => 'More servings';

  @override
  String mealsCalculatingCalories(int servings) {
    return 'Calculating calories… · serves $servings';
  }

  @override
  String mealsRecipeYield(int kcal, int servings) {
    return '$kcal kcal · serves $servings';
  }

  @override
  String get mealsLoadFoodsError =>
      'We couldn\'t load the recipe\'s foods. Please try again.';

  @override
  String mealsRegisterIn(String meal) {
    return 'Add to $meal';
  }

  @override
  String get nutritionAddFridgeTitle => 'Add to my fridge';

  @override
  String get nutritionLogConsumedTitle => 'Log what you ate';

  @override
  String get nutritionAddFridgeSubtitle =>
      'It\'ll be saved in your fridge so the AI can suggest it when you chat.';

  @override
  String get nutritionLogConsumedSubtitle =>
      'It\'ll be logged as eaten in the meal you pick, so your calorie count stays accurate.';

  @override
  String get nutritionFoodNameLabel => 'Food name';

  @override
  String get nutritionFoodNameHint => 'E.g. Banana';

  @override
  String get nutritionFoodNameRequired => 'Please enter a name';

  @override
  String get nutritionSimilarFoodExists =>
      'A similar food already exists. Pick one to use it:';

  @override
  String nutritionUseFood(String name) {
    return 'Use $name';
  }

  @override
  String get nutritionChange => 'Change';

  @override
  String get nutritionCaloriesLabel => 'Calories (kcal)';

  @override
  String get nutritionCaloriesHint => 'E.g. 105';

  @override
  String get nutritionCaloriesRequired => 'Enter calories';

  @override
  String get nutritionMustBePositive => 'Must be > 0';

  @override
  String get nutritionPortionLabel => 'Serving';

  @override
  String get nutritionAmountHaveLabel => 'Amount you have';

  @override
  String get nutritionAmountConsumedLabel => 'Amount eaten';

  @override
  String get nutritionAmountRequired => 'Enter an amount';

  @override
  String get nutritionAmountLabel => 'Amount';

  @override
  String get nutritionUnitLabel => 'Unit';

  @override
  String get nutritionMealOfDay => 'Meal of the day';

  @override
  String get nutritionSaving => 'Saving...';

  @override
  String get nutritionSaveInFridge => 'Save to fridge';

  @override
  String get nutritionSaveInMyFridge => 'Save to my fridge';

  @override
  String get nutritionLogConsumption => 'Log what I ate';

  @override
  String get nutritionGenericError => 'Error';

  @override
  String get nutritionErrorNoFoodId =>
      'We couldn\'t get the food\'s ID. Please try again.';

  @override
  String get nutritionErrorRegisterFailed =>
      'We couldn\'t complete that. Please try again.';

  @override
  String get nutritionDoneTitle => 'All set!';

  @override
  String get nutritionDoneFridge => 'Your food is now in the fridge.';

  @override
  String get nutritionDoneConsumed => 'Your meal has been logged.';

  @override
  String get nutritionAddAnotherFridge => 'Add another to my fridge';

  @override
  String get nutritionLogAnother => 'Log another meal';

  @override
  String get nutritionDoneButton => 'Done';

  @override
  String get nutritionFridgeTitle => 'My fridge';

  @override
  String get nutritionFridgeSubtitle =>
      'What you have at home. The AI suggests it first when you attach it to the chat.';

  @override
  String get nutritionHowItWorks => 'How does it work?';

  @override
  String get nutritionCommonTitle => 'Common';

  @override
  String get nutritionManualEntryTitle => 'Manual entry';

  @override
  String get nutritionHelpFridgeBody =>
      'Foods you\'ve saved. When you attach them to the chat, the AI prioritizes them.';

  @override
  String get nutritionHelpCommonBody =>
      'NutriLife\'s general catalog, for when you can\'t find what you\'re looking for.';

  @override
  String get nutritionHelpManualBody =>
      'Choose \"I have it\" (goes to your fridge) or \"I ate it\" (logged, not saved).';

  @override
  String get nutritionGotIt => 'Got it';

  @override
  String get nutritionCustomTitle => 'Add your own';

  @override
  String get nutritionCustomBody =>
      'Can\'t find your food? Add it and choose whether you have it at home or just logged it.';

  @override
  String get nutritionToFridge => 'To my fridge';

  @override
  String get nutritionIAteIt => 'I ate it';

  @override
  String get nutritionSavedSubtitle => 'What you\'ve saved';

  @override
  String get nutritionCatalogSubtitle => 'NutriLife catalog';

  @override
  String get nutritionSeeAllItems => 'See all';

  @override
  String get nutritionSeeAllFoods => 'See all';

  @override
  String get nutritionSeeLess => 'See less';

  @override
  String nutritionResultsCount(int count) {
    return 'Results ($count)';
  }

  @override
  String get nutritionTip =>
      'Tip: adding what\'s in your fridge first (not what you ate out) helps the AI suggest recipes using what you already have at home.';

  @override
  String nutritionNoResults(String query) {
    return 'We couldn\'t find \"$query\". Try another name or add it from \"Manual entry\".';
  }

  @override
  String get nutritionNoCommonFoods => 'No common foods loaded yet.';

  @override
  String nutritionFoodAddedToFridge(String food) {
    return '$food added to your fridge';
  }

  @override
  String nutritionFoodLoggedIn(String food, String meal) {
    return '$food added to $meal';
  }

  @override
  String get nutritionErrorAdd => 'Couldn\'t add it';

  @override
  String get nutritionErrorLog => 'Couldn\'t log it';

  @override
  String nutritionBulkResult(int ok, int total) {
    return '$ok/$total processed successfully.';
  }

  @override
  String nutritionBulkResultWithFailed(int ok, int total, String names) {
    return '$ok/$total processed successfully. Failed: $names';
  }

  @override
  String get nutritionAskMealTitle => 'Which meal?';

  @override
  String get nutritionAskMealBody =>
      'All the selected foods will be logged as eaten in the meal you choose.';

  @override
  String get nutritionActions => 'Actions';

  @override
  String get nutritionClearSelection => 'Clear selection';

  @override
  String nutritionSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods selected',
      one: '1 food selected',
    );
    return '$_temp0';
  }

  @override
  String get nutritionEmptyFridgeTitle => 'Your fridge is empty';

  @override
  String get nutritionEmptyFridgeBody =>
      'Add what you have at home from \"Manual entry\" so the AI can suggest it in the chat.';

  @override
  String get nutritionAllFoodsTitle => 'All foods';

  @override
  String nutritionItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String nutritionFoodsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods',
      one: '1 food',
    );
    return '$_temp0';
  }

  @override
  String get nutritionFridgeEmptyAll =>
      'Your fridge is empty. Add foods from \"Manual entry\" or from the Common tab.';

  @override
  String nutritionEditAmount(String name) {
    return 'Edit amount of $name';
  }

  @override
  String nutritionFridgeItemRemoved(String name) {
    return '$name was removed from your fridge';
  }

  @override
  String nutritionFridgeAmountUpdated(String name) {
    return '$name amount updated';
  }

  @override
  String get nutritionRemoveFoodTitle => 'Remove food';

  @override
  String nutritionRemoveFoodBody(String name) {
    return 'Remove $name from your fridge? It will no longer show up among your available foods.';
  }

  @override
  String get nutritionRemove => 'Remove';

  @override
  String get nutritionAmountGreaterThanZero => 'Enter an amount greater than 0';

  @override
  String nutritionCantSubtractMore(String quantity) {
    return 'You can\'t subtract more than you have ($quantity).';
  }

  @override
  String nutritionAvailable(String amount) {
    return 'Available: $amount';
  }

  @override
  String nutritionAdjustLabel(String unit) {
    return 'Amount to add or subtract ($unit)';
  }

  @override
  String nutritionNewTotalLabel(String unit) {
    return 'New total amount ($unit)';
  }

  @override
  String get nutritionSubtract => 'Subtract';

  @override
  String get nutritionIncrease => 'Add';

  @override
  String get nutritionSaveExactAmount => 'Save exact amount';

  @override
  String get nutritionRemoveFromFridge => 'Remove from fridge';

  @override
  String get nutritionSearchHint => 'Search over 100,000 foods...';

  @override
  String get nutritionClearSearch => 'Clear search';

  @override
  String get nutritionUnitOne => '1 unit';

  @override
  String get nutritionUnitServing => '1 serving';

  @override
  String get nutritionUnitCup => '1 cup';

  @override
  String get nutritionUnitTablespoon => '1 tablespoon';

  @override
  String get nutritionUnitSlice => '1 slice';

  @override
  String nutritionCountUnit(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountServing(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountCup(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount cups',
      one: '1 cup',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountTablespoon(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount tablespoons',
      one: '1 tablespoon',
    );
    return '$_temp0';
  }

  @override
  String nutritionCountSlice(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount slices',
      one: '1 slice',
    );
    return '$_temp0';
  }

  @override
  String get nutritionErrorServerConnection => 'Server connection error';

  @override
  String get nutritionErrorLoadFoods => 'Couldn\'t load foods';

  @override
  String nutritionErrorUnexpectedLoadFoods(String error) {
    return 'Something unexpected went wrong loading the foods: $error';
  }

  @override
  String get nutritionErrorRegisterFood => 'Couldn\'t save the food';

  @override
  String get nutritionErrorRegisterFoodServer =>
      'Couldn\'t save the food on the server';

  @override
  String nutritionErrorUnexpectedRegisterFood(String error) {
    return 'Something unexpected went wrong saving the food: $error';
  }

  @override
  String get nutritionErrorLoadFridge => 'Couldn\'t load your fridge';

  @override
  String nutritionErrorUnexpectedLoadFridge(String error) {
    return 'Something unexpected went wrong loading your fridge: $error';
  }

  @override
  String get nutritionErrorAddToFridge => 'Couldn\'t add it to your fridge';

  @override
  String nutritionErrorAddToFridgeDetail(String error) {
    return 'Couldn\'t add it to your fridge: $error';
  }

  @override
  String get nutritionErrorUpdateAmount => 'Couldn\'t update the amount';

  @override
  String nutritionErrorUpdateAmountDetail(String error) {
    return 'Couldn\'t update the amount: $error';
  }

  @override
  String get nutritionErrorRemoveFromFridge =>
      'Couldn\'t remove it from your fridge';

  @override
  String nutritionErrorRemoveFromFridgeDetail(String error) {
    return 'Couldn\'t remove it from your fridge: $error';
  }
}
