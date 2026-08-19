import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
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

    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: SafeRouteColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Logo + Brand
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'saferoute_logo',
                        child: Image.asset(
                          'assets/images/saferoute_logo.png',
                          width: 160,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_bus,
                            color: SafeRouteColors.blue,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SafeRoute',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: SafeRouteColors.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every Child. Every Mile. Safely.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SafeRouteColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

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
                          'Sign In',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: SafeRouteColors.deepNavy,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your username, mobile number, or email.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),

                        // Identifier Field (username / phone / email)
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Username, Mobile or Email',
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'e.g. superadmin or +919876543210',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your username, mobile, or email';
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
                            labelText: 'Password',
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
                              return 'Please enter your password';
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
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
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
  }
}
