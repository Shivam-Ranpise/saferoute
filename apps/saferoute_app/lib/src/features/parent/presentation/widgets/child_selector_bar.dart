import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/parent_providers.dart';

class ChildSelectorBar extends ConsumerWidget {
  const ChildSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);
    final selectedId = ref.watch(selectedChildIdProvider);

    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: SafeRouteColors.deepNavy,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final child = children[index];
              final isSelected = child.id == selectedId;

              return ChoiceChip(
                showCheckmark: false,
                avatar: CircleAvatar(
                  backgroundColor: isSelected
                      ? SafeRouteColors.yellow
                      : SafeRouteColors.navyLight,
                  child: Text(
                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: isSelected
                          ? SafeRouteColors.deepNavy
                          : SafeRouteColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                label: Text(child.name),
                selected: isSelected,
                selectedColor: SafeRouteColors.yellow,
                backgroundColor: SafeRouteColors.navyMid,
                labelStyle: TextStyle(
                  color: isSelected
                      ? SafeRouteColors.deepNavy
                      : SafeRouteColors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
                side: BorderSide(
                  color: isSelected
                      ? SafeRouteColors.yellow
                      : SafeRouteColors.navyLight,
                  width: 1.5,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedChildIdProvider.notifier).state = child.id;
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => Container(
        height: 64,
        color: SafeRouteColors.deepNavy,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: SafeRouteColors.yellow,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
