import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// Evidence and documents attached to a record (incident, inspection, notice, corrective action).
/// Photos can be taken with the camera or picked from the gallery; documents from the device.
class AttachmentsSection extends StatefulWidget {
  const AttachmentsSection({super.key, required this.entityType, required this.entityId, this.canUpload = false, this.title = 'Attachments'});

  final String entityType;
  final String entityId;
  final bool canUpload;
  final String title;

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  late Future<List<Json>> _files = _load();

  Future<List<Json>> _load() => context.api.attachments(widget.entityType, widget.entityId);

  void _reload() => setState(() => _files = _load());

  Future<void> _add() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!kIsWeb) ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Take a photo'), onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose a photo'), onTap: () => Navigator.pop(ctx, 'gallery')),
          ListTile(leading: const Icon(Icons.attach_file), title: const Text('Choose a document'), onTap: () => Navigator.pop(ctx, 'file')),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    Uint8List? bytes;
    String? name;
    if (source == 'file') {
      final picked = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'txt'],
      );
      final f = picked?.files.single;
      bytes = f?.bytes;
      name = f?.name;
    } else {
      final image = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 80,
      );
      if (image != null) {
        bytes = await image.readAsBytes();
        name = image.name.contains('.') ? image.name : '${image.name}.jpg';
      }
    }
    if (bytes == null || name == null || !mounted) return;
    if (bytes.length > 10 * 1024 * 1024) {
      showMessage(context, 'Files must be 10 MB or smaller', error: true);
      return;
    }
    final description = await askText(context, 'Describe the file', hint: 'e.g. Guard rail installed on level 2', action: 'Upload');
    if (description == null || !mounted) return;
    final ok = await runAction(
      context,
      () => context.api.uploadAttachment(entityType: widget.entityType, entityId: widget.entityId, bytes: bytes!, filename: name!, description: description),
      success: 'Uploaded',
    );
    if (ok) _reload();
  }

  Future<void> _open(Json f) async {
    if (kIsWeb) {
      showMessage(context, 'Open attachments from the web console on this device.');
      return;
    }
    await runAction(context, () async {
      final bytes = await context.api.downloadAttachment(text(f['id']));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${text(f['fileName'], 'attachment')}');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) throw Exception('No app on this device can open ${text(f['fileName'])}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: widget.title,
      trailing: widget.canUpload ? TextButton.icon(onPressed: _add, icon: const Icon(Icons.add_a_photo_outlined, size: 18), label: const Text('Add')) : null,
      children: [
        FutureBuilder<List<Json>>(
          future: _files,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text(snap.error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error));
            final files = snap.data!;
            if (files.isEmpty) {
              return Text(widget.canUpload ? 'No files yet. Add photos or documents as evidence.' : 'No files.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline));
            }
            return Column(children: [
              for (final f in files)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(text(f['contentType']))),
                  title: Text(text(f['fileName'], 'File'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text([
                    if (str(f['description']) != null) str(f['description'])!,
                    '${text(f['uploadedBy'], 'Unknown')} · ${ago(date(f['uploadedAt']))} · ${_size(integer(f['sizeBytes']))}',
                  ].join('\n')),
                  isThreeLine: str(f['description']) != null,
                  onTap: () => _open(f),
                ),
            ]);
          },
        ),
      ],
    );
  }

  static IconData _iconFor(String type) {
    if (type.startsWith('image/')) return Icons.image_outlined;
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.contains('sheet') || type.contains('excel') || type.contains('csv')) return Icons.table_chart_outlined;
    return Icons.description_outlined;
  }

  static String _size(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
