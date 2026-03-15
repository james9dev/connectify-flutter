part of 'explore_bloc.dart';

enum ExploreStatus { initial, loading, success, failure }

enum ExploreMemberDetailStatus { initial, loading, success, failure }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final ExploreMemberDetailStatus memberDetailStatus;
  final List<Member> members;
  final int? selectedMemberId;
  final Member? selectedMember;
  final Set<int> likedMemberIds;
  final Set<int> requestedMatchMemberIds;
  final Set<int> reportedMemberIds;
  final Set<int> hiddenMemberIds;
  final Map<int, Set<int>> likedPhotoIdsByMember;
  final String? noticeMessage;
  static const _unset = Object();

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.memberDetailStatus = ExploreMemberDetailStatus.initial,
    this.members = const <Member>[],
    this.selectedMemberId,
    this.selectedMember,
    this.likedMemberIds = const <int>{},
    this.requestedMatchMemberIds = const <int>{},
    this.reportedMemberIds = const <int>{},
    this.hiddenMemberIds = const <int>{},
    this.likedPhotoIdsByMember = const <int, Set<int>>{},
    this.noticeMessage,
  });

  ExploreState copyWith({
    ExploreStatus? status,
    ExploreMemberDetailStatus? memberDetailStatus,
    List<Member>? members,
    Object? selectedMemberId = _unset,
    Object? selectedMember = _unset,
    Set<int>? likedMemberIds,
    Set<int>? requestedMatchMemberIds,
    Set<int>? reportedMemberIds,
    Set<int>? hiddenMemberIds,
    Map<int, Set<int>>? likedPhotoIdsByMember,
    Object? noticeMessage = _unset,
  }) {
    return ExploreState(
      status: status ?? this.status,
      memberDetailStatus: memberDetailStatus ?? this.memberDetailStatus,
      members: members ?? this.members,
      selectedMemberId: identical(selectedMemberId, _unset) ? this.selectedMemberId : selectedMemberId as int?,
      selectedMember: identical(selectedMember, _unset) ? this.selectedMember : selectedMember as Member?,
      likedMemberIds: likedMemberIds ?? this.likedMemberIds,
      requestedMatchMemberIds: requestedMatchMemberIds ?? this.requestedMatchMemberIds,
      reportedMemberIds: reportedMemberIds ?? this.reportedMemberIds,
      hiddenMemberIds: hiddenMemberIds ?? this.hiddenMemberIds,
      likedPhotoIdsByMember: likedPhotoIdsByMember ?? this.likedPhotoIdsByMember,
      noticeMessage: identical(noticeMessage, _unset) ? this.noticeMessage : noticeMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    memberDetailStatus,
    members,
    selectedMemberId,
    selectedMember,
    likedMemberIds,
    requestedMatchMemberIds,
    reportedMemberIds,
    hiddenMemberIds,
    likedPhotoIdsByMember,
    noticeMessage,
  ];
}
