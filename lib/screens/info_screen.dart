import 'package:flutter/material.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showLanguageSelection = true;

  final List<IconData> _icons = [
    Icons.help_outline_rounded,
    Icons.assistant_rounded,
    Icons.group_rounded,
    Icons.emoji_events_rounded,
  ];

  Widget _buildLanguageSelection() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade800,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Choose your language\nElige tu idioma',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                _buildLanguageButton(
                  'Español',
                  '🇪🇸',
                  () => _selectLanguage(const Locale('es')),
                ),
                const SizedBox(height: 16),
                _buildLanguageButton(
                  'English',
                  '🇺🇸',
                  () => _selectLanguage(const Locale('en')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String text, String flag, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(Locale locale) {
    widget.onLocaleChange(locale);
    setState(() {
      _showLanguageSelection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLanguageSelection) {
      return _buildLanguageSelection();
    }

    final local = AppLocalizations.of(context)!;

    final List<Map<String, String>> sections = [
      {'title': local.sectionWhatIs, 'desc': local.sectionWhatIsDesc},
      {'title': local.sectionHelps, 'desc': local.sectionHelpsDesc},
      {'title': local.sectionWhoWeAre, 'desc': local.sectionWhoWeAreDesc},
      {'title': local.sectionBenefits, 'desc': local.sectionBenefitsDesc},
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade800,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language selector button in top right
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'es')
                        widget.onLocaleChange(const Locale('es'));
                      if (value == 'en')
                        widget.onLocaleChange(const Locale('en'));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'es',
                        child: Row(
                          children: [
                            Text('🇪🇸'),
                            SizedBox(width: 8),
                            Text('Español'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Text('🇺🇸'),
                            SizedBox(width: 8),
                            Text('English'),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.language_rounded,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

              // Main content
              PageView.builder(
                controller: _pageController,
                itemCount: sections.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(40, 80, 40, 120),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _icons[index],
                            size: 70,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          section['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          section['desc']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Bottom controls
              Positioned(
                bottom: 40,
                left: 40,
                right: 40,
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        sections.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next/Finish button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo.shade800,
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (_currentPage < sections.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
      ),
    );
  }
}
