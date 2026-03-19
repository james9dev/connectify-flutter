import 'package:connectify/features/member_profile/presentation/view/member_profile_detail_view.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:flutter/material.dart';

typedef MemberProfileLoader = Future<Member?> Function(int memberId);

const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _muted = Color(0xFF6B675D);

class MemberProfileDetailPage extends StatefulWidget {
  const MemberProfileDetailPage({
    super.key,
    required this.memberId,
    required this.loadMember,
    required this.fallbackName,
    this.isMemberLiked = false,
    this.isMatchRequestEnabled = true,
    this.likedPhotoIds = const <int>{},
    this.onMemberLikePressed,
    this.onMatchRequestPressed,
    this.onPhotoLikePressed,
    this.onReportPressed,
    this.onHidePressed,
  });

  final int memberId;
  final MemberProfileLoader loadMember;
  final String fallbackName;
  final bool isMemberLiked;
  final bool isMatchRequestEnabled;
  final Set<int> likedPhotoIds;
  final VoidCallback? onMemberLikePressed;
  final VoidCallback? onMatchRequestPressed;
  final ValueChanged<int>? onPhotoLikePressed;
  final VoidCallback? onReportPressed;
  final VoidCallback? onHidePressed;

  @override
  State<MemberProfileDetailPage> createState() => _MemberProfileDetailPageState();
}

class _MemberProfileDetailPageState extends State<MemberProfileDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Member? _member;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final member = await widget.loadMember(widget.memberId);
      if (!mounted) {
        return;
      }
      setState(() {
        _member = member;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _member = null;
        _isLoading = false;
        _errorMessage = '프로필을 불러오지 못했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName = _member?.profile.nickName?.trim().isNotEmpty == true ? _member!.profile.nickName!.trim() : widget.fallbackName.trim();

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(backgroundColor: _pageBackground, elevation: 0, centerTitle: false, title: Text(titleName.isEmpty ? '프로필' : titleName)),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ProfileMessageView(message: _errorMessage!, actionLabel: '다시 시도', onPressed: _load);
    }

    final member = _member;
    if (member == null) {
      return _ProfileMessageView(message: '프로필 정보가 없어요.', actionLabel: '뒤로가기', onPressed: () => Navigator.of(context).maybePop());
    }

    return MemberProfileDetailView(
      member: member,
      isMemberLiked: widget.isMemberLiked,
      isMatchRequestEnabled: widget.isMatchRequestEnabled,
      likedPhotoIds: widget.likedPhotoIds,
      onMemberLikePressed: widget.onMemberLikePressed,
      onMatchRequestPressed: widget.onMatchRequestPressed,
      onPhotoLikePressed: widget.onPhotoLikePressed,
      onReportPressed: widget.onReportPressed,
      onHidePressed: widget.onHidePressed,
      onRefresh: _load,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 16),
    );
  }
}

class _ProfileMessageView extends StatelessWidget {
  const _ProfileMessageView({required this.message, required this.actionLabel, required this.onPressed});

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4DCC0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _muted),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
