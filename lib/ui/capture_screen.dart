import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

Uint8List cropImage(Map<String, Object> args) {
  final decoded = img.decodeImage(args['bytes'] as Uint8List);
  if (decoded == null) {
    throw const FormatException('Unsupported image. Choose a JPEG or PNG.');
  }
  final upright = img.bakeOrientation(decoded);
  final r = args['rect'] as List<double>;
  final cropped = img.copyCrop(
    upright,
    x: (r[0] * upright.width).round(),
    y: (r[1] * upright.height).round(),
    width: ((r[2] - r[0]) * upright.width).round().clamp(1, upright.width),
    height: ((r[3] - r[1]) * upright.height).round().clamp(1, upright.height),
  );
  final output = cropped.width > 1800
      ? img.copyResize(cropped, width: 1800)
      : cropped;
  return Uint8List.fromList(img.encodeJpg(output, quality: 92));
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  String? error;
  bool busy = false, flash = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  Future<void> init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera found. Import a receipt from your gallery.');
      }
      final c = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
      controller = c;
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => error = null);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = 'Camera unavailable. Allow camera access in Settings, or import a photo.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final c = controller;
      controller = null;
      c?.dispose();
    }
    if (state == AppLifecycleState.resumed && controller == null) init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  Future<void> take({bool gallery = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final XFile? file = gallery
          ? await ImagePicker().pickImage(source: ImageSource.gallery)
          : await controller?.takePicture();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final result = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => CropScreen(bytes: bytes)),
      );
      if (result != null && mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not read photo: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF142D25),
    appBar: AppBar(
      title: const Text('Scan receipt'),
      backgroundColor: const Color(0xFF142D25),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Toggle flash',
          onPressed: controller?.value.isInitialized == true
              ? () async {
                  try {
                    await controller!.setFlashMode(
                      flash ? FlashMode.off : FlashMode.torch,
                    );
                    setState(() => flash = !flash);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Flash is not supported by this camera.',
                          ),
                        ),
                      );
                    }
                  }
                }
              : null,
          icon: Icon(flash ? Icons.flash_on : Icons.flash_off),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Keep the receipt flat and well lit.\nTap to focus. Crop precisely on the next screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: controller?.value.isInitialized == true
                  ? LayoutBuilder(
                      builder: (context, box) => GestureDetector(
                        onTapDown: (d) async {
                          try {
                            await controller?.setFocusPoint(
                              Offset(
                                (d.localPosition.dx / box.maxWidth).clamp(0, 1),
                                (d.localPosition.dy / box.maxHeight).clamp(
                                  0,
                                  1,
                                ),
                              ),
                            );
                          } catch (_) {}
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(controller!),
                            IgnorePointer(
                              child: CustomPaint(painter: FramePainter()),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Import receipt',
                onPressed: busy ? null : () => take(gallery: true),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              FilledButton(
                onPressed: busy || controller?.value.isInitialized != true
                    ? null
                    : () => take(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDDF4A6),
                  foregroundColor: const Color(0xFF142D25),
                  padding: const EdgeInsets.all(22),
                ),
                child: busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                    : const Icon(Icons.camera_alt, size: 32),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    ),
  );
}

class FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(
      size.width * .08,
      size.height * .06,
      size.width * .84,
      size.height * .88,
    );
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  double left = 0, right = 1, top = 0, bottom = 1;
  bool busy = false;
  late final decoded = img.decodeImage(widget.bytes);
  double get aspectRatio {
    if (decoded == null) return 1;
    final upright = img.bakeOrientation(decoded!);
    return upright.width / upright.height;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crop your receipt')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.bytes, fit: BoxFit.contain),
                      CustomPaint(
                        painter: CropOverlay(
                          Rect.fromLTRB(left, top, right, bottom),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Text('Horizontal edges'),
          RangeSlider(
            values: RangeValues(left, right),
            onChanged: busy
                ? null
                : (v) {
                    if (v.end - v.start > .1) {
                      setState(() {
                        left = v.start;
                        right = v.end;
                      });
                    }
                  },
          ),
          const Text('Vertical edges'),
          RangeSlider(
            values: RangeValues(top, bottom),
            onChanged: busy
                ? null
                : (v) {
                    if (v.end - v.start > .1) {
                      setState(() {
                        top = v.start;
                        bottom = v.end;
                      });
                    }
                  },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final result = await compute(cropImage, {
                          'bytes': widget.bytes,
                          'rect': [left, top, right, bottom],
                        });
                        if (context.mounted) Navigator.pop(context, result);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('$e')));
                          setState(() => busy = false);
                        }
                      }
                    },
              icon: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.document_scanner),
              label: Text(busy ? 'Preparing image…' : 'Crop & recognize'),
            ),
          ),
        ],
      ),
    ),
  );
}

class CropOverlay extends CustomPainter {
  CropOverlay(this.selection);
  final Rect selection;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      selection.left * size.width,
      selection.top * size.height,
      selection.right * size.width,
      selection.bottom * size.height,
    );
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFDDF4A6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CropOverlay old) => old.selection != selection;
}
