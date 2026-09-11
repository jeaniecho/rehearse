import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../theme/app_theme.dart';

/// The three pushback levels, side by side.
///
/// Shared because it appears twice: on the briefing for this rehearsal, and
/// on the You tab for the remembered default. Both write the same setting.
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    required this.selected,
    required this.onChanged,
    this.keyPrefix = 'difficulty',
    super.key,
  });

  final SimulationDifficulty selected;
  final ValueChanged<SimulationDifficulty> onChanged;

  /// Both copies can be in the tree at once — the tabs stay built under a
  /// pushed briefing — so the keys have to differ or a finder matches two.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All three the height of the tallest, because "Very defensive"
        // wraps to two lines where "Calm" does not, and three pills at three
        // heights read as a mistake rather than as a choice.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final level in SimulationDifficulty.values) ...[
                if (level != SimulationDifficulty.values.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    selected: level == selected,
                    button: true,
                    child: Material(
                      color: level == selected
                          ? AppColors.forest
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        key: Key('${keyPrefix}_${level.name}'),
                        onTap: () => onChanged(level),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: level == selected
                                  ? AppColors.forest
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            level.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: level == selected
                                  ? Colors.white
                                  : AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          selected.description,
          key: Key('${keyPrefix}_description'),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
