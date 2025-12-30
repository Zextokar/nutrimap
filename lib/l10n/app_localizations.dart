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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Title of the 'What is NutriMap' section
  ///
  /// In en, this message translates to:
  /// **'What is NutriMap?'**
  String get sectionWhatIs;

  /// Description of the 'What is NutriMap' section
  ///
  /// In en, this message translates to:
  /// **'NutriMap helps you track your meals, nutrition, and healthy habits.'**
  String get sectionWhatIsDesc;

  /// Title of the 'What will it help you do' section
  ///
  /// In en, this message translates to:
  /// **'What will it help you do?'**
  String get sectionHelps;

  /// Description of the 'What will it help you do' section
  ///
  /// In en, this message translates to:
  /// **'Plan meals, count calories, monitor nutrients, and improve your diet.'**
  String get sectionHelpsDesc;

  /// Title of the 'Who are we' section
  ///
  /// In en, this message translates to:
  /// **'Who are we?'**
  String get sectionWhoWeAre;

  /// Description of the 'Who are we' section
  ///
  /// In en, this message translates to:
  /// **'We are a team passionate about nutrition and technology.'**
  String get sectionWhoWeAreDesc;

  /// Title of the 'Benefits' section
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get sectionBenefits;

  /// Description of the 'Benefits' section
  ///
  /// In en, this message translates to:
  /// **'Stay healthy, eat better, and achieve your goals easily.'**
  String get sectionBenefitsDesc;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Email field label in login
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label in login
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// Next button text in onboarding
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Label for the Home tab in BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Label for the Map tab in BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Label for the Benefits tab in BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// Label for the Recipes tab in BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get recipes;

  /// Label for the Settings tab in BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Welcome text below title on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Validation message when email is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get emailRequired;

  /// Validation message when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get invalidEmail;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get passwordRequired;

  /// Validation message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// Password recovery button
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// Separator text for social login
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Text asking if user has an account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Sign up button/link
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// Generic sign in error message
  ///
  /// In en, this message translates to:
  /// **'Error signing in.'**
  String get loginError;

  /// Message when user doesn't exist
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// Message when password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// Message when email is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailError;

  /// Enter your email
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get enterEmail;

  /// Message when password is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get enterPassword;

  /// Validation message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get shortPassword;

  /// Settings text for user
  ///
  /// In en, this message translates to:
  /// **'Settings for {email}'**
  String settingsUser(Object email);

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Default name or email
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Text showing user benefits
  ///
  /// In en, this message translates to:
  /// **'Benefits available for {email}'**
  String benefitsUser(Object email);

  /// Sign up title
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerTitle;

  /// Step 1 title
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get registerStep1Title;

  /// Step 2 title
  ///
  /// In en, this message translates to:
  /// **'Email and Password'**
  String get registerStep2Title;

  /// Step 3 title
  ///
  /// In en, this message translates to:
  /// **'Institution and Preferences'**
  String get registerStep3Title;

  /// Summary screen title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// First name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Institution field
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// Label for selecting diets
  ///
  /// In en, this message translates to:
  /// **'Preferred Diets'**
  String get dietas;

  /// Help text for diets
  ///
  /// In en, this message translates to:
  /// **'Choose your diets'**
  String get chooseDiet;

  /// Name empty validation
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get enterName;

  /// Last name empty validation
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name.'**
  String get enterLastName;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Confirm registration button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// General registration error
  ///
  /// In en, this message translates to:
  /// **'Error registering user.'**
  String get registerError;

  /// User data summary
  ///
  /// In en, this message translates to:
  /// **'Review your data: {email}'**
  String summaryUser(Object email);

  /// Institution help text
  ///
  /// In en, this message translates to:
  /// **'Select your institution'**
  String get selectInstitution;

  /// Personal data step
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// First name empty validation
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name.'**
  String get enterFirstName;

  /// Diet selection step
  ///
  /// In en, this message translates to:
  /// **'Diets'**
  String get diets;

  /// Final confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm your registration'**
  String get confirmRegistration;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Final registration button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Final registration error
  ///
  /// In en, this message translates to:
  /// **'Error registering user.'**
  String get registrationError;

  /// Duplicate email
  ///
  /// In en, this message translates to:
  /// **'Email already in use.'**
  String get emailInUse;

  /// Phone validation
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get enterPhone;

  /// Other settings
  ///
  /// In en, this message translates to:
  /// **'Other settings'**
  String get otherSettings;

  /// User profile title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// User last name
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get surname;

  /// Phone number
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// User RUT
  ///
  /// In en, this message translates to:
  /// **'RUT'**
  String get rut;

  /// User region
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// User commune
  ///
  /// In en, this message translates to:
  /// **'Commune'**
  String get commune;

  /// User diet type
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get diet;

  /// Profile screen
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// Main screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Business screen
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get commerce;

  /// User disabled in Firebase
  ///
  /// In en, this message translates to:
  /// **'User disabled'**
  String get userDisabled;

  /// Attempt limit exceeded
  ///
  /// In en, this message translates to:
  /// **'Too many attempts, try again later'**
  String get tooManyRequests;

  /// Network error
  ///
  /// In en, this message translates to:
  /// **'Network error, check your connection'**
  String get networkError;

  /// Password recovery title
  ///
  /// In en, this message translates to:
  /// **'Forgot your password'**
  String get forgotPasswordTitle;

  /// Recovery description
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password'**
  String get forgotPasswordDescription;

  /// Send recovery button
  ///
  /// In en, this message translates to:
  /// **'Send recovery link'**
  String get sendResetLink;

  /// Email sent message
  ///
  /// In en, this message translates to:
  /// **'A password reset email has been sent'**
  String get resetEmailSent;

  /// Error sending email
  ///
  /// In en, this message translates to:
  /// **'Error sending recovery email'**
  String get resetEmailFailed;

  /// Informative registration text
  ///
  /// In en, this message translates to:
  /// **'Create your account by entering your data'**
  String get registerDescription;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerButton;

  /// Logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutConfirmationTitle;

  /// Logout message
  ///
  /// In en, this message translates to:
  /// **'You will be logged out of the application.'**
  String get logoutConfirmationMessage;

  /// Logout error
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String get logoutError;

  /// Error sending email
  ///
  /// In en, this message translates to:
  /// **'Error sending recovery email.'**
  String get resetPasswordError;

  /// Send link button
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendResetLinkButton;

  /// Back to login
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Account section in settings
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// Preferences section
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get sectionPreferences;

  /// Others section
  ///
  /// In en, this message translates to:
  /// **'OTHERS'**
  String get sectionOthers;

  /// Profile subtitle
  ///
  /// In en, this message translates to:
  /// **'View and edit your profile'**
  String get profileSubtitle;

  /// Security option
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Change password option
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Notifications option
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get notificationsOn;

  /// Notifications disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get notificationsOff;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Premium option
  ///
  /// In en, this message translates to:
  /// **'Nutrimap Premium'**
  String get premium;

  /// About option
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Terms and conditions option
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get terms;

  /// Appearance section within Settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Option to enable or disable dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// Dark mode description
  ///
  /// In en, this message translates to:
  /// **'Enable or disable the app\'s dark mode.'**
  String get darkModeDescription;

  /// Title for selecting theme
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appTheme;

  /// System-based theme
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Description for Premium option
  ///
  /// In en, this message translates to:
  /// **'Access additional features with Nutrimap Premium.'**
  String get premiumDescription;

  /// About section description
  ///
  /// In en, this message translates to:
  /// **'Information about the app and team.'**
  String get aboutDescription;

  /// Terms and conditions section description
  ///
  /// In en, this message translates to:
  /// **'Read the terms and conditions of use.'**
  String get termsDescription;

  /// Text for Spanish language
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Text for English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Logout dialog body message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutBody;

  /// Title for editing
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String editTitle(Object field);

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Phone hint
  ///
  /// In en, this message translates to:
  /// **'9 1234 5678'**
  String get phoneHint;

  /// Personal information section
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get personalInfo;

  /// Location section
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get location;

  /// Preferences section
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No options message
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get noOptions;

  /// Missing region selection message
  ///
  /// In en, this message translates to:
  /// **'You must first select a Region.'**
  String get selectFirstRegion;

  /// Select title
  ///
  /// In en, this message translates to:
  /// **'Select {field}'**
  String selectTitle(Object field);

  /// Profile updated message
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(Object error);

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Explore button or text
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Navigation state
  ///
  /// In en, this message translates to:
  /// **'Navigating'**
  String get navigating;

  /// Instruction to select point on map
  ///
  /// In en, this message translates to:
  /// **'Select a point'**
  String get selectPoint;

  /// Button to start trip
  ///
  /// In en, this message translates to:
  /// **'START TRIP'**
  String get startTrip;

  /// Walking transport mode
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// Bicycle transport mode
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bicycling;

  /// Car transport mode
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get driving;

  /// Waiting for GPS message
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal...'**
  String get waitingGps;

  /// GPS offline status
  ///
  /// In en, this message translates to:
  /// **'GPS Offline'**
  String get gpsOffline;

  /// Online status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Arrival at destination message
  ///
  /// In en, this message translates to:
  /// **'You have arrived!'**
  String get arrived;

  /// Distance to next turn
  ///
  /// In en, this message translates to:
  /// **'{distance} to turn'**
  String distanceToTurn(Object distance);

  /// Remaining travel time
  ///
  /// In en, this message translates to:
  /// **'{duration} remaining'**
  String durationRemaining(Object duration);

  /// Estimated arrival time
  ///
  /// In en, this message translates to:
  /// **'Arrival: {time}'**
  String arrivalTime(Object time);

  /// Label for distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Label for duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Label for estimated arrival time
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// Instruction for navigation turn
  ///
  /// In en, this message translates to:
  /// **'Turn'**
  String get turn;

  /// Indicates the next turn on the map
  ///
  /// In en, this message translates to:
  /// **'Next turn'**
  String get nextTurn;

  /// Unit of distance in meters
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// Unit of distance in kilometers
  ///
  /// In en, this message translates to:
  /// **'kilometers'**
  String get kilometers;

  /// Unit of time in minutes
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Unit of time in seconds
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// Message when locations cannot be fetched
  ///
  /// In en, this message translates to:
  /// **'Error fetching locations'**
  String get errorFetchingLocations;

  /// Label indicating the user's location
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// Message when no route is found
  ///
  /// In en, this message translates to:
  /// **'No route found'**
  String get noRouteFound;

  /// Message when there is a connection error
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// Message when an error occurs calculating the route
  ///
  /// In en, this message translates to:
  /// **'Route error'**
  String get routeError;

  /// Message when an error occurs while finding the email
  ///
  /// In en, this message translates to:
  /// **'Email not found'**
  String get emailNotFound;

  /// Message when an error occurs while sending the recovery email
  ///
  /// In en, this message translates to:
  /// **'Send recovery email'**
  String get resetPasswordEmailSent;

  /// Message when an error occurs while sending the recovery email
  ///
  /// In en, this message translates to:
  /// **'Send recovery email'**
  String get passwordResetSent;

  /// Mensaje cuando ocurre un error al enviar el correo de recuperación
  ///
  /// In en, this message translates to:
  /// **'No se pudo enviar el correo de recuperación'**
  String get error;

  /// Message for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// Title for password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Body text for password reset confirmation
  ///
  /// In en, this message translates to:
  /// **'We will send a password reset link to'**
  String get resetPasswordBody;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
