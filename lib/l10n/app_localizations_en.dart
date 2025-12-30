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
  String get sectionWhatIsDesc => 'NutriMap helps you track your meals, nutrition, and healthy habits.';

  @override
  String get sectionHelps => 'What will it help you do?';

  @override
  String get sectionHelpsDesc => 'Plan meals, count calories, monitor nutrients, and improve your diet.';

  @override
  String get sectionWhoWeAre => 'Who are we?';

  @override
  String get sectionWhoWeAreDesc => 'We are a team passionate about nutrition and technology.';

  @override
  String get sectionBenefits => 'Benefits';

  @override
  String get sectionBenefitsDesc => 'Stay healthy, eat better, and achieve your goals easily.';

  @override
  String get loginTitle => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get nextButton => 'Next';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get benefits => 'Benefits';

  @override
  String get recipes => 'Businesses';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailRequired => 'Please enter your email.';

  @override
  String get invalidEmail => 'Please enter a valid email.';

  @override
  String get passwordRequired => 'Please enter your password.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get register => 'Sign Up';

  @override
  String get loginError => 'Error signing in.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get invalidEmailError => 'Invalid email format.';

  @override
  String get enterEmail => 'Enter your email.';

  @override
  String get enterPassword => 'Please enter your password.';

  @override
  String get shortPassword => 'Password must be at least 6 characters.';

  @override
  String settingsUser(Object email) {
    return 'Settings for $email';
  }

  @override
  String get logout => 'Logout';

  @override
  String get user => 'User';

  @override
  String benefitsUser(Object email) {
    return 'Benefits available for $email';
  }

  @override
  String get registerTitle => 'Sign Up';

  @override
  String get registerStep1Title => 'Personal Data';

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
  String get enterName => 'Please enter your name.';

  @override
  String get enterLastName => 'Please enter your last name.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get registerError => 'Error registering user.';

  @override
  String summaryUser(Object email) {
    return 'Review your data: $email';
  }

  @override
  String get selectInstitution => 'Select your institution';

  @override
  String get personalData => 'Personal Data';

  @override
  String get enterFirstName => 'Please enter your first name.';

  @override
  String get diets => 'Diets';

  @override
  String get confirmRegistration => 'Confirm your registration';

  @override
  String get cancel => 'Cancel';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registrationError => 'Error registering user.';

  @override
  String get emailInUse => 'Email already in use.';

  @override
  String get enterPhone => 'Please enter your phone number.';

  @override
  String get otherSettings => 'Other settings';

  @override
  String get profile => 'Profile';

  @override
  String get surname => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get rut => 'RUT';

  @override
  String get region => 'Region';

  @override
  String get commune => 'Commune';

  @override
  String get diet => 'Diet type';

  @override
  String get userProfile => 'User Profile';

  @override
  String get homeTitle => 'Home';

  @override
  String get commerce => 'Business';

  @override
  String get userDisabled => 'User disabled';

  @override
  String get tooManyRequests => 'Too many attempts, try again later';

  @override
  String get networkError => 'Network error, check your connection';

  @override
  String get forgotPasswordTitle => 'Forgot your password';

  @override
  String get forgotPasswordDescription => 'Enter your email and we\'ll send you a link to reset your password';

  @override
  String get sendResetLink => 'Send recovery link';

  @override
  String get resetEmailSent => 'A password reset email has been sent';

  @override
  String get resetEmailFailed => 'Error sending recovery email';

  @override
  String get registerDescription => 'Create your account by entering your data';

  @override
  String get name => 'Name';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get logoutConfirmationTitle => 'Logout?';

  @override
  String get logoutConfirmationMessage => 'You will be logged out of the application.';

  @override
  String get logoutError => 'Error logging out';

  @override
  String get resetPasswordError => 'Error sending recovery email.';

  @override
  String get sendResetLinkButton => 'Send Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get sectionPreferences => 'PREFERENCES';

  @override
  String get sectionOthers => 'OTHERS';

  @override
  String get profileSubtitle => 'View and edit your profile';

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOn => 'Enabled';

  @override
  String get notificationsOff => 'Disabled';

  @override
  String get language => 'Language';

  @override
  String get premium => 'Nutrimap Premium';

  @override
  String get about => 'About';

  @override
  String get terms => 'Terms and Conditions';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeDescription => 'Enable or disable the app\'s dark mode.';

  @override
  String get appTheme => 'App theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get premiumDescription => 'Access additional features with Nutrimap Premium.';

  @override
  String get aboutDescription => 'Information about the app and team.';

  @override
  String get termsDescription => 'Read the terms and conditions of use.';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get logoutBody => 'Are you sure you want to logout?';

  @override
  String editTitle(Object field) {
    return 'Edit $field';
  }

  @override
  String get save => 'Save';

  @override
  String get phoneHint => '9 1234 5678';

  @override
  String get personalInfo => 'PERSONAL INFORMATION';

  @override
  String get location => 'LOCATION';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get noOptions => 'No options available';

  @override
  String get selectFirstRegion => 'You must first select a Region.';

  @override
  String selectTitle(Object field) {
    return 'Select $field';
  }

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String errorOccurred(Object error) {
    return 'Error: $error';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get explore => 'Explore';

  @override
  String get navigating => 'Navigating';

  @override
  String get selectPoint => 'Select a point';

  @override
  String get startTrip => 'START TRIP';

  @override
  String get walking => 'Walking';

  @override
  String get bicycling => 'Bike';

  @override
  String get driving => 'Car';

  @override
  String get waitingGps => 'Waiting for GPS signal...';

  @override
  String get gpsOffline => 'GPS Offline';

  @override
  String get online => 'Online';

  @override
  String get arrived => 'You have arrived!';

  @override
  String distanceToTurn(Object distance) {
    return '$distance to turn';
  }

  @override
  String durationRemaining(Object duration) {
    return '$duration remaining';
  }

  @override
  String arrivalTime(Object time) {
    return 'Arrival: $time';
  }

  @override
  String get distance => 'Distance';

  @override
  String get duration => 'Duration';

  @override
  String get arrival => 'Arrival';

  @override
  String get turn => 'Turn';

  @override
  String get nextTurn => 'Next turn';

  @override
  String get meters => 'meters';

  @override
  String get kilometers => 'kilometers';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get errorFetchingLocations => 'Error fetching locations';

  @override
  String get yourLocation => 'Your location';

  @override
  String get noRouteFound => 'No route found';

  @override
  String get connectionError => 'Connection error';

  @override
  String get routeError => 'Route error';

  @override
  String get emailNotFound => 'Email not found';

  @override
  String get resetPasswordEmailSent => 'Send recovery email';

  @override
  String get passwordResetSent => 'Send recovery email';

  @override
  String get error => 'No se pudo enviar el correo de recuperación';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordBody => 'We will send a password reset link to';

  @override
  String get confirm => 'Confirm';
}
