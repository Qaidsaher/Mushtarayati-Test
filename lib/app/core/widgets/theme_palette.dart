import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class ThemePalette extends StatelessWidget {
  const ThemePalette({super.key, this.onSelected});

  final void Function(Color)? onSelected;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: themeCtrl.availableColors.map((c) {
          final selected = c == themeCtrl.colorSeed.value;
          return GestureDetector(
            onTap: () {
              themeCtrl.setColor(c);
              if (onSelected != null) onSelected!(c);
            },
            child: Tooltip(
              message: '#${c.a.toInt().toRadixString(16).padLeft(2, '0')}${c.r.toInt().toRadixString(16).padLeft(2, '0')}${c.g.toInt().toRadixString(16).padLeft(2, '0')}${c.b.toInt().toRadixString(16).padLeft(2, '0')}'.toUpperCase(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: selected ? 68 : 56,
                height: selected ? 68 : 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.white, width: 3) : null,
            boxShadow: selected
              ? [BoxShadow(color: c.withAlpha((0.4 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withAlpha((0.06 * 255).toInt()), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                    ),
                    if (selected) const Icon(Icons.check, color: Colors.white, size: 28)
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
