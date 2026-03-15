import 'package:connectify/shared/models/member.dart';
import 'package:connectify/shared/models/profile_tag_catalog.dart';
import 'package:equatable/equatable.dart';

enum ProfileBasicInfoCatalogStatus { initial, loading, success, failure }

enum ProfileBasicInfoSubmitStatus { initial, inProgress, success, failure }

class ProfileBasicInfoState extends Equatable {
  static const _unset = Object();

  final ProfileBasicInfoCatalogStatus catalogStatus;
  final ProfileBasicInfoSubmitStatus submitStatus;
  final ProfileTagCatalog? catalog;
  final List<String> regions;

  final String nickname;
  final String bio;
  final String? region;
  final GenderType? gender;
  final DateTime? birthDate;

  final Map<int, Set<int>> selectedProfileTagIdsByCategory;
  final Set<int> selectedPreferredTagIds;

  final bool showValidationErrors;

  final String? catalogErrorMessage;
  final String? submitErrorMessage;
  final String? noticeMessage;

  const ProfileBasicInfoState({
    this.catalogStatus = ProfileBasicInfoCatalogStatus.initial,
    this.submitStatus = ProfileBasicInfoSubmitStatus.initial,
    this.catalog,
    this.regions = const <String>[],
    this.nickname = '',
    this.bio = '',
    this.region,
    this.gender,
    this.birthDate,
    this.selectedProfileTagIdsByCategory = const <int, Set<int>>{},
    this.selectedPreferredTagIds = const <int>{},
    this.showValidationErrors = false,
    this.catalogErrorMessage,
    this.submitErrorMessage,
    this.noticeMessage,
  });

  int get maxProfileTagsPerCategory => catalog?.maxProfileTagsPerCategory ?? 3;

  int get maxPreferredTags => catalog?.maxPreferredTags ?? 5;

  bool get isCatalogReady => catalogStatus == ProfileBasicInfoCatalogStatus.success && catalog != null;

  bool get isSubmitting => submitStatus == ProfileBasicInfoSubmitStatus.inProgress;

  List<int> get selectedProfileTagIds {
    final ids = selectedProfileTagIdsByCategory.values.expand((tagIds) => tagIds).toList(growable: false);
    ids.sort();
    return ids;
  }

  List<ProfileTag> get allTags {
    final categories = catalog?.categories ?? const <ProfileTagCategory>[];
    final tags = <ProfileTag>[];

    for (final category in categories) {
      tags.addAll(category.tags);
    }

    return tags;
  }

  bool get isNicknameValid {
    final value = nickname.trim();
    return value.length >= 2 && value.length <= 20;
  }

  bool get isBioValid => bio.trim().length <= 120;

  bool get isStep1Valid {
    return isCatalogReady && !isSubmitting && isNicknameValid && gender != null && birthDate != null && (region?.isNotEmpty ?? false);
  }

  bool get isStep2Valid {
    return isCatalogReady && !isSubmitting && selectedProfileTagIds.isNotEmpty;
  }

  bool get isStep3Valid => isBioValid;

  bool get isFormValid {
    return isStep1Valid && isStep2Valid && isStep3Valid;
  }

  bool get canTapSubmit => isFormValid;

  ProfileBasicInfoState copyWith({
    ProfileBasicInfoCatalogStatus? catalogStatus,
    ProfileBasicInfoSubmitStatus? submitStatus,
    Object? catalog = _unset,
    List<String>? regions,
    String? nickname,
    String? bio,
    Object? region = _unset,
    Object? gender = _unset,
    Object? birthDate = _unset,
    Map<int, Set<int>>? selectedProfileTagIdsByCategory,
    Set<int>? selectedPreferredTagIds,
    bool? showValidationErrors,
    Object? catalogErrorMessage = _unset,
    Object? submitErrorMessage = _unset,
    Object? noticeMessage = _unset,
  }) {
    return ProfileBasicInfoState(
      catalogStatus: catalogStatus ?? this.catalogStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      catalog: identical(catalog, _unset) ? this.catalog : catalog as ProfileTagCatalog?,
      regions: regions ?? this.regions,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      region: identical(region, _unset) ? this.region : region as String?,
      gender: identical(gender, _unset) ? this.gender : gender as GenderType?,
      birthDate: identical(birthDate, _unset) ? this.birthDate : birthDate as DateTime?,
      selectedProfileTagIdsByCategory: selectedProfileTagIdsByCategory ?? this.selectedProfileTagIdsByCategory,
      selectedPreferredTagIds: selectedPreferredTagIds ?? this.selectedPreferredTagIds,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      catalogErrorMessage: identical(catalogErrorMessage, _unset) ? this.catalogErrorMessage : catalogErrorMessage as String?,
      submitErrorMessage: identical(submitErrorMessage, _unset) ? this.submitErrorMessage : submitErrorMessage as String?,
      noticeMessage: identical(noticeMessage, _unset) ? this.noticeMessage : noticeMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    catalogStatus,
    submitStatus,
    catalog,
    regions,
    nickname,
    bio,
    region,
    gender,
    birthDate,
    selectedProfileTagIdsByCategory,
    selectedPreferredTagIds,
    showValidationErrors,
    catalogErrorMessage,
    submitErrorMessage,
    noticeMessage,
  ];
}
