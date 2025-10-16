import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class FontSizeSlider extends StatelessWidget {
  final double min;
  final double max;

  const FontSizeSlider({super.key, this.min = 12.0, this.max = 24.0});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final value = themeController.baseFontSize.value;
      final canDecrease = value > min;
      final canIncrease = value < max;

      return Row(
        children: [
          IconButton.filled(
            onPressed: canDecrease ? themeController.decreaseFontSize : null,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'تصغير حجم الخط',
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: value.toInt().toString(),
              onChanged: themeController.setBaseFontSize,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${value.toInt()} px',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: canIncrease ? themeController.increaseFontSize : null,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'تكبير حجم الخط',
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      );
    });
  }
}
