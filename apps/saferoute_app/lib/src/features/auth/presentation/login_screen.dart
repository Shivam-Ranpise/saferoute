import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';

/// Login screen — supports username, mobile number, or email + password.
/// No self-registration. Accounts are created by school admin.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loc = ref.watch(appLocalizationsProvider);
    final currentLocale = ref.watch(appLocaleProvider);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Top Language Switcher Bar
                Align(
                  alignment: Alignment.topRight,
                  child: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: SafeRouteColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SafeRouteColors.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 16, color: SafeRouteColors.deepNavy),
                          const SizedBox(width: 6),
                          Text(
                            currentLocale.languageCode == 'mr'
                                ? 'मराठी'
                                : currentLocale.languageCode == 'hi'
                                    ? 'हिंदी'
                                    : 'English',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: SafeRouteColors.deepNavy,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16, color: SafeRouteColors.deepNavy),
                        ],
                      ),
                    ),
                    tooltip: 'Change Language / भाषा बदला',
                    onSelected: (code) {
                      ref.read(appLocaleProvider.notifier).setLanguage(code);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                      PopupMenuItem(value: 'hi', child: Text('🇮🇳 हिंदी (Hindi)')),
                      PopupMenuItem(value: 'mr', child: Text('🇮🇳 मराठी (Marathi)')),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logo + Brand
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'saferoute_logo',
                        child: Image.asset(
                          'assets/images/saferoute_logo.png',
                          width: 150,
                          height: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_bus,
                            color: SafeRouteColors.blue,
                            size: 70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: SafeRouteColors.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SafeRouteColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Login Card
                Container(
                  decoration: BoxDecoration(
                    color: SafeRouteColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: SafeRouteColors.deepNavy.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: SafeRouteColors.outline),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loc.loginTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: SafeRouteColors.deepNavy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.loginSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),

                        // Identifier Field (username / phone / email)
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: loc.identifierLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                            hintText: loc.identifierHint,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return loc.identifierError;
                            }
                            if (value.trim().length < 3) {
                              return 'Identifier too short';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSignIn(),
                          decoration: InputDecoration(
                            labelText: loc.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.passwordError;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sign In Button
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeRouteColors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  loc.signInButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Text(
                    'Your account is provided by your school administrator.\nContact them if you need access.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SafeRouteColors.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signInWithIdentifier(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null && authState.error!.isNotEmpty) {
      final error = authState.error!;
      ref.read(authProvider.notifier).clearError();
      _showInvalidCredentialsDialog(error);
    }
  }

  void _showInvalidCredentialsDialog(String errorMessage) {
    final loc = ref.read(appLocalizationsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SafeRouteColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: SafeRouteColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.invalidCredentialsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SafeRouteColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.invalidCredentialsMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeRouteColors.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    loc.tryAgain,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
