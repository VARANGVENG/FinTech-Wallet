import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/register_page.dart';
import 'package:fintech_wallet/shared/widgets/custom_button.dart';
import 'package:fintech_wallet/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  void login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // print('Email: $email');
    // print('Password: $password');

    // TODO: Call API here
  }

  void signinwithgamil() {}

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.textPrimary,
      appBar: AppBar(backgroundColor: AppColors.background),
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
                'Wellcome back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              Text(
                'Nova Pay',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomTextField(
                      controller: emailController,
                      // label: 'Email',
                      hinText: '',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.surface,
                            ),
                          ),
                          Text(
                            'Forgot?',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 7, 143, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomTextField(
                      controller: passwordController,
                      hinText: '',
                      // label: 'Password',
                      obscureText: true,
                      prefixIcon: Icons.password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 100),
                    CustomButton(
                      textColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      text: 'Sgin in',
                      onPressed: login,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey, thickness: 1),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    CustomButton(
                      text: 'Sign in with Email',
                      onPressed: signinwithgamil,
                      bordersideColor: Colors.white,
                    ),
                    SizedBox(height: 60),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Resgiter",
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
