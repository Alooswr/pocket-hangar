import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/images/eve_image.dart';
import '../../core/sde/sde_models.dart';
import '../../widgets/common.dart';

typedef PickerResults = AsyncValue<List<TypeInfo>> Function(WidgetRef ref, String query);

/// Full-screen list of types with a search field. Pops with the chosen [TypeInfo].
class TypePickerScreen extends ConsumerStatefulWidget {
  const TypePickerScreen({
    required this.title,
    required this.results,
    this.searchHint,
    this.emptyQueryMessage,
    this.searchable = true,
    super.key,
  });

  final String title;
  final PickerResults results;
  final String? searchHint;

  /// Shown instead of results while the query is empty (when the list would be too long).
  final String? emptyQueryMessage;
  final bool searchable;

  @override
  ConsumerState<TypePickerScreen> createState() => _TypePickerScreenState();
}

class _TypePickerScreenState extends ConsumerState<TypePickerScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hint = widget.emptyQueryMessage;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
              child: TextField(
                controller: _controller,
                autofocus: hint != null,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? l.search,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
          Expanded(
            child: _query.isEmpty && hint != null
                ? MessageView(message: hint)
                : AsyncBody(
                    value: widget.results(ref, _query),
                    builder: (types) => types.isEmpty
                        ? MessageView(message: _query.isEmpty ? l.noItems : l.noResults(_query))
                        : ListView.builder(
                            itemCount: types.length,
                            itemExtent: 56,
                            itemBuilder: (context, i) => _TypeRow(type: types[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type});

  final TypeInfo type;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: EveImage.type(type.typeId, size: 32),
        title: Text(type.name.of(zh: context.zh), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: context.zh && type.name.zh != null
            ? Text(type.name.en, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        onTap: () => Navigator.of(context).pop(type),
      );
}

/// Bottom sheet with a text field for EFT text. Returns the text, or null when dismissed.
Future<String?> showEftImportSheet(BuildContext context) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _EftSheet(),
    );

class _EftSheet extends StatefulWidget {
  const _EftSheet();

  @override
  State<_EftSheet> createState() => _EftSheetState();
}

class _EftSheetState extends State<_EftSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    setState(() => _controller.text = text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.importEft, style: context.text.titleMedium),
          const SizedBox(height: Space.m),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(hintText: l.eftPasteHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.m),
          Row(
            children: [
              TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_outlined, size: 18),
                label: Text(l.paste),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_controller.text),
                child: Text(l.eftImport),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Text input dialog (rename). Returns the trimmed text, or null when cancelled.
Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String confirm,
  int maxLength = 50,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: title, initial: initial, confirm: confirm, maxLength: maxLength),
    );

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial, required this.confirm, required this.maxLength});

  final String title;
  final String initial;
  final String confirm;
  final int maxLength;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void submit() => Navigator.of(context).pop(_controller.text.trim());
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(onPressed: submit, child: Text(widget.confirm)),
      ],
    );
  }
}

/// Yes/no dialog for destructive actions. The confirming button carries the action's name.
Future<bool> confirmAction(BuildContext context, {required String message, required String action}) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.tokens.danger, foregroundColor: context.tokens.bg),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
