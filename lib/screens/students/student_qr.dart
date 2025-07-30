import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_app/screens/encuesta_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _verificarEncuesta(String code) async {
    final doc = await FirebaseFirestore.instance
        .collection('encuestas')
        .doc(code)
        .get();

    final encuesta = doc.data();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR detectado'),
        content: Text(encuesta != null
            ? 'Encuesta encontrada: ${encuesta['titulo']}'
            : 'No se encontró ninguna encuesta con ese ID.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogShown = false;

              if (encuesta != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EncuestaScreen(id: code),
                  ),
                );
              } else {
                controller.start();
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture barcode) {
    final String? code = barcode.barcodes.first.rawValue;

    if (code != null && !_dialogShown) {
      controller.stop();
      _dialogShown = true;
      _verificarEncuesta(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanea una encuesta')),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
      ),
    );
  }
}
