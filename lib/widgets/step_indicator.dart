import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final completed = index < current - 1;
        final active = index == current - 1;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 32 : 12,
          height: 8,
          decoration: BoxDecoration(
            color: active || completed
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
