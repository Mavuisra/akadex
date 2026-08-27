import 'package:flutter/material.dart';

import '../theme/akadex_theme.dart';
import '../theme/auth_entry_style.dart';
import '../theme/timeline_tokens.dart';
import 'common_widgets.dart';

class AcademicOption {
  const AcademicOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// Autocomplete réutilisable pour université / faculté / département / promotion.
class AcademicAutocomplete extends StatefulWidget {
  const AcademicAutocomplete({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.selectedId,
    this.selectedName,
    this.allowCustom = true,
    this.onCreateCustom,
    this.enabled = true,
    this.icon,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.softStyle = false,
    this.authOutline = false,
  });

  final String label;
  final List<AcademicOption> options;
  final String? selectedId;
  final String? selectedName;
  final void Function(String id, String name) onSelected;
  final bool allowCustom;
  final Future<String?> Function(String name)? onCreateCustom;
  final bool enabled;
  final IconData? icon;
  final EdgeInsets contentPadding;
  /// Style SoftCard + hint, sans bordure Material.
  final bool softStyle;
  /// Style connexion/inscription (fond + contour type Facebook).
  final bool authOutline;

  @override
  State<AcademicAutocomplete> createState() => _AcademicAutocompleteState();
}

class _AcademicAutocompleteState extends State<AcademicAutocomplete> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _textController = TextEditingController(text: _initialText());
    _focusNode = FocusNode();
  }

  String _initialText() {
    if (widget.selectedName != null && widget.selectedName!.isNotEmpty) {
      return widget.selectedName!;
    }
    if (widget.selectedId == null || widget.selectedId!.isEmpty) return '';
    for (final o in widget.options) {
      if (o.id == widget.selectedId) return o.name;
    }
    return '';
  }

  @override
  void didUpdateWidget(covariant AcademicAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idChanged = widget.selectedId != oldWidget.selectedId;
    final nameChanged = widget.selectedName != oldWidget.selectedName;
    final optionsChanged = widget.options != oldWidget.options;
    if (idChanged || nameChanged || optionsChanged) {
      _selectedId = widget.selectedId;
      final next = _initialText();
      if (_textController.text != next && !_focusNode.hasFocus) {
        _textController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AcademicOption> _filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.name.toLowerCase().contains(q))
        .toList();
  }

  bool _exactMatch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return widget.options.any((o) => o.name.toLowerCase() == q);
  }

  Future<void> _pickCustom(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (widget.onCreateCustom != null) {
      try {
        final id = await widget.onCreateCustom!(trimmed);
        if (!mounted) return;
        final resolvedId = (id == null || id.isEmpty) ? trimmed : id;
        _selectedId = resolvedId;
        _textController.text = trimmed;
        widget.onSelected(resolvedId, trimmed);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Impossible d’ajouter « $trimmed ».')),
        );
      }
      return;
    }
    _selectedId = trimmed;
    _textController.text = trimmed;
    widget.onSelected(trimmed, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<AcademicOption>(
      textEditingController: _textController,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue value) {
        if (!widget.enabled) return const Iterable<AcademicOption>.empty();
        final filtered = _filter(value.text);
        final q = value.text.trim();
        if (widget.allowCustom &&
            q.isNotEmpty &&
            !_exactMatch(q)) {
          return [
            ...filtered,
            AcademicOption(id: '__custom__', name: q),
          ];
        }
        return filtered;
      },
      displayStringForOption: (o) =>
          o.id == '__custom__' ? 'Ajouter « ${o.name} »' : o.name,
      onSelected: (option) async {
        if (option.id == '__custom__') {
          await _pickCustom(option.name);
          return;
        }
        _selectedId = option.id;
        _textController.text = option.name;
        widget.onSelected(option.id, option.name);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final suffix = _selectedId != null && _selectedId!.isNotEmpty
            ? IconButton(
                tooltip: 'Effacer',
                onPressed: widget.enabled
                    ? () {
                        setState(() {
                          _selectedId = null;
                          controller.clear();
                        });
                        widget.onSelected('', '');
                      }
                    : null,
                icon: const Icon(Icons.clear_rounded, size: 20),
              )
            : Icon(
                Icons.arrow_drop_down_rounded,
                color: AuthEntryStyle.muted(isDark),
              );

        late final InputDecoration decoration;
        if (widget.authOutline) {
          decoration = AuthEntryStyle.fieldDecoration(
            hint: widget.label,
            isDark: isDark,
            suffixIcon: suffix,
          );
        } else {
          final feed = TimelineTokens.of(context);
          decoration = InputDecoration(
            hintText: widget.softStyle ? widget.label : null,
            labelText: widget.softStyle ? null : widget.label,
            hintStyle: widget.softStyle
                ? TextStyle(color: feed.meta, fontSize: 15)
                : null,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, color: feed.meta),
            border: widget.softStyle ? InputBorder.none : null,
            filled: true,
            fillColor: widget.softStyle ? Colors.transparent : null,
            contentPadding: widget.contentPadding,
            suffixIcon: IconTheme(
              data: IconThemeData(color: feed.meta),
              child: suffix,
            ),
          );
        }

        final feedColors = TimelineTokens.of(context);
        final field = TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => onFieldSubmitted(),
          style: TextStyle(
            color: widget.authOutline
                ? AuthEntryStyle.title(isDark)
                : feedColors.ink,
            fontSize: 16,
          ),
          decoration: decoration,
        );
        if (widget.authOutline || !widget.softStyle) return field;
        return SoftCard(padding: EdgeInsets.zero, child: field);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final isCustom = option.id == '__custom__';
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCustom
                                ? Icons.add_circle_outline_rounded
                                : Icons.school_outlined,
                            size: 18,
                            color: isCustom
                                ? AkadexColors.primary
                                : AkadexColors.inkMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isCustom
                                  ? 'Ajouter « ${option.name} »'
                                  : option.name,
                              style: TextStyle(
                                fontWeight: isCustom
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCustom
                                    ? AkadexColors.primary
                                    : AkadexColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
