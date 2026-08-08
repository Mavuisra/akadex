import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/akadex_theme.dart';
import '../theme/timeline_tokens.dart';
import 'file_drop_validator.dart';

/// Zone d’upload pro : cliquer pour parcourir **ou** glisser-déposer.
class FileDropZone extends StatefulWidget {
  const FileDropZone({
    super.key,
    required this.allowedExtensions,
    required this.onChanged,
    this.fileName,
    this.fileSize,
    this.maxBytes = FileDropValidator.defaultMaxBytes,
    this.enabled = true,
    this.title = 'Glisser-déposer un fichier',
    this.subtitle,
  });

  final List<String> allowedExtensions;
  final ValueChanged<FileDropSelection?> onChanged;
  final String? fileName;
  final int? fileSize;
  final int maxBytes;
  final bool enabled;
  final String title;
  final String? subtitle;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _dragging = false;
  bool _busy = false;
  String? _error;

  String get _hintExtensions {
    final list = widget.allowedExtensions
        .map((e) => '.${e.replaceAll('.', '')}')
        .join(', ');
    final mo = (widget.maxBytes / (1024 * 1024)).toStringAsFixed(0);
    return widget.subtitle ?? 'Formats : $list · max $mo Mo';
  }

  Future<void> _applyBytes({
    required String name,
    required List<int> bytes,
    String? path,
  }) async {
    final result = FileDropValidator.validate(
      name: name,
      bytes: bytes,
      path: path,
      allowedExtensions: widget.allowedExtensions,
      maxBytes: widget.maxBytes,
    );
    if (!result.isValid) {
      setState(() => _error = result.error);
      return;
    }
    setState(() => _error = null);
    widget.onChanged(result.selection);
  }

  Future<void> _pick() async {
    if (!widget.enabled || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions
            .map((e) => e.replaceAll('.', ''))
            .toList(),
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      var bytes = file.bytes;
      final path = kIsWeb ? null : file.path;
      if ((bytes == null || bytes.isEmpty) &&
          path != null &&
          path.isNotEmpty &&
          !kIsWeb) {
        // Lecture différée gérée par le parent via path si besoin —
        // ici on exige des bytes pour la validation taille.
        setState(() {
          _error =
              'Impossible de lire ce fichier. Réessaie avec un autre fichier.';
        });
        return;
      }
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _error = 'Impossible de lire ce fichier.';
        });
        return;
      }
      await _applyBytes(
        name: file.name,
        bytes: bytes,
        path: path,
      );
    } catch (e) {
      setState(() => _error = 'Sélection impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    if (!widget.enabled || _busy) return;
    if (details.files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _dragging = false;
    });
    try {
      final xfile = details.files.first;
      final bytes = await xfile.readAsBytes();
      await _applyBytes(
        name: xfile.name,
        bytes: bytes,
        path: kIsWeb ? null : xfile.path,
      );
    } catch (_) {
      setState(() => _error = 'Impossible de lire le fichier déposé.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    setState(() => _error = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null && widget.fileName!.isNotEmpty;
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final borderColor = _dragging
        ? primary
        : (_error != null
            ? AkadexColors.danger
            : feed.meta.withValues(alpha: 0.45));
    final bg = _dragging ? feed.softTint : feed.commentBubble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropTarget(
          enable: widget.enabled,
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: _onDrop,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.enabled && !_busy ? _pick : null,
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: borderColor,
                  radius: 12,
                  strokeWidth: _dragging ? 2 : 1.4,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: hasFile
                      ? _SelectedFileRow(
                          name: widget.fileName!,
                          sizeLabel: FileDropValidator.formatSize(
                            widget.fileSize ?? 0,
                          ),
                          busy: _busy,
                          onClear: widget.enabled ? _clear : null,
                          onReplace: widget.enabled && !_busy ? _pick : null,
                        )
                      : _EmptyDropContent(
                          title: widget.title,
                          hint: _hintExtensions,
                          busy: _busy,
                          dragging: _dragging,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: AkadexColors.danger,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyDropContent extends StatelessWidget {
  const _EmptyDropContent({
    required this.title,
    required this.hint,
    required this.busy,
    required this.dragging,
  });

  final String title;
  final String hint;
  final bool busy;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Icon(
          dragging
              ? Icons.file_download_outlined
              : Icons.cloud_upload_outlined,
          size: 32,
          color: dragging ? primary : feed.meta,
        ),
        const SizedBox(height: 10),
        Text(
          busy ? 'Lecture du fichier…' : title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: dragging ? primary : feed.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ou appuyer pour parcourir',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: feed.meta,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: feed.meta,
          ),
        ),
      ],
    );
  }
}

class _SelectedFileRow extends StatelessWidget {
  const _SelectedFileRow({
    required this.name,
    required this.sizeLabel,
    required this.busy,
    this.onClear,
    this.onReplace,
  });

  final String name;
  final String sizeLabel;
  final bool busy;
  final VoidCallback? onClear;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: feed.softTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.insert_drive_file_outlined,
                  color: primary,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: feed.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sizeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: feed.meta,
                ),
              ),
            ],
          ),
        ),
        if (onReplace != null)
          TextButton(
            onPressed: onReplace,
            child: Text('Changer', style: TextStyle(color: primary)),
          ),
        if (onClear != null)
          IconButton(
            tooltip: 'Retirer',
            onPressed: onClear,
            icon: Icon(Icons.close_rounded, color: feed.meta),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

FileDropSelection fileDropSelectionForTest({
  String name = 'cours.pdf',
  List<int>? bytes,
}) {
  return FileDropSelection(
    name: name,
    bytes: bytes ?? List<int>.filled(120, 1),
  );
}
