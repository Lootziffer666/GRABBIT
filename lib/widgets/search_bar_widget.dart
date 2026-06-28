import 'package:flutter/material.dart';

import '../theme/grabbit_colors.dart';

/// GRABBIT search bar — instant search against the FTS5 index.
/// Styled to FLUBBER specs: dark surface, turquoise focus, Barlow font.
class GrabbitSearchBar extends StatelessWidget {
  const GrabbitSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.hintText = 'Dateien suchen...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GrabbitColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.borderStrong),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GrabbitColors.t1,
            ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: GrabbitColors.t3,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: GrabbitColors.t3, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
