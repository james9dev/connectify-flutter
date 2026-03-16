import 'package:flutter/material.dart';

class ProfilePhotoMosaicLayout<T> extends StatelessWidget {
  const ProfilePhotoMosaicLayout({
    super.key,
    required this.photos,
    required this.imageBuilder,
    required this.onAddPressed,
    required this.onDeletePressed,
    this.onReorder,
    this.enableReorder = false,
    this.maxPhotos = 6,
    this.representativeLabel = '대표 사진',
  });

  final List<T> photos;
  final Widget Function(BuildContext context, T photo) imageBuilder;
  final VoidCallback? onAddPressed;
  final ValueChanged<int>? onDeletePressed;
  final void Function(int fromIndex, int toIndex)? onReorder;
  final bool enableReorder;
  final int maxPhotos;
  final String representativeLabel;

  static const double _gap = 10;
  static const Map<int, Offset> _thumbnailGrid = <int, Offset>{1: Offset(2, 0), 2: Offset(2, 1), 3: Offset(0, 2), 4: Offset(1, 2), 5: Offset(2, 2)};

  @override
  Widget build(BuildContext context) {
    final limitedPhotos = photos.take(maxPhotos).toList(growable: false);
    final representative = limitedPhotos.isNotEmpty ? limitedPhotos.first : null;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = (constraints.maxWidth - (_gap * 2)) / 3;
          final representativeSize = (cell * 2) + _gap;

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: representativeSize,
                height: representativeSize,
                child: _wrapWithReorder(
                  index: 0,
                  photoCount: limitedPhotos.length,
                  width: representativeSize,
                  height: representativeSize,
                  borderRadius: BorderRadius.circular(16),
                  child: _HeroPhotoCard<T>(
                    picture: representative,
                    imageBuilder: imageBuilder,
                    representativeLabel: representativeLabel,
                    onAddPressed: onAddPressed,
                    onDeletePressed: representative == null || onDeletePressed == null ? null : () => onDeletePressed!(0),
                  ),
                ),
              ),
              ..._thumbnailGrid.entries.map((entry) {
                final photoIndex = entry.key;
                final col = entry.value.dx;
                final row = entry.value.dy;

                return Positioned(left: col * (cell + _gap), top: row * (cell + _gap), width: cell, height: cell, child: _buildThumbnailSlot(context, limitedPhotos, photoIndex));
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnailSlot(BuildContext context, List<T> limitedPhotos, int index) {
    if (index < limitedPhotos.length) {
      final picture = limitedPhotos[index];
      return _wrapWithReorder(
        index: index,
        photoCount: limitedPhotos.length,
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(16),
        child: _PhotoSlotFilled<T>(picture: picture, imageBuilder: imageBuilder, onDelete: onDeletePressed == null ? null : () => onDeletePressed!(index)),
      );
    }

    if (index >= maxPhotos) {
      return const SizedBox.shrink();
    }

    return _PhotoSlotEmpty(onTap: onAddPressed);
  }

  Widget _wrapWithReorder({required int index, required int photoCount, required double width, required double height, required BorderRadius borderRadius, required Widget child}) {
    final canReorder = enableReorder && onReorder != null && index < photoCount;
    if (!canReorder) {
      return child;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index && details.data >= 0 && details.data < photoCount,
      onAcceptWithDetails: (details) => onReorder!(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: isHovering ? Border.all(color: const Color(0xFFFFC629), width: 2.4) : null,
          ),
          child: LongPressDraggable<int>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width.isFinite ? width : 110,
                height: height.isFinite ? height : 110,
                child: Opacity(opacity: 0.92, child: child),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: child),
            child: child,
          ),
        );
      },
    );
  }
}

class _HeroPhotoCard<T> extends StatelessWidget {
  const _HeroPhotoCard({required this.picture, required this.imageBuilder, required this.representativeLabel, required this.onAddPressed, required this.onDeletePressed});

  final T? picture;
  final Widget Function(BuildContext context, T photo) imageBuilder;
  final String representativeLabel;
  final VoidCallback? onAddPressed;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE36D),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: picture == null ? onAddPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (picture == null)
              const ColoredBox(
                color: Color(0xFFFFE36D),
                child: Center(child: Icon(Icons.add_a_photo_rounded, size: 56, color: Colors.black87)),
              )
            else
              imageBuilder(context, picture as T),
            Positioned(
              top: 12,
              left: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.64), borderRadius: BorderRadius.circular(999)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    representativeLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ),
            if (picture != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  onPressed: onDeletePressed,
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.86), foregroundColor: Colors.black87, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSlotFilled<T> extends StatelessWidget {
  const _PhotoSlotFilled({required this.picture, required this.imageBuilder, required this.onDelete});

  final T picture;
  final Widget Function(BuildContext context, T photo) imageBuilder;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageBuilder(context, picture),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              onPressed: onDelete,
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.86), foregroundColor: Colors.black87, visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlotEmpty extends StatelessWidget {
  const _PhotoSlotEmpty({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE9A3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Center(child: Icon(Icons.add, size: 34, color: Colors.black54)),
      ),
    );
  }
}
