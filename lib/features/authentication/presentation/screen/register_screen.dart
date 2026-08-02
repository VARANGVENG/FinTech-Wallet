import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/login_page.dart';
import 'package:fintech_wallet/shared/widgets/custom_button.dart';
import 'package:fintech_wallet/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool agreeTerms = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void register() {
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Check if passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // print('Name: $name');
    // print('Email: $email');
    // print('Password: $password');

    // TODO: Call Register API here
  }

  @override
  Widget build(BuildContext context) {
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
                      text: 'Create Account',
                      onPressed: register,
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
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
