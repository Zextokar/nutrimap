import 'package:flutter/material.dart';
import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/screens/info/widgets/language_option.dart';

class InfoScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final VoidCallback onFinished;

  const InfoScreen({
    super.key,
    required this.onLocaleChange,
    required this.onFinished,
  });

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  // --- PALETA DE COLORES ---
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showLanguageSelection = true;

  final List<IconData> _icons = [
    Icons.health_and_safety_rounded,
    Icons.monitor_heart_rounded,
    Icons.groups_3_rounded,
    Icons.verified_rounded,
  ];

  void _selectLanguage(Locale locale) {
    widget.onLocaleChange(locale);
    setState(() {
      _showLanguageSelection = false;
    });
  }

  Widget _buildLanguageSelection() {
    return Scaffold(
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentGreen.withOpacity(0.15),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: _secondaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentGreen.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: _accentGreen.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 50,
                      color: _accentGreen,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Bienvenido / Welcome',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona tu idioma para continuar\nSelect your language to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  LanguageOption(
                    label: 'Español',
                    flag: '🇪🇸',
                    onTap: () => _selectLanguage(const Locale('es')),
                    textColor: _textPrimary,
                    backgroundColor: _secondaryDark,
                    borderColor: _accentGreen.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  LanguageOption(
                    label: 'English',
                    flag: '🇺🇸',
                    onTap: () => _selectLanguage(const Locale('en')),
                    textColor: _textPrimary,
                    backgroundColor: _secondaryDark,
                    borderColor: _accentGreen.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLanguageSelection) return _buildLanguageSelection();

    final local = AppLocalizations.of(context)!;
    final List<Map<String, String>> sections = [
      {'title': local.sectionWhatIs, 'desc': local.sectionWhatIsDesc},
      {'title': local.sectionHelps, 'desc': local.sectionHelpsDesc},
      {'title': local.sectionWhoWeAre, 'desc': local.sectionWhoWeAreDesc},
      {'title': local.sectionBenefits, 'desc': local.sectionBenefitsDesc},
    ];

    return Scaffold(
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentGreen.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _secondaryDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _textSecondary.withOpacity(0.2),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          color: _secondaryDark,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: _textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Localizations.localeOf(
                                  context,
                                ).languageCode.toUpperCase(),
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onSelected: (value) {
                            if (value == 'es')
                              widget.onLocaleChange(const Locale('es'));
                            if (value == 'en')
                              widget.onLocaleChange(const Locale('en'));
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'es',
                              child: Text(
                                '🇪🇸 Español',
                                style: TextStyle(color: _textPrimary),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'en',
                              child: Text(
                                '🇺🇸 English',
                                style: TextStyle(color: _textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: sections.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                color: _secondaryDark,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentGreen.withOpacity(0.15),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _icons[index],
                                size: 80,
                                color: _accentGreen,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              section['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              section['desc']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          sections.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _accentGreen
                                  : _secondaryDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: _accentGreen.withOpacity(0.4),
                          ),
                          onPressed: () {
                            if (_currentPage < sections.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              widget.onFinished();
                            }
                          },
                          child: Text(
                            _currentPage == sections.length - 1
                                ? local.loginButton
                                : local.nextButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
