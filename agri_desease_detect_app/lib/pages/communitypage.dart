import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  void _showContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contacter un assistant agricole',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.email, color: Color(0xFF15803D)),
                title: Text('Email : kalanelogitiel@gmail.com'),
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF15803D)),
                title: const Text('Téléphone : +226 68 11 61 91'),
                onTap: () async {
                  await FlutterPhoneDirectCaller.callNumber("+22668116191");
                },
              ),
              const ListTile(
                leading: Icon(Icons.message, color: Color(0xFF15803D)),
                title: Text('WhatsApp : +226 57 98 94 67'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Communauté'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue dans la Communauté Agricole !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Accédez à de l’aide, posez vos questions, ou contactez un spécialiste.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showContactModal(context),
              icon: const Icon(Icons.support_agent),
              label: const Text('Contacter un assistant agricole'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '❓ FAQ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ExpansionTile(
                    title: Text('Comment utiliser le diagnostic ?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Prenez une photo de votre plante, et laissez lapplication analyser les maladies possibles.',
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Comment contacter un expert ?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Vous pouvez contacter un expert via téléphone, WhatsApp ou email en utilisant le bouton ci-dessus.',
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Comment rejoindre la communauté ?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Nous travaillons à lancer une plateforme communautaire. Restez connectés !',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}