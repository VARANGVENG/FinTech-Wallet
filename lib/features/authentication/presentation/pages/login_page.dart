import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        // backgroundColor: const Color.fromARGB(255, 141, 82, 180),
        // leading: Icon(Icons.back_hand_sharp),
        // title: Center(
        //   child: Text(
        //     'Fintech Wallet',
        //     style: TextStyle(color: Colors.black, fontSize: 24),
        //   ),
        // ),
        // actions: [Icon(Icons.back_hand_sharp)],
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(color: Colors.blue, width: 500),
              Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 40),
                child: Positioned(
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.white,
                  ),
                ),
                // Icon(Icons.access_alarm)
              ),
            ],
          ),
        ],
      ),
    );
  }
}
