import 'package:fintech_wallet/features/dashboard/presentation/page/home_dashboard.dart';
import 'package:fintech_wallet/shared/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  late final List<Widget> page;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    page = [HomeDashboard()
    
    ];
  }

  void changePage(int index) {
    if (index == 2) {
      return;
    }
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: page[currentIndex],
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: currentIndex,
        onTap: changePage,
      ),
    );
  }
}
