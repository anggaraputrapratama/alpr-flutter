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
  late ModelObjectDetection _objectModel, licenseModel;
  List<ResultObjectDetection?> objDetect = [];
  List<ResultObjectDetection?> licenseDetect = [];
  Map<String, Object?>? data;
  bool dataResult = false;
  final List<String> _prediction = [];
  List<dynamic> cek = [];
  List<dynamic> cekLefts = [];
  String? hasilPlat;
  List<String> plat = [];
  List<Map<String, dynamic>> list_crop = [];
  String? angka;
  List<String> parts = [];
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

  Future loadModel() async {
    // String pathPlateDetection = 'assets/models/';
    String pathObjectDetectionModel =
        'assets/models/alpha_numeric_v1.torchscript';
    String pathLicenseDetectionModel = 'assets/models/best.torchscript';
    try {
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectDetectionModel, 36, 640, 640,
          labelPath: "assets/models/labels_alpha_numeric.txt");
      licenseModel = await PytorchLite.loadObjectDetectionModel(
          pathLicenseDetectionModel, 2, 416, 416,
          labelPath: "assets/models/label.txt");
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('only supported for android, Error is $e');
      } else {
        debugPrint('Error is $e');
      }
    }
  }

  Future runLicenseDetect() async {
    final XFile file = await _controller.takePicture();
    ContrastImage = File(file.path);

    ImageLib.Image? contrast =
        ImageLib.decodeImage(ContrastImage!.readAsBytesSync());
    contrast = ImageLib.copyRotate(contrast!, 90);
    ContrastImage!.writeAsBytesSync(ImageLib.encodeJpg(contrast));
    setState(() {
      image = ContrastImage;
    });

    licenseDetect = (await licenseModel.getImagePrediction(
            await image!.readAsBytes(),
            minimumScore: 0.1,
            IOUThershold: 0.45))
        .cast<ResultObjectDetection?>();
  }

  Future runObjDetect() async {
    list_crop.clear();
    plat.clear();
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

    cekLefts = objDetect.map((e) {
      return (e!.rect.left);
    }).toList();
    cek = objDetect.map((e) {
      if (e!.rect.top >= 0 && e.rect.bottom <= 0.5) {
        return (e.className);
      }
    }).toList();
    cekLefts.sort();

    var a = cekLefts.take(cek.length).toList();

    a.asMap().forEach((index, element) {
      objDetect.asMap().forEach((key, value) {
        if (value!.rect.left == element && value.score >= 0.76) {
          list_crop.add({
            'name': value.className,
            'left': value.rect.left,
            'top': value.rect.top,
            'bottom': value.rect.bottom,
            'right': value.rect.right,
          });
        }
      });
    });

    for (var i in list_crop) {
      plat.add(i['name'].toString());
    }

    setState(() {
      dataResult = true;
      hasilPlat = plat.join();
      var azs = hasilPlat!.codeUnits.where((e) => e != 13).toList();

      hasilPlat = String.fromCharCodes(azs);

      RegExp exp = RegExp(r'\d');

      parts = hasilPlat!
          .splitMapJoin(
            RegExp(r'[a-zA-Z]'),
            onMatch: (value) => '${value[0]}',
            onNonMatch: (p0) => '',
          )
          .split('');
      var numbers = hasilPlat?.splitMapJoin(exp,
          onMatch: (value) => '${value[0]}', onNonMatch: (value) => '');

      if (numbers != null) {
        angka = numbers;
      } else {
        print('Angka tidak ditemukan');
      }
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
  List<Map<String, dynamic>> listCrop = [];

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

    // ///split angka dan numeric
    // String plat1 = 'R4111SN';
    // RegExp exp = RegExp(r'\d+');
    // List<String> parts1 = hasilPlat!.split(RegExp(r'(\d+)'));

    // var match = exp.firstMatch(hasilPlat!);
    // print(plat);

    // if (match != null) {
    //   String? oke = match.group(0);
    //   print(oke); // Output: 4111
    //   print(parts1);
    // } else {
    //   print('Angka tidak ditemukan');
    // }

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
                  : GridTile(child: renderBoxImage(image!, licenseDetect)),
          BottomSheetCustom(
              size: size,
              onDetectionPlate: () async {
                setState(() {
                  image = null;
                  dataResult = false;
                });
                await runLicenseDetect();
              },
              onRetakePicture: () {
                setState(() {
                  image = null;
                  dataResult = false;
                  plat.clear();
                  hasilPlat = null;
                  list_crop.clear();
                  parts.clear();
                  angka = null;
                });
              },
              onTakePicture: () async {
                setState(() {
                  image = null;
                  dataResult = false;
                });
                await runObjDetect();
                // await runLicenseDetect();
              },
              text: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(hasilPlat == null ? '' : hasilPlat!),
                  Text(parts.isEmpty ? 'kosong' : 'Dpn:${parts.first}'),
                  Text(angka == null ? '' : angka!),
                  Text(hasilPlat == null
                      ? 'ko'
                      : 'Belakang: ${parts.last + parts[parts.length - 2]}')
                ],
              ),
              dataResult: true,
              itemCount: plat == null ? 0 : plat.length,
              itemBuilder: (context, index) {
                return Center(
                    child: Text(
                  plat[index],
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
