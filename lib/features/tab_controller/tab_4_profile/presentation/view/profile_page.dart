import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_bloc.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:connectify/shared/authentication/bloc/authentication_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProfileBloc(getIt<ProfileRepository>())..add(ProfileLoaded()), child: const ProfileView());
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.select((AuthenticationBloc bloc) => bloc.state.user);
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) {
            final uploadDone =
                previous.photoUploadStatus != current.photoUploadStatus &&
                (current.photoUploadStatus == ProfilePhotoUploadStatus.success || current.photoUploadStatus == ProfilePhotoUploadStatus.failure);
            final deleteDone =
                previous.photoDeleteStatus != current.photoDeleteStatus &&
                (current.photoDeleteStatus == ProfilePhotoDeleteStatus.success || current.photoDeleteStatus == ProfilePhotoDeleteStatus.failure);
            return uploadDone || deleteDone;
          },
          listener: (context, state) {
            if (state.photoUploadStatus == ProfilePhotoUploadStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 사진 업로드가 완료되었습니다.')));
            }

            if (state.photoUploadStatus == ProfilePhotoUploadStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.photoUploadErrorMessage ?? '프로필 사진 업로드에 실패했습니다.')));
            }

            if (state.photoDeleteStatus == ProfilePhotoDeleteStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 사진이 삭제되었습니다.')));
            }

            if (state.photoDeleteStatus == ProfilePhotoDeleteStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.photoDeleteErrorMessage ?? '프로필 사진 삭제에 실패했습니다.')));
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.loading && authUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ProfileStatus.failure && authUser == null) {
              return const Center(child: Text('프로필 정보를 불러오지 못했습니다.'));
            }

            final user = state.profile ?? authUser;

            return Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [const _LogoutButton(), const SizedBox(width: 24)]),
                _UserId(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    child: user != null
                        ? _ProfileInfoView(
                            member: user,
                            isUploading: state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress,
                            isDeleting: state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Logout'),
      onPressed: () {
        context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed());
      },
    );
  }
}

class _UserId extends StatelessWidget {
  const _UserId({this.user});
  final Member? user;

  @override
  Widget build(BuildContext context) {
    final userId = user?.id;
    final name = user?.name;

    return Text('UserID: $userId, UserName: $name');
  }
}

class _ProfileInfoView extends StatefulWidget {
  final Member member;
  final bool isUploading;
  final bool isDeleting;

  const _ProfileInfoView({required this.member, required this.isUploading, required this.isDeleting});

  @override
  State<_ProfileInfoView> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<_ProfileInfoView> {
  static final ImagePicker _imagePicker = ImagePicker();

  Member get member => widget.member;

  int current = 0;

  bool get _isBusy => widget.isUploading || widget.isDeleting;

  @override
  Widget build(BuildContext context) {
    final pictures = member.profile.orderedPictures;
    final currentIndex = pictures.isEmpty ? 0 : (current >= pictures.length ? pictures.length - 1 : current);
    final currentPosition = pictures.isEmpty ? 0.0 : currentIndex.toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(member.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),

          Text('${member.profile.age()}세 • ${member.profile.location}', style: const TextStyle(fontSize: 18, color: Colors.grey)),

          const SizedBox(height: 24),

          // -------------------------------
          // 🖼 프로필 이미지 슬라이더
          // -------------------------------
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (pictures.isEmpty)
                    _EmptyPicturePlaceholder(onUploadPressed: _isBusy ? null : _pickAndUploadPhoto)
                  else
                    PageView.builder(
                      key: ValueKey(pictures.length),
                      itemCount: pictures.length,
                      onPageChanged: (index) => setState(() {
                        current = index;
                      }),
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: pictures[index].imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, _, _) => const ColoredBox(
                            color: Color(0xFFEAEAEA),
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        );
                      },
                    ),
                  if (pictures.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : () => _confirmAndDeleteCurrentPhoto(pictures[currentIndex].id),
                        icon: widget.isDeleting ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete),
                        label: const Text('삭제'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      ),
                    ),
                  if (pictures.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: DotsIndicator(
                          dotsCount: pictures.length,
                          position: currentPosition,
                          decorator: const DotsDecorator(color: Colors.grey, activeColor: Colors.pink),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _pickAndUploadPhoto,
                      icon: widget.isUploading ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo),
                      label: Text(widget.isUploading ? '업로드중' : '사진 추가'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                    ),
                  ),
                  if (_isBusy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Text('Bio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ],
          ),
          Text(member.profile.bio ?? "안녕하세요!\n${member.profile.nickName} 입니다. 😊", style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.left),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final selected = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1440);
      if (!mounted || selected == null) {
        return;
      }

      final fileName = selected.name.isNotEmpty ? selected.name : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final contentType = _resolveSupportedContentType(fileName);
      if (contentType == null) {
        _showSnackBar('지원하지 않는 파일 형식입니다. (jpg, png, webp)');
        return;
      }

      final bytes = await selected.readAsBytes();
      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        _showSnackBar('선택한 이미지가 비어 있습니다.');
        return;
      }

      context.read<ProfileBloc>().add(ProfilePhotoUploadRequested(imageBytes: bytes, fileName: fileName, contentType: contentType));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('사진 선택 중 오류가 발생했습니다.');
    }
  }

  Future<void> _confirmAndDeleteCurrentPhoto(int pictureId) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 삭제'),
          content: const Text('선택한 프로필 사진을 삭제할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
          ],
        );
      },
    );

    if (!mounted || isConfirmed != true) {
      return;
    }

    context.read<ProfileBloc>().add(ProfilePhotoDeleteRequested(pictureId: pictureId));
  }

  String? _resolveSupportedContentType(String fileName) {
    final split = fileName.split('.');
    if (split.length < 2) {
      return null;
    }

    final ext = split.last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyPicturePlaceholder extends StatelessWidget {
  final VoidCallback? onUploadPressed;

  const _EmptyPicturePlaceholder({required this.onUploadPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_outlined, size: 52, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('등록된 프로필 사진이 없습니다.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onUploadPressed, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('사진 업로드')),
        ],
      ),
    );
  }
}
