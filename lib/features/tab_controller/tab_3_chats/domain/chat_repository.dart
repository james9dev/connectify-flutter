import 'package:connectify/features/tab_controller/tab_3_chats/domain/entities/date_request.dart';
import 'package:connectify/shared/models/member.dart';

abstract class ChatRepository {
  Future<int> requestDate({required int receiverMemberId, String? requestMessage});
  Future<void> acceptDateRequest({required int dateRequestId});
  Future<void> rejectDateRequest({required int dateRequestId});
  Future<List<DateRequest>> getSentDateRequests({DateRequestStatus? status, int page = 0, int size = 20});
  Future<List<DateRequest>> getReceivedDateRequests({DateRequestStatus? status, int page = 0, int size = 20});
  Future<Member?> getMemberProfile({required int memberId});
}
