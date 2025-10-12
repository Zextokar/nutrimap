// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get sectionWhatIs => '¿Qué es NutriMap?';

  @override
  String get sectionWhatIsDesc =>
      'NutriMap te ayuda a seguir tus comidas, nutrición y hábitos saludables.';

  @override
  String get sectionHelps => '¿Qué te ayudará a hacer?';

  @override
  String get sectionHelpsDesc =>
      'Planificar comidas, contar calorías, controlar nutrientes y mejorar tu dieta.';

  @override
  String get sectionWhoWeAre => '¿Quiénes somos?';

  @override
  String get sectionWhoWeAreDesc =>
      'Somos un equipo apasionado por la nutrición y la tecnología.';

  @override
  String get sectionBenefits => 'Beneficios';

  @override
  String get sectionBenefitsDesc =>
      'Mantente saludable, come mejor y alcanza tus metas fácilmente.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get loginButton => 'Ingresar';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get home => 'Inicio';

  @override
  String get map => 'Mapa';

  @override
  String get benefits => 'Beneficios';

  @override
  String get recipes => 'Comercio';

  @override
  String get settings => 'Configuración';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get emailRequired => 'Por favor, ingresa tu correo electrónico.';

  @override
  String get invalidEmail => 'Ingresa un correo electrónico válido.';

  @override
  String get passwordRequired => 'Por favor, ingresa tu contraseña.';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get orContinueWith => 'O continúa con';

  @override
  String get noAccount => '¿No tienes una cuenta?';

  @override
  String get register => 'Regístrate';

  @override
  String get loginError => 'Error al iniciar sesión.';

  @override
  String get userNotFound => 'Usuario no encontrado.';

  @override
  String get wrongPassword => 'Contraseña incorrecta.';

  @override
  String get invalidEmailError => 'Formato de correo inválido.';

  @override
  String get enterEmail => 'Ingresa tu email.';

  @override
  String get enterPassword => 'Por favor, ingresa tu contraseña.';

  @override
  String get shortPassword => 'La contraseña debe tener al menos 6 caracteres.';

  @override
  String settingsUser(Object email) {
    return 'Configuraciones de $email';
  }

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get user => 'Usuario';

  @override
  String benefitsUser(Object email) {
    return 'Beneficios disponibles para $email';
  }

  @override
  String get registerTitle => 'Registro';

  @override
  String get registerStep1Title => 'Datos Personales';

  @override
  String get registerStep2Title => 'Email y Contraseña';

  @override
  String get registerStep3Title => 'Institución y Preferencias';

  @override
  String get summaryTitle => 'Resumen';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get institution => 'Institución';

  @override
  String get dietas => 'Dietas Preferidas';

  @override
  String get chooseDiet => 'Elige tus dietas';

  @override
  String get enterName => 'Por favor, ingresa tu nombre.';

  @override
  String get enterLastName => 'Por favor, ingresa tu apellido.';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get registerError => 'Error al registrar el usuario.';

  @override
  String summaryUser(Object email) {
    return 'Revisa tus datos: $email';
  }

  @override
  String get selectInstitution => 'Selecciona tu institución';

  @override
  String get personalData => 'Datos Personales';

  @override
  String get diets => 'Dietas';

  @override
  String get confirmRegistration => 'Confirme su registro';

  @override
  String get cancel => 'Cancelar';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get registrationError => 'Error al registrar usuario.';

  @override
  String get emailInUse => 'El correo ya está en uso.';

  @override
  String get enterFirstName => 'Por favor, ingrese su nombre.';

  @override
  String get phone => 'Teléfono';

  @override
  String get otherSettings => 'Otros ajustes';

  @override
  String get profile => 'Perfil';

  @override
  String get surname => 'Apellido';

  @override
  String get rut => 'RUT';

  @override
  String get region => 'Región';

  @override
  String get commune => 'Comuna';

  @override
  String get diet => 'Tipo de dieta';

  @override
  String get userProfile => 'Perfil del usuario';

  @override
  String get homeTitle => 'Inicio';
}
