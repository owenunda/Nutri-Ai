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
      'We couldn\'t save that entry. Please try again.';

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

  @override
  String nutritionUnitNameUnit(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'units',
      one: 'unit',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameServing(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'servings',
      one: 'serving',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cups',
      one: 'cup',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameTablespoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tablespoons',
      one: 'tablespoon',
    );
    return '$_temp0';
  }

  @override
  String nutritionUnitNameSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'slices',
      one: 'slice',
    );
    return '$_temp0';
  }

  @override
  String get commonDone => 'Done';

  @override
  String get chatHistoryBarrierLabel => 'Close history';

  @override
  String get chatWaitForReply => 'Hold on until the chef finishes replying';

  @override
  String get chatDeleteTitle => 'Delete chat';

  @override
  String get chatDeleteConfirm =>
      'Are you sure you want to delete this conversation?';

  @override
  String get chatDeleteButton => 'Delete';

  @override
  String get chatTooltipHistory => 'History';

  @override
  String get chatTooltipNewChat => 'New conversation';

  @override
  String get chatWelcomeTitle => 'How can I help you today?';

  @override
  String get chatWelcomeSubtitle =>
      'Ask me for recipes, nutrition tips or meal plans.';

  @override
  String get chatInputHint => 'Message NutriLife...';

  @override
  String chatRateLimitExhausted(int seconds) {
    return 'Limit reached · try again in ${seconds}s';
  }

  @override
  String chatRateLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count messages left this minute',
      one: 'You have 1 message left this minute',
    );
    return '$_temp0';
  }

  @override
  String get chatRateLimitReplyMinute =>
      'Hang on a moment, you\'ve reached the per-minute message limit';

  @override
  String chatRateLimitReplyMinutes(int minutes) {
    return 'Please wait about $minutes minutes, you\'ve reached the message limit';
  }

  @override
  String get chatGenericError =>
      'Sorry, something went wrong. Please try again.';

  @override
  String get chatHistoryTitle => 'Conversations';

  @override
  String get chatHistoryEmpty => 'No conversations yet';

  @override
  String get chatSessionFallbackTitle => 'Conversation';

  @override
  String get chatSessionActive => 'Active';

  @override
  String chatHistoryToday(String time) {
    return 'Today, $time';
  }

  @override
  String chatHistoryYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String chatHistoryDate(int day, String month) {
    return '$month $day';
  }

  @override
  String chatStepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String chatStepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get chatStepByStep => 'Step by step';

  @override
  String get chatViewStepByStep => 'See step by step';

  @override
  String get chatChefTip => 'Chef\'s tip';

  @override
  String chatServingsShort(int count) {
    return '$count SERV.';
  }

  @override
  String chatServingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String get chatSeeMore => 'See more';

  @override
  String get chatSeeLess => 'See less';

  @override
  String get chatViewFullRecipe => 'View full recipe';

  @override
  String get chatLogMeal => 'Log meal';

  @override
  String chatStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get chatTipsTab => 'Tips';

  @override
  String get chatPrevious => 'Back';

  @override
  String get chatNext => 'Next';

  @override
  String get chatSwipeHint => 'Swipe to continue';

  @override
  String get chatChefTips => 'Chef\'s tips';

  @override
  String get chatPickerTitle => 'Add foods';

  @override
  String get chatPickerIntro =>
      'My fridge: what you have at home. Common: the general catalog.';

  @override
  String get chatPickerTabFridge => 'My fridge';

  @override
  String get chatPickerTabCommon => 'Common';

  @override
  String get chatPickerSearchFridge => 'Search your fridge';

  @override
  String get chatPickerSearchCommon => 'Search common foods';

  @override
  String chatPickerAddCount(int count) {
    return 'Add $count to message';
  }

  @override
  String get chatPickerErrorTitle => 'We couldn\'t read your fridge';

  @override
  String get chatPickerNoResults => 'No results';

  @override
  String chatPickerNoResultsFridge(String query) {
    return 'We couldn\'t find \"$query\" in your fridge.';
  }

  @override
  String chatPickerNoResultsCommon(String query) {
    return 'We couldn\'t find \"$query\" in common foods.';
  }

  @override
  String chatPickerSeeInFridge(int count) {
    return 'See in My fridge ($count)';
  }

  @override
  String chatPickerSeeInCommon(int count) {
    return 'See in Common ($count)';
  }

  @override
  String get chatPickerCommonEmptyTitle => 'No common foods';

  @override
  String get chatPickerCommonEmptyBody =>
      'We couldn\'t load the catalog. Please try again later.';

  @override
  String get chatPickerFridgeEmptyTitle => 'Your fridge is empty';

  @override
  String get chatPickerFridgeEmptyBody =>
      'Add foods from the Foods tab or pick from Common.';

  @override
  String get chatPickerNoAmount => 'No amount';

  @override
  String get chatErrorTimeout =>
      'The chef is taking a while. Please try again.';

  @override
  String get chatErrorServerConnection => 'Couldn\'t connect to the server';

  @override
  String get chatErrorUnexpectedResponse =>
      'Unexpected response from the server';

  @override
  String chatErrorReadReply(String error) {
    return 'Couldn\'t read the chef\'s reply: $error';
  }

  @override
  String get chatErrorLoadHistory => 'Couldn\'t load your history';

  @override
  String chatErrorUnexpected(String error) {
    return 'Something unexpected happened: $error';
  }

  @override
  String get chatErrorLoadSession => 'Couldn\'t load the session';

  @override
  String get chatErrorLoadConversation => 'Couldn\'t load the conversation';

  @override
  String get chatErrorOpenConversation => 'Couldn\'t open the conversation';

  @override
  String get chatErrorCloseSession => 'Couldn\'t close the session';

  @override
  String get chatNoReply => 'No reply';

  @override
  String get progressKicker => 'WEEKLY PROGRESS';

  @override
  String progressGreeting(String name) {
    return 'Great progress,\n$name!';
  }

  @override
  String progressGoalPill(String goal) {
    return 'Goal:\n$goal';
  }

  @override
  String get progressGoalLose => 'Lose weight';

  @override
  String get progressGoalGain => 'Gain weight';

  @override
  String get progressGoalMaintain => 'Maintain weight';

  @override
  String get progressGoalNone => 'No goal';

  @override
  String get progressStatusNoData => 'No data';

  @override
  String get progressStatusExceeded => 'EXCEEDED';

  @override
  String get progressErrorTitle => 'Couldn\'t load your progress';

  @override
  String get progressErrorLoadShort => 'Couldn\'t load your progress.';

  @override
  String get progressErrorLoad =>
      'Couldn\'t load your progress. Please try again.';

  @override
  String get progressErrorLoadDailyGoal =>
      'Couldn\'t load your daily goal. Please try again.';

  @override
  String get progressErrorSaveWeight => 'Couldn\'t save your weight.';

  @override
  String get progressErrorInvalidData => 'The server sent back invalid data.';

  @override
  String get progressErrorLoadInfo => 'Couldn\'t load the information.';

  @override
  String get progressRetry => 'Try again';

  @override
  String get progressWeightSummaryTitle => 'Weight summary';

  @override
  String progressWeightDown(String amount) {
    return 'Your weight dropped\n$amount since your last entry';
  }

  @override
  String progressWeightUp(String amount) {
    return 'Your weight went up\n$amount since your last entry';
  }

  @override
  String progressWeightChanged(String amount) {
    return 'Your weight changed\n$amount since your last entry';
  }

  @override
  String get progressCurrentWeight => 'Current weight';

  @override
  String get progressNoRecord => 'No entries yet';

  @override
  String get progressCompareHint => 'Compared with your previous entry.';

  @override
  String get progressAddAnotherHint =>
      'Log another weight later to see how you\'re doing.';

  @override
  String get progressRegisterWeight => 'Log weight';

  @override
  String get progressSummaryWeek => 'Weekly summary';

  @override
  String get progressSummaryNutrition => 'Nutrition summary';

  @override
  String get progressTodayCaloriesTitle => 'Today\'s calories';

  @override
  String get progressKcalConsumed => 'kcal consumed';

  @override
  String progressKcalOfLimit(String limit) {
    return 'of $limit kcal';
  }

  @override
  String get progressCompleteDataHint =>
      'Fill in your body stats and goal to work out your daily limit.';

  @override
  String progressGoalAndRemaining(String limit, String remaining) {
    return 'Daily goal: $limit kcal. You have $remaining kcal left today.';
  }

  @override
  String get progressHistoryTitle => 'Weight history';

  @override
  String get progressHistoryNoCurrent => 'No current weight';

  @override
  String progressHistoryCurrent(String weight) {
    return '${weight}kg Current';
  }

  @override
  String get progressHistoryEmpty =>
      'You don\'t have any body stats history yet.';

  @override
  String get progressAxisStart => 'START';

  @override
  String get progressAxisToday => 'TODAY';

  @override
  String get progressTileConsumed => 'CONSUMED';

  @override
  String get progressTileLoggedToday => 'Logged today';

  @override
  String get progressTileDailyGoal => 'DAILY GOAL';

  @override
  String get progressTileRemaining => 'REMAINING';

  @override
  String get progressTileStatus => 'STATUS';

  @override
  String get progressTileDailyAverage => 'DAILY AVERAGE';

  @override
  String get progressTileDaysOnTarget => 'DAYS ON TARGET';

  @override
  String get progressTileWeekTotal => 'WEEK TOTAL';

  @override
  String progressDaysOfSeven(int count) {
    return '$count of 7';
  }

  @override
  String get progressWeekTitle => 'This week';

  @override
  String progressWeekAverage(String average) {
    return 'Average: $average kcal/day';
  }

  @override
  String progressWeekAverageOnTarget(String average, int days) {
    return 'Average: $average kcal/day · $days of 7 days on target';
  }

  @override
  String progressWeekDaySelected(String weekday, int day, String kcal) {
    return '$weekday $day · $kcal kcal';
  }

  @override
  String get progressCompleteProfile => 'Complete your profile';

  @override
  String get progressSheetHintNoLast =>
      'Type your weight or adjust it with − and +';

  @override
  String progressSheetLastEntry(String weight) {
    return 'Last entry: $weight kg';
  }

  @override
  String get progressSheetSame => 'Same as last time';

  @override
  String progressSheetIncrease(String weight) {
    return '+$weight kg since last time';
  }

  @override
  String progressSheetDecrease(String weight) {
    return '−$weight kg since last time';
  }

  @override
  String get progressSheetSubtract => 'Subtract 0.1 kg';

  @override
  String get progressSheetAdd => 'Add 0.1 kg';

  @override
  String get progressSheetHeightLabel => 'Height (cm)';

  @override
  String get progressSheetWeightRangeError =>
      'Weight must be between 30 and 300 kg';

  @override
  String get progressSheetHeightRequired => 'Enter your height in cm';

  @override
  String get progressSheetSave => 'Save weight';

  @override
  String get profileLoadError => 'We couldn\'t load your profile.';

  @override
  String get profileLoadErrorRetry =>
      'We couldn\'t load your profile. Please try again.';

  @override
  String get profileUpdateError => 'We couldn\'t update your profile.';

  @override
  String get profileUpdateErrorRetry =>
      'We couldn\'t update your profile. Please try again.';

  @override
  String get profileDeleteError => 'We couldn\'t delete your account.';

  @override
  String get profileDeleteErrorRetry =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get profileDeleteWrongPassword => 'That password isn\'t correct.';

  @override
  String get profileDeleteGoogleMismatch =>
      'That Google account doesn\'t match this profile.';

  @override
  String get profileDeleteGoogleFailed =>
      'We couldn\'t confirm with Google. Please try again.';

  @override
  String get profileMemberDefault => 'NutriLife member';

  @override
  String profileMemberSince(String year) {
    return 'Member since $year';
  }

  @override
  String profileMemberPlan(String plan) {
    return '$plan member';
  }

  @override
  String profileMemberPlanSince(String plan, String year) {
    return '$plan member since $year';
  }

  @override
  String get profileStatAge => 'AGE';

  @override
  String get profileStatWeight => 'WEIGHT';

  @override
  String get profileStatHeight => 'HEIGHT';

  @override
  String get profileGoalHeading => 'Nutrition goal';

  @override
  String get profileGoalActive => 'ACTIVE';

  @override
  String get profileGoalPillLose => 'Lose weight';

  @override
  String get profileGoalPillMaintain => 'Maintain';

  @override
  String get profileGoalPillGain => 'Build muscle';

  @override
  String get profileSettingsHeading => 'Settings & reminders';

  @override
  String get premiumTitle => 'NutriLife Premium';

  @override
  String get profilePremiumSubtitle => 'Plans and benefits';

  @override
  String get profileRemindersTitle => 'Meal reminders';

  @override
  String get profileRemindersSubtitle => 'Daily alerts for 4 meals';

  @override
  String get profileNotificationsTitle => 'Notification settings';

  @override
  String get profileNotificationsSubtitle => 'Push, email and SMS';

  @override
  String get profileConfigTitle => 'Settings';

  @override
  String get profileConfigSubtitle => 'Age, height, sex, goal and email';

  @override
  String get profileLegalHeading => 'Legal';

  @override
  String get profileTermsTitle => 'Terms and conditions';

  @override
  String get profileTermsSubtitle => 'Rules for using NutriLife';

  @override
  String get profilePrivacyTitle => 'Privacy policy';

  @override
  String get profilePrivacySubtitle => 'How we handle your data';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileLoadErrorTitle => 'We couldn\'t load your profile';

  @override
  String get profileRetry => 'Try again';

  @override
  String get profileDeleteDone => 'Your account and data have been deleted.';

  @override
  String get profileDeleteDialogTitle => 'Delete your account?';

  @override
  String get profileDeleteDialogBody =>
      'Your profile, weight history, meals, fridge, recipes and conversations will be permanently deleted. This can\'t be undone.';

  @override
  String get profileDeletePasswordRequired => 'Enter your password to confirm.';

  @override
  String get profileDeletePasswordLabel => 'Password';

  @override
  String get profileDeleteGoogleHint =>
      'To confirm, choose your Google account.';

  @override
  String get profileDeleting => 'Deleting...';

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleteConfirmGoogle => 'Confirm with Google';

  @override
  String get profileEditHeading => 'Nutrition details';

  @override
  String get profileEditSubtitle =>
      'Update your details so NutriLife can fine-tune your plan.';

  @override
  String get profileEditAge => 'Age';

  @override
  String get profileEditYearsUnit => 'years';

  @override
  String get profileEditHeight => 'Height';

  @override
  String get profileEditWeight => 'Weight';

  @override
  String get profileEditSex => 'Sex';

  @override
  String get profileEditGoal => 'Goal';

  @override
  String get profileEditAccountHeading => 'Account';

  @override
  String get profileEditEmail => 'Email';

  @override
  String get profileEditEmailMissing => 'Email not available';

  @override
  String get profileEditSaving => 'Saving...';

  @override
  String get profileEditSave => 'Save changes';

  @override
  String get profileEditSelectAll => 'Select all your details to continue.';

  @override
  String get profileEditHeightInvalid =>
      'Select a valid height between 1.50 cm and 2.50 cm.';

  @override
  String get profileEditWeightDialogTitle =>
      'You\'re about to update your weight';

  @override
  String get profileEditWeightDialogBody =>
      'This change may affect your current settings, like your daily calorie target and your nutrition plan. NutriLife will recalculate your goals with the new value.';

  @override
  String get premiumSubtitle => 'Take your nutrition to the next level';

  @override
  String get premiumBenefitChat => 'AI Chef with unlimited messages';

  @override
  String get premiumBenefitProgress => 'Full progress history';

  @override
  String get premiumBenefitPlans => 'Weekly meal plans';

  @override
  String get premiumBenefitRecipes => 'Unlimited saved recipes';

  @override
  String get premiumPlanYearly => 'Yearly';

  @override
  String get premiumPlanMonthly => 'Monthly';

  @override
  String premiumPricePerYear(String price) {
    return '$price / year';
  }

  @override
  String premiumPricePerMonth(String price) {
    return '$price / month';
  }

  @override
  String get premiumSaveBadge => 'Save 50%';

  @override
  String get premiumStartTrial => 'Start 7 days free';

  @override
  String get premiumRestore => 'Restore purchases';

  @override
  String get premiumTerms => 'Terms';

  @override
  String get premiumPaymentsSoon => 'Payments are coming soon';

  @override
  String get premiumPromoTitle => 'Unlock your full progress';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }
}
