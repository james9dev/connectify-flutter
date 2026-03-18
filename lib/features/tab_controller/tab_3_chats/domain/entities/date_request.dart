enum DateRequestStatus { requested, accepted, rejected }

class DateRequest {
  const DateRequest({
    required this.id,
    required this.requesterMemberId,
    required this.requesterNickName,
    required this.receiverMemberId,
    required this.receiverNickName,
    required this.status,
    required this.requestMessage,
    required this.requestedAt,
    required this.respondedAt,
  });

  final int id;
  final int requesterMemberId;
  final String requesterNickName;
  final int receiverMemberId;
  final String receiverNickName;
  final DateRequestStatus status;
  final String? requestMessage;
  final DateTime? requestedAt;
  final DateTime? respondedAt;
}
