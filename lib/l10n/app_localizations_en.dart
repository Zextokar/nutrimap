// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sectionWhatIs => 'What is NutriMap?';

  @override
  String get sectionWhatIsDesc =>
      'NutriMap helps you track your meals, nutrition, and healthy habits.';

  @override
  String get sectionHelps => 'What it will help you do';

  @override
  String get sectionHelpsDesc =>
      'Plan meals, track calories, monitor nutrients, and improve your diet.';

  @override
  String get sectionWhoWeAre => 'Who we are';

  @override
  String get sectionWhoWeAreDesc =>
      'We are a team passionate about nutrition and technology.';

  @override
  String get sectionBenefits => 'Benefits';

  @override
  String get sectionBenefitsDesc =>
      'Stay healthy, eat better, and reach your goals easily.';

  @override
  String get loginTitle => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get nextButton => 'Next';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get benefits => 'Benefits';

  @override
  String get recipes => 'Recipes';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get register => 'Sign up';

  @override
  String get loginError => 'Login error';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get invalidEmailError => 'Invalid email format';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get shortPassword => 'Password must be at least 6 characters';

  @override
  String settingsUser(Object email) {
    return 'Settings for $email';
  }

  @override
  String get logout => 'Log Out';

  @override
  String get user => 'User';

  @override
  String benefitsUser(Object email) {
    return 'Benefits available for $email';
  }

  @override
  String get registerTitle => 'Register';

  @override
  String get registerStep1Title => 'Personal Information';

  @override
  String get registerStep2Title => 'Email and Password';

  @override
  String get registerStep3Title => 'Institution and Preferences';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get institution => 'Institution';

  @override
  String get dietas => 'Preferred Diets';

  @override
  String get chooseDiet => 'Choose your diets';

  @override
  String get enterName => 'Please enter your first name';

  @override
  String get enterLastName => 'Please enter your last name';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get registerError => 'Error registering user';

  @override
  String summaryUser(Object email) {
    return 'Review your information: $email';
  }

  @override
  String get selectInstitution => 'Select your institution';

  @override
  String get personalData => 'Personal Data';

  @override
  String get diets => 'Preferred Diets';

  @override
  String get confirmRegistration => 'Confirm Registration';

  @override
  String get cancel => 'Cancel';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registrationError => 'Error registering user';

  @override
  String get emailInUse => 'Email is already in use';

  @override
  String get enterFirstName => 'Please enter your first name';

  @override
  String get phone => 'Phone number';
}
