import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/login_page.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.background),
      body: Container(
        width: double.infinity,

        // height: 200,
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              // InkWell(
              //   borderRadius: BorderRadius.circular(100),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => LoginPage()),
              //     );
              //   },
              // ),
              Row(
                children: [
                  CircleAvatar(radius: 25),
                  SizedBox(width: 10),
                  Text(
                    'Hello, Alex',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(Icons.notifications, color: AppColors.surface),
                  // ClipOval(
                  //   child: Image.asset(
                  //     'assets/images/profile.png',
                  //     width: 100,
                  //     height: 100,
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
