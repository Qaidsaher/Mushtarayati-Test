import 'package:flutter/material.dart';
// no Get usage here

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Saher Kit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('تطبيق لإدارة الفروع والقوائم.\nتم التطوير بواسطة فريق المطورين.'),
            SizedBox(height: 16),
            Text('اتصل بالمطور: dev@example.com')
          ],
        ),
      ),
    );
  }
}
