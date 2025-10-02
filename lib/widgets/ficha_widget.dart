// FILE: lib/widgets/ficha_widget.dart
import 'package:flutter/material.dart';
import '../models/ficha.dart';

class FichaWidget extends StatelessWidget {
  final DominoPiece ficha;
  final double width;
  final bool isHorizontal;
  final bool isSelected;
  final VoidCallback? onTap;

  const FichaWidget({
    super.key,
    required this.ficha,
    this.width = 50,
    this.isHorizontal = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? width * 2 : width,
        height: isHorizontal ? width : width * 2,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.black54,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isHorizontal
            ? Row(children: _buildHalves())
            : Column(children: _buildHalves()),
      ),
    );
  }

  List<Widget> _buildHalves() {
    return [
      Expanded(child: _PipGrid(value: ficha.a)),
      Container(
        width: isHorizontal ? 2 : double.infinity,
        height: isHorizontal ? double.infinity : 2,
        color: Colors.black54,
        margin: isHorizontal
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 6),
      ),
      Expanded(child: _PipGrid(value: ficha.b)),
    ];
  }
}

class _PipGrid extends StatelessWidget {
  final int value;
  const _PipGrid({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildPip(index);
        },
      ),
    );
  }

  Widget? _buildPip(int index) {
    bool isVisible = false;
    switch (value) {
      case 1:
        if (index == 4) isVisible = true;
        break;
      case 2:
        if (index == 0 || index == 8) isVisible = true;
        break;
      case 3:
        if (index == 0 || index == 4 || index == 8) isVisible = true;
        break;
      case 4:
        if (index == 0 || index == 2 || index == 6 || index == 8) isVisible = true;
        break;
      case 5:
        if (index == 0 || index == 2 || index == 4 || index == 6 || index == 8) isVisible = true;
        break;
      case 6:
        if (index == 0 || index == 2 || index == 3 || index == 5 || index == 6 || index == 8) isVisible = true;
        break;
    }

    return isVisible
        ? Container(
      margin: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    )
        : null;
  }
}
