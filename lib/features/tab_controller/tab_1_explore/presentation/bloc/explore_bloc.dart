import 'package:bloc/bloc.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final MemberRepository repository;

  ExploreBloc(this.repository) : super(const ExploreState()) {
    on<ExploreLoaded>(_onLoaded);
    on<MemberSelected>(_onSelected);
    on<MemberLikePressed>(_onMemberLikePressed);
    on<PhotoLikePressed>(_onPhotoLikePressed);
    on<MatchRequestPressed>(_onMatchRequestPressed);
    on<MemberReported>(_onMemberReported);
    on<MemberHidden>(_onMemberHidden);
    on<ExploreNoticeCleared>(_onNoticeCleared);
  }

  Future<void> _onLoaded(ExploreLoaded event, Emitter<ExploreState> emit) async {
    emit(state.copyWith(status: ExploreStatus.loading, memberDetailStatus: ExploreMemberDetailStatus.initial, noticeMessage: null));

    try {
      final members = await repository.fetchMembers();
      if (members.isEmpty) {
        emit(state.copyWith(status: ExploreStatus.success, members: const <Member>[], selectedMemberId: null, selectedMember: null, memberDetailStatus: ExploreMemberDetailStatus.initial));
        return;
      }

      final firstMember = members.first;
      emit(state.copyWith(status: ExploreStatus.success, members: members, selectedMemberId: firstMember.id, selectedMember: firstMember, memberDetailStatus: ExploreMemberDetailStatus.loading));

      await _loadMemberDetail(memberId: firstMember.id, fallback: firstMember, emit: emit);
    } catch (_) {
      emit(state.copyWith(status: ExploreStatus.failure, memberDetailStatus: ExploreMemberDetailStatus.initial));
    }
  }

  Future<void> _onSelected(MemberSelected event, Emitter<ExploreState> emit) async {
    if (event.memberId == null) {
      emit(state.copyWith(selectedMemberId: null, selectedMember: null, memberDetailStatus: ExploreMemberDetailStatus.initial));
      return;
    }

    final memberId = event.memberId!;
    final fallbackMember = _findMemberById(memberId);

    emit(state.copyWith(selectedMemberId: memberId, selectedMember: fallbackMember, memberDetailStatus: ExploreMemberDetailStatus.loading));

    await _loadMemberDetail(memberId: memberId, fallback: fallbackMember, emit: emit);
  }

  Future<void> _onMemberLikePressed(MemberLikePressed event, Emitter<ExploreState> emit) async {
    final isCurrentlyLiked = _isMemberLiked(event.memberId);

    try {
      if (isCurrentlyLiked) {
        await repository.cancelMemberLike(memberId: event.memberId);
      } else {
        await repository.likeMember(memberId: event.memberId);
      }

      final nextLiked = <int>{...state.likedMemberIds};
      if (isCurrentlyLiked) {
        nextLiked.remove(event.memberId);
      } else {
        nextLiked.add(event.memberId);
      }

      final updatedSelected = _updateSelectedMemberLikeStatus(memberId: event.memberId, isLiked: !isCurrentlyLiked);
      emit(
        state.copyWith(
          likedMemberIds: nextLiked,
          selectedMember: updatedSelected,
          members: _replaceMemberInList(updatedSelected),
          noticeMessage: isCurrentlyLiked ? '회원 좋아요를 취소했어요.' : '회원 좋아요를 보냈어요.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(noticeMessage: isCurrentlyLiked ? '회원 좋아요 취소에 실패했습니다.' : '회원 좋아요에 실패했습니다.'));
    }
  }

  Future<void> _onPhotoLikePressed(PhotoLikePressed event, Emitter<ExploreState> emit) async {
    final currentLikedPhotos = state.likedPhotoIdsByMember[event.memberId] ?? const <int>{};

    final isCurrentlyLiked = _isPictureLiked(memberId: event.memberId, pictureId: event.pictureId);
    try {
      if (isCurrentlyLiked) {
        await repository.unlikeProfilePhoto(pictureId: event.pictureId);
      } else {
        await repository.likeProfilePhoto(pictureId: event.pictureId);
      }

      final copiedMap = _copyLikedPhotoMap(state.likedPhotoIdsByMember);
      final nextForMember = <int>{...currentLikedPhotos};
      if (isCurrentlyLiked) {
        nextForMember.remove(event.pictureId);
      } else {
        nextForMember.add(event.pictureId);
      }

      if (nextForMember.isEmpty) {
        copiedMap.remove(event.memberId);
      } else {
        copiedMap[event.memberId] = nextForMember;
      }

      final updatedSelected = _updateSelectedPictureLikeStatus(memberId: event.memberId, pictureId: event.pictureId, isLiked: !isCurrentlyLiked);
      emit(
        state.copyWith(
          likedPhotoIdsByMember: copiedMap,
          selectedMember: updatedSelected,
          members: _replaceMemberInList(updatedSelected),
          noticeMessage: isCurrentlyLiked ? '사진 좋아요를 취소했어요.' : '현재 사진에 좋아요를 보냈어요.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(noticeMessage: isCurrentlyLiked ? '사진 좋아요 취소에 실패했습니다.' : '사진 좋아요에 실패했습니다.'));
    }
  }

  void _onMatchRequestPressed(MatchRequestPressed event, Emitter<ExploreState> emit) {
    if (state.requestedMatchMemberIds.contains(event.memberId)) {
      emit(state.copyWith(noticeMessage: '이미 데이트 요청을 보낸 회원입니다.'));
      return;
    }

    final nextRequested = <int>{...state.requestedMatchMemberIds, event.memberId};
    emit(state.copyWith(requestedMatchMemberIds: nextRequested, noticeMessage: '데이트 요청을 보냈어요.'));
  }

  void _onMemberReported(MemberReported event, Emitter<ExploreState> emit) {
    if (state.reportedMemberIds.contains(event.memberId)) {
      emit(state.copyWith(noticeMessage: '이미 신고 처리한 회원입니다.'));
      return;
    }

    final nextReported = <int>{...state.reportedMemberIds, event.memberId};
    emit(state.copyWith(reportedMemberIds: nextReported, noticeMessage: '신고가 접수되었습니다.'));
  }

  Future<void> _onMemberHidden(MemberHidden event, Emitter<ExploreState> emit) async {
    if (state.hiddenMemberIds.contains(event.memberId)) {
      emit(state.copyWith(noticeMessage: '이미 숨긴 회원입니다.'));
      return;
    }

    final nextHidden = <int>{...state.hiddenMemberIds, event.memberId};
    final visibleMembers = state.members.where((member) => member.id != event.memberId).toList(growable: false);

    if (visibleMembers.isEmpty) {
      emit(
        state.copyWith(
          members: const <Member>[],
          hiddenMemberIds: nextHidden,
          selectedMemberId: null,
          selectedMember: null,
          memberDetailStatus: ExploreMemberDetailStatus.initial,
          noticeMessage: '회원을 숨겼습니다.',
        ),
      );
      return;
    }

    if (state.selectedMemberId == event.memberId) {
      final nextSelected = visibleMembers.first;
      emit(
        state.copyWith(
          members: visibleMembers,
          hiddenMemberIds: nextHidden,
          selectedMemberId: nextSelected.id,
          selectedMember: nextSelected,
          memberDetailStatus: ExploreMemberDetailStatus.loading,
          noticeMessage: '회원을 숨겼습니다.',
        ),
      );

      await _loadMemberDetail(memberId: nextSelected.id, fallback: nextSelected, emit: emit);
      return;
    }

    emit(state.copyWith(members: visibleMembers, hiddenMemberIds: nextHidden, noticeMessage: '회원을 숨겼습니다.'));
  }

  void _onNoticeCleared(ExploreNoticeCleared event, Emitter<ExploreState> emit) {
    emit(state.copyWith(noticeMessage: null));
  }

  Future<void> _loadMemberDetail({required int memberId, required Member? fallback, required Emitter<ExploreState> emit}) async {
    try {
      final detail = await repository.getMember(memberId.toString());
      if (state.selectedMemberId != memberId) {
        return;
      }

      if (detail != null) {
        final nextLikedMembers = <int>{...state.likedMemberIds};
        if (detail.profile.memberLikeStatus) {
          nextLikedMembers.add(detail.id);
        } else {
          nextLikedMembers.remove(detail.id);
        }

        final nextLikedPhotos = _copyLikedPhotoMap(state.likedPhotoIdsByMember);
        final likedPictureIds = detail.profile.pictures.where((picture) => picture.pictureLikeStatus).map((picture) => picture.id).toSet();
        if (likedPictureIds.isEmpty) {
          nextLikedPhotos.remove(detail.id);
        } else {
          nextLikedPhotos[detail.id] = likedPictureIds;
        }

        emit(
          state.copyWith(
            memberDetailStatus: ExploreMemberDetailStatus.success,
            selectedMember: detail,
            members: _replaceMemberInList(detail),
            likedMemberIds: nextLikedMembers,
            likedPhotoIdsByMember: nextLikedPhotos,
          ),
        );
        return;
      }

      emit(state.copyWith(memberDetailStatus: ExploreMemberDetailStatus.failure, selectedMember: fallback, noticeMessage: '회원 상세 정보를 불러오지 못했습니다.'));
    } catch (_) {
      if (state.selectedMemberId != memberId) {
        return;
      }
      emit(state.copyWith(memberDetailStatus: ExploreMemberDetailStatus.failure, selectedMember: fallback, noticeMessage: '회원 상세 정보를 불러오지 못했습니다.'));
    }
  }

  Member? _findMemberById(int memberId) {
    for (final member in state.members) {
      if (member.id == memberId) {
        return member;
      }
    }
    return null;
  }

  bool _isMemberLiked(int memberId) {
    if (state.likedMemberIds.contains(memberId)) {
      return true;
    }

    final selected = state.selectedMember;
    if (selected != null && selected.id == memberId) {
      return selected.profile.memberLikeStatus;
    }

    final cached = _findMemberById(memberId);
    return cached?.profile.memberLikeStatus ?? false;
  }

  bool _isPictureLiked({required int memberId, required int pictureId}) {
    final likedFromState = state.likedPhotoIdsByMember[memberId];
    if (likedFromState != null && likedFromState.contains(pictureId)) {
      return true;
    }

    final selected = state.selectedMember;
    if (selected != null && selected.id == memberId) {
      return selected.profile.pictures.any((picture) => picture.id == pictureId && picture.pictureLikeStatus);
    }

    final cached = _findMemberById(memberId);
    if (cached == null) {
      return false;
    }

    return cached.profile.pictures.any((picture) => picture.id == pictureId && picture.pictureLikeStatus);
  }

  Member? _updateSelectedMemberLikeStatus({required int memberId, required bool isLiked}) {
    final selected = state.selectedMember;
    if (selected == null || selected.id != memberId) {
      return selected;
    }

    return selected.copyWith(profile: selected.profile.copyWith(memberLikeStatus: isLiked));
  }

  Member? _updateSelectedPictureLikeStatus({required int memberId, required int pictureId, required bool isLiked}) {
    final selected = state.selectedMember;
    if (selected == null || selected.id != memberId) {
      return selected;
    }

    final nextPictures = selected.profile.pictures.map((picture) => picture.id == pictureId ? picture.copyWith(pictureLikeStatus: isLiked) : picture).toList(growable: false);

    return selected.copyWith(profile: selected.profile.copyWith(pictures: nextPictures));
  }

  List<Member> _replaceMemberInList(Member? updatedMember) {
    if (updatedMember == null) {
      return state.members;
    }

    return state.members.map((member) => member.id == updatedMember.id ? updatedMember : member).toList(growable: false);
  }

  Map<int, Set<int>> _copyLikedPhotoMap(Map<int, Set<int>> source) {
    final copied = <int, Set<int>>{};
    for (final entry in source.entries) {
      copied[entry.key] = <int>{...entry.value};
    }
    return copied;
  }
}
