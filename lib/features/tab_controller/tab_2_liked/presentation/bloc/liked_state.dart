part of 'liked_bloc.dart';

enum LikedSegment { likedMe, likedMyPictures }

enum LikedFetchStatus { initial, loading, success, failure }

class LikedState extends Equatable {
  const LikedState({
    this.selectedSegment = LikedSegment.likedMe,
    this.likedMeStatus = LikedFetchStatus.initial,
    this.likedMyPicturesStatus = LikedFetchStatus.initial,
    this.likedMeMembers = const <Member>[],
    this.likedMyPicturesMembers = const <Member>[],
    this.likedMeErrorMessage,
    this.likedMyPicturesErrorMessage,
  });

  static const _unset = Object();

  final LikedSegment selectedSegment;
  final LikedFetchStatus likedMeStatus;
  final LikedFetchStatus likedMyPicturesStatus;
  final List<Member> likedMeMembers;
  final List<Member> likedMyPicturesMembers;
  final String? likedMeErrorMessage;
  final String? likedMyPicturesErrorMessage;

  LikedState copyWith({
    LikedSegment? selectedSegment,
    LikedFetchStatus? likedMeStatus,
    LikedFetchStatus? likedMyPicturesStatus,
    List<Member>? likedMeMembers,
    List<Member>? likedMyPicturesMembers,
    Object? likedMeErrorMessage = _unset,
    Object? likedMyPicturesErrorMessage = _unset,
  }) {
    return LikedState(
      selectedSegment: selectedSegment ?? this.selectedSegment,
      likedMeStatus: likedMeStatus ?? this.likedMeStatus,
      likedMyPicturesStatus: likedMyPicturesStatus ?? this.likedMyPicturesStatus,
      likedMeMembers: likedMeMembers ?? this.likedMeMembers,
      likedMyPicturesMembers: likedMyPicturesMembers ?? this.likedMyPicturesMembers,
      likedMeErrorMessage: identical(likedMeErrorMessage, _unset) ? this.likedMeErrorMessage : likedMeErrorMessage as String?,
      likedMyPicturesErrorMessage: identical(likedMyPicturesErrorMessage, _unset) ? this.likedMyPicturesErrorMessage : likedMyPicturesErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [selectedSegment, likedMeStatus, likedMyPicturesStatus, likedMeMembers, likedMyPicturesMembers, likedMeErrorMessage, likedMyPicturesErrorMessage];
}
