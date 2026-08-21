import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/app/main_navigation.dart';
import 'package:fintech_wallet/features/authentication/presentation/screen/login_screen.dart';
import 'package:fintech_wallet/shared/widgets/custom_button.dart';
import 'package:fintech_wallet/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool agreeTerms = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }

      if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Registration failed')),
        );
      }
    });
  }

  Future<void> register() async {
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    await ref
        .read(authProvider.notifier)
        .register(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          password: password,
          passwordConfirmation: confirmPassword,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Resgister'),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        width: double.infinity,
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nova Pay',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              Text(
                "Let's get you started",
                style: TextStyle(fontSize: 12, color: AppColors.surface),
              ),
              Text(
                'Nova Pay',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      prefixIcon: Icons.person,
                      controller: nameController,
                      hinText: 'Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      prefixIcon: Icons.email,
                      controller: emailController,
                      hinText: 'Email',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      prefixIcon: Icons.lock,
                      controller: passwordController,
                      hinText: 'Password',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Confirm password',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      prefixIcon: Icons.lock,
                      controller: confirmPasswordController,
                      hinText: 'Confirm Password',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                    ),
                    // SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: CheckboxListTile(
                        // checkColor: AppColors.surface,
                        value: agreeTerms,
                        onChanged: (value) {
                          setState(() {
                            agreeTerms = value!;
                          });
                        },
                        fillColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 15, 100, 228),
                        ),
                        // checkColor: Colors.purple,
                        side: BorderSide.none,
                        title: Text(
                          'I agree to the Terms & Conditions',
                          style: TextStyle(color: AppColors.surface),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    CustomButton(
                      text: authState.status == AuthStatus.loading
                          ? 'Creating account...'
                          : 'Create Account',
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : register,
                      backgroundColor: const Color.fromARGB(255, 7, 143, 255),
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 7, 143, 255),
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
