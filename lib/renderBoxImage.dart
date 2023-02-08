import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pytorch_lite/pigeon.dart';

Widget renderBoxImage(
    File? image, List<ResultObjectDetection?> extractPlateDetect) {
  return LayoutBuilder(builder: (context, constraints) {
    debugPrint(
        'Max height: ${constraints.maxHeight}, max width: ${constraints.maxWidth}');
    double factorX = constraints.maxWidth;
    double factorY = constraints.maxHeight;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: factorX,
          // height: factorY - 180,
          child: Container(
              child: Image.file(
            image!,
          )),
        ),
        ...extractPlateDetect.map((re) {
          if (re == null) {
            return Container();
          }
          Color usedColor;

          usedColor = Colors.primaries[
              ((re.className ?? re.classIndex.toString()).length +
                      (re.className ?? re.classIndex.toString()).codeUnitAt(0) +
                      re.classIndex) %
                  Colors.primaries.length];

          return Positioned(
            left: re.rect.left * factorX,
            top: re.rect.top * factorY - 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  alignment: Alignment.centerRight,
                  color: usedColor,
                  child: Text(
                      "${re.className ?? re.classIndex.toString()}_${(re.score * 100).toStringAsFixed(2)}%"),
                ),
                Container(
                  width: re.rect.width.toDouble() * factorX,
                  height: re.rect.height.toDouble() * (factorY - 50),
                  decoration: BoxDecoration(
                      border: Border.all(color: usedColor, width: 3),
                      borderRadius: const BorderRadius.all(Radius.circular(2))),
                  child: Container(),
                ),
              ],
            ),
          );
        }).toList()
      ],
    );
  });
}
