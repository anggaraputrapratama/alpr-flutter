import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picture_camera_model/bottom_sheet.dart';

import 'package:picture_camera_model/main.dart';
import 'package:picture_camera_model/renderBoxImage.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as ImageLib;

class DetectImageCamera extends StatefulWidget {
  const DetectImageCamera({super.key});

  @override
  State<DetectImageCamera> createState() => _DetectImageCameraState();
}

class _DetectImageCameraState extends State<DetectImageCamera> {
  late CameraController _controller;
  File? image, ContrastImage, im2;
  late ModelObjectDetection _objectModel;
  List<ResultObjectDetection?> objDetect = [];
  Map<String, Object?>? data;
  bool dataResult = false;
  final List<String> _prediction = [];
  List<dynamic> cek = [];
  List<dynamic> cekLefts = [];

  @override
  void initState() {
    super.initState();

    _controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    loadModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeCamera() async {
    _controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  Future loadModel() async {
    // String pathPlateDetection = 'assets/models/';
    String pathObjectDetectionModel =
        'assets/models/alpha_numeric_v1.torchscript';
    try {
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectDetectionModel, 36, 640, 640,
          labelPath: "assets/models/labels_alpha_numeric.txt");
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('only supported for android, Error is $e');
      } else {
        debugPrint('Error is $e');
      }
    }
  }

  Future runObjDetect() async {
    final XFile file = await _controller.takePicture();
    ContrastImage = File(file.path);

    ImageLib.Image? contrast =
        ImageLib.decodeImage(ContrastImage!.readAsBytesSync());
    contrast = ImageLib.copyRotate(contrast!, 90);
    ContrastImage!.writeAsBytesSync(ImageLib.encodeJpg(contrast));
    setState(() {
      image = ContrastImage;
    });

    objDetect = (await _objectModel.getImagePrediction(
            await image!.readAsBytes(),
            minimumScore: 0.1,
            IOUThershold: 0.2))
        .cast<ResultObjectDetection?>();

    // for (var i in objDetect) {
    //   print(i!.className);
    //   print(i.rect.left);
    // }

    cekLefts = objDetect.map((e) {
      if (e!.rect.top >= 0 && e.rect.bottom <= 0.5) {
        return e.rect.left;
      }
    }).toList();
    cek = objDetect.map((e) {
      if (e!.rect.top >= 0 && e.rect.bottom <= 0.5) {
        return ({
          'classNames': e.className,
          'left': e.rect.left,
        });
      }
    }).toList();
    // for (var i in cek) {
    //   print(i);
    // }

    setState(() {
      dataResult = true;
    });
  }

  void processImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int numChannels = image.planes.length;
    final List<Uint8List> data = image.planes.map((e) => e.bytes).toList();
    // ... Do something with the image data

    print({
      'width': width,
      'height': height,
      'numChannels': numChannels,
      'data': data,
    });
  }

  bool flash = false;

  @override
  Widget build(BuildContext context) {
    Map<String, double> ratios = {
      '1:1': 1 / 1,
      '9:16': 9 / 16,
      '3:4': 3 / 4,
      '9:21': 9 / 21,
      'full': MediaQuery.of(context).size.aspectRatio,
    };
    final size = MediaQuery.of(context).size;
    if (!_controller.value.isInitialized) {
      return Container();
    }
    // cek.asMap().forEach((key, value) {
    //   print('key: $key, value: $value');
    //   // if (value != null) {
    //   //   print('key: $key, value: $value');
    //   // }
    // });

    for (var i in objDetect) {
      print('hasil Names ${i!.className} }');
      print('hasil score ${i.score} ');
      print('hasil left ${i.rect.left}');
      print('hasil left ${i.rect.top}');
      print('hasil left ${i.rect.bottom}');
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: image == null
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    flash = !flash;
                    flash
                        ? _controller.setFlashMode(FlashMode.off)
                        : _controller.setFlashMode(FlashMode.always);
                  });
                },
                child: Icon(
                  flash ? Icons.flash_off_sharp : Icons.flash_on_sharp,
                  color: Colors.white,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: Stack(
        children: [
          image == null
              ? CameraPreview(_controller)
              : !kDebugMode
                  ? Image.file(
                      image!,
                    )
                  : GridTile(child: renderBoxImage(image!, objDetect)),
          BottomSheetCustom(
              size: size,
              onRetakePicture: () {
                setState(() {
                  image = null;
                  dataResult = false;
                });
              },
              onTakePicture: () async {
                setState(() {
                  image = null;
                  dataResult = false;
                });
                await runObjDetect();
              },
              dataResult: true,
              itemCount: objDetect.length,
              itemBuilder: (context, index) {
                return Center(
                    child: Text(
                  objDetect[index]!.className.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 20),
                ));
              }),
        ],
      ),
    );
  }
}
