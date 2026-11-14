import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'google_drive_service.dart';

class GoogleDriveScreen extends StatefulWidget {
  const GoogleDriveScreen({
    super.key,
    required this.files,
    required this.service,
  });

  final List<drive.File> files;
  final GoogleDriveService service;

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

enum _DriveFilter { all, images, documents, media }

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool? _showGrid;
  bool _isDownloading = false;
  String _query = '';
  _DriveFilter _filter = _DriveFilter.all;

  List<drive.File> get _visibleFiles {
    final String normalizedQuery = _query.toLowerCase();
    return widget.files
        .where((drive.File file) {
          final bool matchesQuery =
              normalizedQuery.isEmpty ||
              (file.name ?? '').toLowerCase().contains(normalizedQuery);
          return matchesQuery && _matchesFilter(file, _filter);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<drive.File> files = _visibleFiles;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool effectiveGrid =
        _showGrid ?? MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title:
            _showSearch
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search in Drive',
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) {
                    setState(() => _query = value.trim());
                  },
                )
                : const Text('My Drive'),
        actions: <Widget>[
          IconButton(
            tooltip: _showSearch ? 'Close search' : 'Search files',
            onPressed: _isDownloading ? null : _toggleSearch,
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
          ),
          IconButton(
            tooltip: effectiveGrid ? 'Show list' : 'Show grid',
            onPressed:
                _isDownloading
                    ? null
                    : () => setState(() => _showGrid = !effectiveGrid),
            icon: Icon(
              effectiveGrid
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DriveToolbar(
                shownCount: files.length,
                totalCount: widget.files.length,
                selectedFilter: _filter,
                onFilterChanged:
                    _isDownloading
                        ? null
                        : (_DriveFilter value) {
                          setState(() => _filter = value);
                        },
              ),
              Expanded(
                child:
                    files.isEmpty
                        ? _EmptyState(
                          hasQuery: _query.isNotEmpty,
                          hasFilter: _filter != _DriveFilter.all,
                          onReset: _resetFilters,
                        )
                        : LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final bool useGrid =
                                _showGrid ?? constraints.maxWidth >= 720;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child:
                                  useGrid
                                      ? _FileGrid(
                                        key: const ValueKey<String>('grid'),
                                        files: files,
                                        enabled: !_isDownloading,
                                        onTap: _confirmDownload,
                                      )
                                      : _FileList(
                                        key: const ValueKey<String>('list'),
                                        files: files,
                                        enabled: !_isDownloading,
                                        onTap: _confirmDownload,
                                      ),
                            );
                          },
                        ),
              ),
            ],
          ),
          if (_isDownloading) const _DownloadingOverlay(),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _filter = _DriveFilter.all;
      _query = '';
      _searchController.clear();
    });
  }

  Future<void> _confirmDownload(drive.File file) async {
    final bool? confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (BuildContext context) => DownloadAlertDialog(file: file),
    );
    if (confirmed == true) {
      await _download(file);
    }
  }

  Future<void> _download(drive.File file) async {
    setState(() => _isDownloading = true);
    try {
      final File downloadedFile = await widget.service.downloadFile(file);
      if (mounted) {
        Navigator.of(context).pop(downloadedFile);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _errorMessage(Object error) {
    if (error case GoogleDriveFileException(:final String message)) {
      return message;
    }
    return 'Unable to download this file. Please try again.';
  }
}

class _DriveToolbar extends StatelessWidget {
  const _DriveToolbar({
    required this.shownCount,
    required this.totalCount,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final int shownCount;
  final int totalCount;
  final _DriveFilter selectedFilter;
  final ValueChanged<_DriveFilter>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: 'All',
                    icon: Icons.folder_open_outlined,
                    value: _DriveFilter.all,
                    selected: selectedFilter,
                    onSelected: onFilterChanged,
                  ),
                  _FilterChip(
                    label: 'Images',
                    icon: Icons.image_outlined,
                    value: _DriveFilter.images,
                    selected: selectedFilter,
                    onSelected: onFilterChanged,
                  ),
                  _FilterChip(
                    label: 'Documents',
                    icon: Icons.description_outlined,
                    value: _DriveFilter.documents,
                    selected: selectedFilter,
                    onSelected: onFilterChanged,
                  ),
                  _FilterChip(
                    label: 'Media',
                    icon: Icons.play_circle_outline_rounded,
                    value: _DriveFilter.media,
                    selected: selectedFilter,
                    onSelected: onFilterChanged,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: <Widget>[
                Text(
                  'Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  shownCount == totalCount
                      ? '$totalCount files'
                      : '$shownCount of $totalCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final _DriveFilter value;
  final _DriveFilter selected;
  final ValueChanged<_DriveFilter>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: value == selected,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        showCheckmark: false,
        backgroundColor: colors.surface,
        selectedColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: onSelected == null ? null : (_) => onSelected!(value),
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    super.key,
    required this.files,
    required this.enabled,
    required this.onTap,
  });

  final List<drive.File> files;
  final bool enabled;
  final ValueChanged<drive.File> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemCount: files.length,
      separatorBuilder:
          (BuildContext context, int index) => Divider(
            height: 1,
            indent: 72,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      itemBuilder: (BuildContext context, int index) {
        final drive.File file = files[index];
        return _FileListCard(
          file: file,
          enabled: enabled,
          onTap: () => onTap(file),
        );
      },
    );
  }
}

class _FileGrid extends StatelessWidget {
  const _FileGrid({
    super.key,
    required this.files,
    required this.enabled,
    required this.onTap,
  });

  final List<drive.File> files;
  final bool enabled;
  final ValueChanged<drive.File> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 232,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (BuildContext context, int index) {
        final drive.File file = files[index];
        return _FileGridCard(
          file: file,
          enabled: enabled,
          onTap: () => onTap(file),
        );
      },
    );
  }
}

class _FileListCard extends StatelessWidget {
  const _FileListCard({
    required this.file,
    required this.enabled,
    required this.onTap,
  });

  final drive.File file;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: <Widget>[
              _FilePreview(file: file, width: 48, height: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      file.name ?? 'Unnamed file',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _FileMetadata(file: file),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Download ${file.name ?? 'file'}',
                onPressed: enabled ? onTap : null,
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileGridCard extends StatelessWidget {
  const _FileGridCard({
    required this.file,
    required this.enabled,
    required this.onTap,
  });

  final drive.File file;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _FilePreview(file: file),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton.filled(
                      tooltip: 'Download ${file.name ?? 'file'}',
                      onPressed: enabled ? onTap : null,
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    file.name ?? 'Unnamed file',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FileMetadata(file: file),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({this.width, this.height, required this.file});

  final double? width;
  final double? height;
  final drive.File file;

  @override
  Widget build(BuildContext context) {
    final _FileVisual visual = _visualForFile(file);
    final String? thumbnail = file.thumbnailLink;
    return Semantics(
      image: true,
      label: 'Preview of ${file.name ?? 'file'}',
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child:
                thumbnail == null || thumbnail.isEmpty
                    ? _FilePlaceholder(visual: visual)
                    : Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) =>
                              loadingProgress == null
                                  ? child
                                  : _FilePlaceholder(visual: visual),
                      errorBuilder:
                          (_, _, _) => _FilePlaceholder(visual: visual),
                    ),
          ),
        ),
      ),
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({required this.visual});

  final _FileVisual visual;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(visual.icon, size: 34, color: visual.color));
  }
}

class _FileMetadata extends StatelessWidget {
  const _FileMetadata({required this.file});

  final drive.File file;

  @override
  Widget build(BuildContext context) {
    final _FileVisual visual = _visualForFile(file);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(visual.icon, size: 15, color: visual.color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            <String>[
              visual.label,
              if (file.size != null) _formatBytes(file.size!),
              if (file.modifiedTime != null) _formatDate(file.modifiedTime!),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasQuery,
    required this.hasFilter,
    required this.onReset,
  });

  final bool hasQuery;
  final bool hasFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final bool isFiltered = hasQuery || hasFilter;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 42,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No matching files' : 'Your Drive looks empty',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try another search or clear the active filter.'
                  : 'No downloadable files were found for this account.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (isFiltered) ...<Widget>[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadingOverlay extends StatelessWidget {
  const _DownloadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const ModalBarrier(dismissible: false, color: Color(0x52000000)),
        Center(
          child: Card(
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Downloading file…',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DownloadAlertDialog extends StatelessWidget {
  const DownloadAlertDialog({super.key, required this.file});

  final drive.File file;

  @override
  Widget build(BuildContext context) {
    final String fileName = file.name ?? 'Unnamed file';
    final TargetPlatform platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoAlertDialog(
        title: const Text('Download file?'),
        content: Text(fileName),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      );
    }

    final _FileVisual visual = _visualForFile(file);
    return AlertDialog(
      icon: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(visual.icon, color: visual.color, size: 30),
        ),
      ),
      title: const Text('Download file?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            fileName,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            <String>[
              visual.label,
              if (file.size != null) _formatBytes(file.size!),
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download'),
        ),
      ],
    );
  }
}

bool _matchesFilter(drive.File file, _DriveFilter filter) {
  final String mimeType = file.mimeType ?? '';
  return switch (filter) {
    _DriveFilter.all => true,
    _DriveFilter.images => mimeType.startsWith('image/'),
    _DriveFilter.media =>
      mimeType.startsWith('video/') || mimeType.startsWith('audio/'),
    _DriveFilter.documents =>
      !mimeType.startsWith('image/') &&
          !mimeType.startsWith('video/') &&
          !mimeType.startsWith('audio/'),
  };
}

_FileVisual _visualForFile(drive.File file) {
  final String mimeType = file.mimeType ?? '';
  if (mimeType.startsWith('image/')) {
    return const _FileVisual(Icons.image_rounded, Colors.purple, 'Image');
  }
  if (mimeType.startsWith('video/')) {
    return const _FileVisual(Icons.movie_rounded, Colors.red, 'Video');
  }
  if (mimeType.startsWith('audio/')) {
    return const _FileVisual(Icons.audio_file_rounded, Colors.orange, 'Audio');
  }
  if (mimeType == 'application/pdf') {
    return const _FileVisual(Icons.picture_as_pdf_rounded, Colors.red, 'PDF');
  }
  if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
    return const _FileVisual(
      Icons.table_chart_rounded,
      Colors.green,
      'Spreadsheet',
    );
  }
  if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
    return const _FileVisual(
      Icons.slideshow_rounded,
      Colors.deepOrange,
      'Presentation',
    );
  }
  if (mimeType.contains('document') ||
      mimeType.contains('word') ||
      mimeType.startsWith('text/')) {
    return const _FileVisual(
      Icons.description_rounded,
      Colors.blue,
      'Document',
    );
  }
  if (mimeType.contains('zip') || mimeType.contains('compressed')) {
    return const _FileVisual(Icons.folder_zip_rounded, Colors.amber, 'Archive');
  }
  return const _FileVisual(
    Icons.insert_drive_file_rounded,
    Colors.blueGrey,
    'File',
  );
}

String _formatDate(DateTime date) {
  final DateTime local = date.toLocal();
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime value = DateTime(local.year, local.month, local.day);
  final int difference = today.difference(value).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _formatBytes(String value) {
  final int? bytes = int.tryParse(value);
  if (bytes == null || bytes < 0) return value;
  if (bytes < 1024) return '$bytes B';
  const List<String> units = <String>['KB', 'MB', 'GB', 'TB'];
  double size = bytes / 1024;
  int unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final int decimals = size >= 10 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${units[unit]}';
}

final class _FileVisual {
  const _FileVisual(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}
