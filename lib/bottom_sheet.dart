import 'package:flutter/material.dart';

class BottomSheetCustom extends StatefulWidget {
  final Size size;
  final void Function() onTakePicture, onRetakePicture;
  final bool dataResult;
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;
  const BottomSheetCustom(
      {super.key,
      required this.size,
      required this.onTakePicture,
      required this.onRetakePicture,
      required this.dataResult,
      required this.itemBuilder,
      required this.itemCount});

  @override
  State<BottomSheetCustom> createState() => _BottomSheetCustomState();
}

class _BottomSheetCustomState extends State<BottomSheetCustom> {
  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            width: widget.size.width,
            height: widget.size.height * 0.4,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Hasil Ektraksi Plat Nomor:',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(fontSize: 24),
                    ),
                  ),
                  Expanded(
                      child: widget.dataResult
                          ? Center(
                              child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.itemCount,
                              itemBuilder: widget.itemBuilder,
                            ))
                          : Container()),
                  Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                          onPressed: widget.onTakePicture,
                          child: const Text('Take Picture')),
                      ElevatedButton(
                          onPressed: widget.onRetakePicture,
                          child: const Text('Reset Picture/Ambil Ulang')),
                    ],
                  )),
                ],
              ),
            )));
  }
}
