import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../profile/profile_categories_provider.dart';
import 'activity_providers.dart';

/// Discover filters: city + category (from Firestore categories) + min age; dashboard tokens.
class DiscoverFiltersPanel extends ConsumerWidget {
  const DiscoverFiltersPanel({
    super.key,
    required this.compactHorizontal,
    this.densePills = false,
  });

  final bool compactHorizontal;
  final bool densePills;

  static String? _categoryDropdownValue(List<String> options, String? selected) {
    if (selected == null || selected.trim().isEmpty) return null;
    final s = selected.trim();
    if (options.contains(s)) return s;
    return null;
  }

  InputDecoration _fieldDecoration(DashboardTokens d, String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: d.bgPrimary,
      contentPadding: EdgeInsets.symmetric(horizontal: densePills ? 12 : 14, vertical: densePills ? 10 : 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: d.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: d.borderColor)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activityFiltersProvider);
    final ctrl = ref.read(activityFiltersProvider.notifier);
    final d = context.dash;
    final catsAsync = ref.watch(profileInterestCategoriesProvider);

    Widget categoryField({required bool expanded, double? width}) {
      Widget wrap(Widget child) {
        if (width != null) return SizedBox(width: width, child: child);
        return child;
      }

      return catsAsync.when(
        loading: () => wrap(
          SizedBox(
            height: densePills ? 44 : 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: d.accentBlue),
              ),
            ),
          ),
        ),
        error: (_, _) => wrap(
          TextField(
            decoration: _fieldDecoration(d, 'Category', hint: 'Exact name'),
            style: DashboardTextStyles.body(d),
            onSubmitted: (v) => ctrl.setCategory(v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        data: (categories) {
          final dropdownValue = _categoryDropdownValue(categories, filters.category);
          return wrap(
            DropdownButtonFormField<String?>(
              key: ValueKey('cat_$dropdownValue'),
              initialValue: dropdownValue,
              isExpanded: expanded,
              decoration: _fieldDecoration(d, 'Category'),
              dropdownColor: d.bgSecondary,
              style: DashboardTextStyles.body(d),
              icon: const Icon(Icons.arrow_drop_down),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any category', overflow: TextOverflow.ellipsis),
                ),
                for (final c in categories)
                  DropdownMenuItem<String?>(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
              ],
              selectedItemBuilder: (ctx) => [
                const Text('Any category', overflow: TextOverflow.ellipsis, maxLines: 1),
                for (final c in categories)
                  Text(c, overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
              onChanged: (v) => ctrl.setCategory(v),
            ),
          );
        },
      );
    }

    Widget cityField({required bool expanded, double? width}) {
      Widget inner = DropdownButtonFormField<String?>(
        key: ValueKey('city_${filters.city}'),
        initialValue: filters.city,
        isExpanded: expanded,
        decoration: _fieldDecoration(d, 'City'),
        dropdownColor: d.bgSecondary,
        style: DashboardTextStyles.body(d),
        icon: const Icon(Icons.arrow_drop_down),
        items: const [
          DropdownMenuItem<String?>(value: null, child: Text('Any city', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<String?>(value: 'Tallinn', child: Text('Tallinn')),
          DropdownMenuItem<String?>(value: 'Tartu', child: Text('Tartu')),
          DropdownMenuItem<String?>(value: 'Pärnu', child: Text('Pärnu')),
          DropdownMenuItem<String?>(value: 'Other', child: Text('Other')),
        ],
        selectedItemBuilder: (ctx) => const [
          Text('Any city', overflow: TextOverflow.ellipsis, maxLines: 1),
          Text('Tallinn', overflow: TextOverflow.ellipsis, maxLines: 1),
          Text('Tartu', overflow: TextOverflow.ellipsis, maxLines: 1),
          Text('Pärnu', overflow: TextOverflow.ellipsis, maxLines: 1),
          Text('Other', overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
        onChanged: ctrl.setCity,
      );
      if (width != null) return SizedBox(width: width, child: inner);
      return inner;
    }

    Widget minAgeField({double? width}) {
      Widget inner = TextField(
        key: ValueKey('minAge_${filters.minAge}'),
        decoration: _fieldDecoration(d, 'Min age', hint: filters.minAge?.toString()),
        style: DashboardTextStyles.body(d),
        keyboardType: TextInputType.number,
        onSubmitted: (v) {
          final n = int.tryParse(v.trim());
          ctrl.setMinAge(n);
        },
      );
      if (width != null) return SizedBox(width: width, child: inner);
      return inner;
    }

    final resetBtn = TextButton(
      onPressed: () {
        ctrl.clear();
        ctrl.setSearchQuery(null);
      },
      child: Text('Reset all', style: DashboardTextStyles.button(d).copyWith(color: d.accentBlue)),
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Discover filters', style: DashboardTextStyles.cardTitle(d)),
        Text('City, category & age — listings update instantly.', style: DashboardTextStyles.cardSubtitle(d)),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelW = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final useExpandedRow = !compactHorizontal && panelW >= 560;

        Widget body;
        if (useExpandedRow) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              SizedBox(height: densePills ? 12 : 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 32, child: cityField(expanded: true)),
                  SizedBox(width: densePills ? 10 : 12),
                  Expanded(flex: 48, child: categoryField(expanded: true)),
                  SizedBox(width: densePills ? 10 : 12),
                  Expanded(flex: 20, child: minAgeField()),
                  SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: resetBtn,
                  ),
                ],
              ),
            ],
          );
        } else if (compactHorizontal) {
          final vw = MediaQuery.sizeOf(context).width;
          final catW = math.max(260.0, math.min(400.0, vw * 0.78));
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              SizedBox(height: densePills ? 10 : 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 158, child: cityField(expanded: true)),
                    const SizedBox(width: 12),
                    SizedBox(width: catW, child: categoryField(expanded: true)),
                    const SizedBox(width: 12),
                    SizedBox(width: 112, child: minAgeField()),
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(top: 8), child: resetBtn),
                  ],
                ),
              ),
            ],
          );
        } else {
          body = Wrap(
            spacing: densePills ? 10 : 12,
            runSpacing: densePills ? 10 : 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              titleBlock,
              SizedBox(
                width: math.min(200.0, panelW * 0.38),
                child: cityField(expanded: true),
              ),
              SizedBox(
                width: math.max(240.0, math.min(panelW - 24, 520.0)),
                child: categoryField(expanded: true),
              ),
              SizedBox(width: 118, child: minAgeField()),
              resetBtn,
            ],
          );
        }

        return Container(
          margin: EdgeInsets.only(bottom: densePills ? 10 : 12),
          padding: EdgeInsets.fromLTRB(densePills ? 12 : 14, densePills ? 12 : 14, densePills ? 12 : 14, densePills ? 12 : 14),
          decoration: BoxDecoration(
            color: d.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: d.borderColor),
          ),
          child: body,
        );
      },
    );
  }
}
