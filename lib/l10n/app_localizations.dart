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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// Title for the 'What is NutriMap' section on onboarding
  ///
  /// In en, this message translates to:
  /// **'What Is NutriMap?'**
  String get sectionWhatIs;

  /// Description for the 'What is NutriMap' section
  ///
  /// In en, this message translates to:
  /// **'NutriMap helps you track your meals, nutrition, and healthy habits.'**
  String get sectionWhatIsDesc;

  /// Title for the 'How It Helps You' section
  ///
  /// In en, this message translates to:
  /// **'How It Helps You?'**
  String get sectionHelps;

  /// Description for the 'How It Helps You' section
  ///
  /// In en, this message translates to:
  /// **'Plan meals, count calories, monitor nutrients, and improve your diet.'**
  String get sectionHelpsDesc;

  /// Title for the 'Who We Are' section
  ///
  /// In en, this message translates to:
  /// **'Who We Are?'**
  String get sectionWhoWeAre;

  /// Description for the 'Who We Are' section
  ///
  /// In en, this message translates to:
  /// **'We are a team passionate about nutrition and technology.'**
  String get sectionWhoWeAreDesc;

  /// Title for the 'Benefits' section
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get sectionBenefits;

  /// Description for the 'Benefits' section
  ///
  /// In en, this message translates to:
  /// **'Stay healthy, eat better, and reach your goals easily.'**
  String get sectionBenefitsDesc;

  /// Title for the login screen
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginTitle;

  /// Label for the email input field on the login screen
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for the password input field on the login screen
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Text for the login button
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// Text for the next button in multi-step flows
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Label for the Home tab in the BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Label for the Map tab in the BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Label for the Benefits tab in the BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// Label for the Commerce tab in the BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Commerce'**
  String get recipes;

  /// Label for the Settings tab in the BottomNavigationBar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Welcome text below the title on the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Validation message when the email field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get emailRequired;

  /// Validation message when the email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// Validation message when the password field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get passwordRequired;

  /// Validation message when the password is shorter than 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get passwordTooShort;

  /// Link/button to recover a forgotten password
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Separator text for social media login options
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Text prompting users to sign up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Text for the registration button/link
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// Generic error message when login fails
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginError;

  /// Error message when the user does not exist
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// Error message when the password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// Error message when the entered email is not valid
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailError;

  /// Placeholder text for an email field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Validation message when the password field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get enterPassword;

  /// Validation message when the password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get shortPassword;

  /// Text showing which user's settings are being displayed
  ///
  /// In en, this message translates to:
  /// **'Settings for {email}'**
  String settingsUser(Object email);

  /// Button text to log out the current user
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Default placeholder for a user's name or email
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Text showing available benefits for the current user
  ///
  /// In en, this message translates to:
  /// **'Benefits available for {email}'**
  String benefitsUser(Object email);

  /// Title of the registration screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Title for Step 1 of registration
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get registerStep1Title;

  /// Title for Step 2 of registration (Email and Password)
  ///
  /// In en, this message translates to:
  /// **'Account Credentials'**
  String get registerStep2Title;

  /// Title for Step 3 of registration
  ///
  /// In en, this message translates to:
  /// **'Institution and Preferences'**
  String get registerStep3Title;

  /// Title of the summary screen before creating an account
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// Label for the first name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Label for the last name field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Label for selecting the user's institution
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// Label for selecting preferred diets
  ///
  /// In en, this message translates to:
  /// **'Preferred Diets'**
  String get dietas;

  /// Helper text for the diet selection
  ///
  /// In en, this message translates to:
  /// **'Choose your diets'**
  String get chooseDiet;

  /// Validation message when the first name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name.'**
  String get enterName;

  /// Validation message when the last name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name.'**
  String get enterLastName;

  /// Button to go to the previous step
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Button to go to the next step
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Button to confirm and create the account
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// Error message when user registration fails
  ///
  /// In en, this message translates to:
  /// **'Could not register user.'**
  String get registerError;

  /// Shows a summary of user information before creating the account
  ///
  /// In en, this message translates to:
  /// **'Review your information: {email}'**
  String summaryUser(Object email);

  /// Label prompting the user to select their institution
  ///
  /// In en, this message translates to:
  /// **'Select your institution'**
  String get selectInstitution;

  /// Title of the personal information step
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalData;

  /// Step to select preferred diets
  ///
  /// In en, this message translates to:
  /// **'Preferred Diets'**
  String get diets;

  /// Title of the confirmation dialog before creating the account
  ///
  /// In en, this message translates to:
  /// **'Confirm Registration'**
  String get confirmRegistration;

  /// Button to cancel the confirmation
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button to create the account after confirmation
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// General error message when account creation fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get registrationError;

  /// Message shown when the email is already registered
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailInUse;

  /// Validation message for the first name input
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name.'**
  String get enterFirstName;

  /// Label for the user's phone number
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// Title for a section with other settings
  ///
  /// In en, this message translates to:
  /// **'Other Settings'**
  String get otherSettings;

  /// Title for the user profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// User's last name
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get surname;

  /// User's national identification number
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get rut;

  /// User's region or state
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// User's city, town, or local administrative district
  ///
  /// In en, this message translates to:
  /// **'City / Municipality'**
  String get commune;

  /// User's selected diet type
  ///
  /// In en, this message translates to:
  /// **'Diet Type'**
  String get diet;

  /// Title of the user profile screen
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// Title of the main/home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Title of the main Commerce
  ///
  /// In en, this message translates to:
  /// **'Commerce'**
  String get commerce;

  /// Error message when the user is disabled in Firebase
  ///
  /// In en, this message translates to:
  /// **'User disabled'**
  String get userDisabled;

  /// Error message when the login attempt limit is exceeded in Firebase
  ///
  /// In en, this message translates to:
  /// **'Too many attempts, try again later'**
  String get tooManyRequests;

  /// Error message when the network connection fails during login
  ///
  /// In en, this message translates to:
  /// **'Network error, check your connection'**
  String get networkError;

  /// Title of the password recovery screen
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// Explanatory message on the password recovery screen
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password'**
  String get forgotPasswordDescription;

  /// Button text to send password reset link
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Confirmation message when the reset email has been sent
  ///
  /// In en, this message translates to:
  /// **'Password reset email has been sent'**
  String get resetEmailSent;

  /// Error message when the reset email could not be sent
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get resetEmailFailed;

  /// Explanatory message on the registration screen
  ///
  /// In en, this message translates to:
  /// **'Create your account by entering your details'**
  String get registerDescription;

  /// Label for the user's name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Button text to complete registration
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Title of the confirmation dialog before logging out
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmationTitle;

  /// Dialog message indicating that the session will be logged out
  ///
  /// In en, this message translates to:
  /// **'Your session will be closed in the app.'**
  String get logoutConfirmationMessage;

  /// Message shown when an error occurs while trying to log out
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String get logoutError;
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
