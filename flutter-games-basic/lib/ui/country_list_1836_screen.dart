import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CountryList1836Screen extends StatelessWidget {
  const CountryList1836Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('1836 Scenario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/scenarios'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple placeholder for the 1836 scenario country list
            const Text(
              '1836 Scenario',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'MPLUS Rounded 1c',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Countries list will appear here',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'MPLUS Rounded 1c',
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
} 