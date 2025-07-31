import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrScreen extends StatelessWidget {
  final String encuestaId;

  const QrScreen({super.key, required this.encuestaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código QR de la Encuesta')),
      body: Center(
        child: QrImageView(
          data: encuestaId,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
}