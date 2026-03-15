import 'dart:io';
import 'dart:typed_data';

import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/profile_photo_repository.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/bloc/profile_photo_bloc.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/bloc/profile_photo_event.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/bloc/profile_photo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoPage extends StatefulWidget {
  const ProfilePhotoPage({super.key});

  static Route<List<ProfilePhotoDraft>?> route({
    required String kakaoAccessToken,
    required ProfileBasicInfoCommand basicInfoCommand,
    List<ProfilePhotoDraft> initialDraftPhotos = const <ProfilePhotoDraft>[],
  }) {
    return MaterialPageRoute<List<ProfilePhotoDraft>?>(
      builder: (context) => BlocProvider(
        create: (_) =>
            ProfilePhotoBloc(repository: context.read<ProfilePhotoRepository>(), kakaoAccessToken: kakaoAccessToken, basicInfoCommand: basicInfoCommand, initialDraftPhotos: initialDraftPhotos),
        child: const ProfilePhotoPage(),
      ),
    );
  }

  @override
  State<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  static final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _popWithDrafts();
      },
      child: BlocConsumer<ProfilePhotoBloc, ProfilePhotoState>(
        listenWhen: (previous, current) => previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == ProfilePhotoSubmitStatus.failure && state.submitErrorMessage != null) {
            _showSnackBar(state.submitErrorMessage!);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white, //const Color(0xFFFFF6CC),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFC629),
              foregroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: _popWithDrafts),
              title: const Text('프로필 사진 등록', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '당신의 진짜 모습을 보여주는 사진 몇 장을 골라보세요.',
                      style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '좋은 프로필 사진은 더 많은 매칭으로 이어져요!\n얼굴이 잘 보이는 사진을 올려보세요.',
                      style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _PhotoMosaicLayout(
                      draftPhotos: state.draftPhotos,
                      onAddPressed: state.isSubmitting ? null : () => _pickAndStagePhoto(state.draftPhotos.length),
                      onDeletePressed: state.isSubmitting ? null : (index) => _confirmDeletePhoto(index),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC629),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                onPressed: state.canComplete ? () => context.read<ProfilePhotoBloc>().add(const ProfilePhotoSubmitRequested()) : null,
                child: state.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87)),
                          const SizedBox(width: 10),
                          Text('업로드 중 (${state.uploadedCount}/${state.totalUploadCount})'),
                        ],
                      )
                    : const Text('완료'),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndStagePhoto(int currentCount) async {
    if (currentCount >= ProfilePhotoState.maxPhotos) {
      _showSnackBar('사진은 최대 ${ProfilePhotoState.maxPhotos}장까지 등록할 수 있어요.');
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted || picked == null) {
        return;
      }

      final cropped = await _cropImageToFourByFive(picked.path);
      if (!mounted || cropped == null) {
        return;
      }

      final bytes = await File(cropped.path).readAsBytes();
      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        _showSnackBar('선택한 사진을 읽을 수 없습니다.');
        return;
      }

      await _validateImage(bytes);
      if (!mounted) {
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${timestamp}_${currentCount + 1}.jpg';
      final draft = ProfilePhotoDraft.create(bytes: bytes, fileName: fileName, contentType: 'image/jpeg');

      context.read<ProfilePhotoBloc>().add(ProfilePhotoDraftAdded(draft: draft));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = '$error';
      _showSnackBar(message.startsWith('Exception: ') ? message.replaceFirst('Exception: ', '') : '사진 선택 중 오류가 발생했습니다.');
    }
  }

  Future<CroppedFile?> _cropImageToFourByFive(String sourcePath) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      maxWidth: 1080,
      maxHeight: 1350,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '사진 자르기', toolbarColor: const Color(0xFFFFC629), toolbarWidgetColor: Colors.black, initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: true),
        IOSUiSettings(title: '사진 자르기', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
      ],
    );
  }

  Future<void> _validateImage(List<int> bytes) async {
    final image = await decodeImageFromList(Uint8List.fromList(bytes));

    if (image.width < 320 || image.height < 320) {
      throw Exception('사진의 최소 해상도는 320px 이상이어야 합니다.');
    }

    final ratio = image.width / image.height;
    const targetRatio = 4 / 5;
    if ((ratio - targetRatio).abs() > 0.08) {
      throw Exception('사진 비율은 4:5에 맞춰주세요.');
    }
  }

  Future<void> _confirmDeletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 삭제'),
          content: const Text('선택한 사진을 목록에서 제거할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    context.read<ProfilePhotoBloc>().add(ProfilePhotoDraftRemoved(index: index));
  }

  void _popWithDrafts() {
    final state = context.read<ProfilePhotoBloc>().state;
    if (state.isSubmitting) {
      _showSnackBar('업로드 중에는 뒤로 갈 수 없습니다.');
      return;
    }

    final draftPhotos = state.draftPhotos.map((photo) => photo.clone()).toList(growable: false);
    Navigator.of(context).pop(draftPhotos);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoMosaicLayout extends StatelessWidget {
  const _PhotoMosaicLayout({required this.draftPhotos, required this.onAddPressed, required this.onDeletePressed});

  final List<ProfilePhotoDraft> draftPhotos;
  final VoidCallback? onAddPressed;
  final ValueChanged<int>? onDeletePressed;

  static const double _gap = 10;
  static const Map<int, Offset> _thumbnailGrid = <int, Offset>{1: Offset(2, 0), 2: Offset(2, 1), 3: Offset(0, 2), 4: Offset(1, 2), 5: Offset(2, 2)};

  @override
  Widget build(BuildContext context) {
    final representative = draftPhotos.isNotEmpty ? draftPhotos.first : null;

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
                child: _HeroPhotoCard(picture: representative, onAddPressed: onAddPressed, onDeletePressed: representative == null || onDeletePressed == null ? null : () => onDeletePressed!(0)),
              ),
              ..._thumbnailGrid.entries.map((entry) {
                final photoIndex = entry.key;
                final col = entry.value.dx;
                final row = entry.value.dy;

                return Positioned(left: col * (cell + _gap), top: row * (cell + _gap), width: cell, height: cell, child: _buildThumbnailSlot(photoIndex));
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnailSlot(int index) {
    if (index < draftPhotos.length) {
      final picture = draftPhotos[index];
      return _PhotoSlotFilled(picture: picture, onDelete: onDeletePressed == null ? null : () => onDeletePressed!(index));
    }

    return _PhotoSlotEmpty(onTap: onAddPressed);
  }
}

class _HeroPhotoCard extends StatelessWidget {
  const _HeroPhotoCard({required this.picture, required this.onAddPressed, required this.onDeletePressed});

  final ProfilePhotoDraft? picture;
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
              Image.memory(
                picture!.bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, _) => const ColoredBox(
                  color: Color(0xFFFFE36D),
                  child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.64), borderRadius: BorderRadius.circular(999)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '대표 사진',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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

class _PhotoSlotFilled extends StatelessWidget {
  const _PhotoSlotFilled({required this.picture, required this.onDelete});

  final ProfilePhotoDraft picture;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            picture.bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, _, _) => const ColoredBox(color: Color(0xFFFFE9A3), child: Icon(Icons.broken_image_outlined)),
          ),
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
