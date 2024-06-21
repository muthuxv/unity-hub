import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ServerAvatarGenerator {
  final String filename;

  ServerAvatarGenerator({required this.filename});

  Future<String> generate() async {
    ByteData data = await rootBundle.load(filename);
    Uint8List bytes = data.buffer.asUint8List();
    img.Image? logo = img.decodeImage(bytes);

    if (logo == null) {
      throw Exception('Impossible de charger l\'image');
    }

    img.Image resizedLogo = img.copyResize(logo, width: 150, height: 150);

    img.Image avatar = img.Image(width: 200, height: 200);

    final Random random = Random();
    final int colorStart = (random.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
    final int colorEnd = (random.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;

    int x = (avatar.width - resizedLogo.width) ~/ 2;
    int y = (avatar.height - resizedLogo.height) ~/ 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromPoints(ui.Offset.zero, const ui.Offset(200.0, 200.0)));

    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(200, 200),
        [Color(colorStart), Color(colorEnd)],
      );

    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), paint);
    canvas.drawImage(await _convertImage(resizedLogo), ui.Offset(x.toDouble(), y.toDouble()), ui.Paint());

    final picture = recorder.endRecording();
    final imgUi = await picture.toImage(200, 200);
    final pngBytes = await imgUi.toByteData(format: ui.ImageByteFormat.png);

    if (pngBytes == null) {
      throw Exception('Impossible d\'encoder l\'image au format PNG');
    }

    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    final tempFile = File('$tempPath/${Random().nextInt(10000)}.png');
    await tempFile.writeAsBytes(Uint8List.view(pngBytes.buffer));

    return tempFile.path; // Return the file path instead of the file itself
  }

  Future<ui.Image> _convertImage(img.Image image) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      image.getBytes(),
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
          (ui.Image img) {
        completer.complete(img);
      },
    );
    return completer.future;
  }
}