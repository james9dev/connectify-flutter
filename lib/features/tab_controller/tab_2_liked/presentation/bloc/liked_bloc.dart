import 'package:bloc/bloc.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/domain/liked_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

part 'liked_event.dart';
part 'liked_state.dart';

class LikedBloc extends Bloc<LikedEvent, LikedState> {
  LikedBloc(this._likedRepository) : super(const LikedState()) {
    on<LikedStarted>(_onStarted);
    on<LikedSegmentChanged>(_onSegmentChanged);
    on<LikedRefreshRequested>(_onRefreshRequested);
  }

  final LikedRepository _likedRepository;

  Future<void> _onStarted(LikedStarted event, Emitter<LikedState> emit) async {
    await _loadSegment(emit, state.selectedSegment, forceReload: true);
  }

  Future<void> _onSegmentChanged(LikedSegmentChanged event, Emitter<LikedState> emit) async {
    if (state.selectedSegment == event.segment) {
      return;
    }

    emit(state.copyWith(selectedSegment: event.segment));

    if (_statusFor(event.segment) == LikedFetchStatus.initial) {
      await _loadSegment(emit, event.segment, forceReload: true);
    }
  }

  Future<void> _onRefreshRequested(LikedRefreshRequested event, Emitter<LikedState> emit) async {
    final targetSegment = event.segment ?? state.selectedSegment;
    await _loadSegment(emit, targetSegment, forceReload: true);
  }

  Future<void> _loadSegment(Emitter<LikedState> emit, LikedSegment segment, {required bool forceReload}) async {
    final currentStatus = _statusFor(segment);
    if (!forceReload && currentStatus == LikedFetchStatus.loading) {
      return;
    }

    emit(_updateSegmentStatus(state, segment: segment, status: LikedFetchStatus.loading, errorMessage: null));

    try {
      final members = await _loadMembersBySegment(segment);
      emit(_updateSegmentData(state, segment: segment, status: LikedFetchStatus.success, members: members, errorMessage: null));
    } catch (error) {
      emit(_updateSegmentStatus(state, segment: segment, status: LikedFetchStatus.failure, errorMessage: _normalizeErrorMessage(error)));
    }
  }

  LikedFetchStatus _statusFor(LikedSegment segment) {
    switch (segment) {
      case LikedSegment.likedMe:
        return state.likedMeStatus;
      case LikedSegment.likedMyPictures:
        return state.likedMyPicturesStatus;
    }
  }

  Future<List<Member>> _loadMembersBySegment(LikedSegment segment) {
    switch (segment) {
      case LikedSegment.likedMe:
        return _likedRepository.getMembersWhoLikedMe();
      case LikedSegment.likedMyPictures:
        return _likedRepository.getMembersWhoLikedMyPictures();
    }
  }

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return '목록을 불러오지 못했어요.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }

  LikedState _updateSegmentStatus(LikedState source, {required LikedSegment segment, required LikedFetchStatus status, required String? errorMessage}) {
    switch (segment) {
      case LikedSegment.likedMe:
        return source.copyWith(likedMeStatus: status, likedMeErrorMessage: errorMessage);
      case LikedSegment.likedMyPictures:
        return source.copyWith(likedMyPicturesStatus: status, likedMyPicturesErrorMessage: errorMessage);
    }
  }

  LikedState _updateSegmentData(LikedState source, {required LikedSegment segment, required LikedFetchStatus status, required List<Member> members, required String? errorMessage}) {
    switch (segment) {
      case LikedSegment.likedMe:
        return source.copyWith(likedMeStatus: status, likedMeMembers: members, likedMeErrorMessage: errorMessage);
      case LikedSegment.likedMyPictures:
        return source.copyWith(likedMyPicturesStatus: status, likedMyPicturesMembers: members, likedMyPicturesErrorMessage: errorMessage);
    }
  }
}
