import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../theme/palette.dart';

/// Modern theme color palette selector
class ThemePalette extends StatelessWidget {
  const ThemePalette({super.key, this.onSelected});

  final void Function(Color)? onSelected;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: Palette.themeColors.length,
        itemBuilder: (context, index) {
          final colorPalette = Palette.themeColors[index];
          final selected =
              themeCtrl.colorSeed.value.value == colorPalette.seed.value;

          return GestureDetector(
            onTap: () {
              themeCtrl.setColor(colorPalette.seed);
              if (onSelected != null) onSelected!(colorPalette.seed);
            },
            child: Tooltip(
              message: '${colorPalette.name}\n${colorPalette.description}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: colorPalette.seed,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: colorPalette.seed.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        colorPalette.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: colorPalette.seed,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
