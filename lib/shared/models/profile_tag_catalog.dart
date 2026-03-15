import 'package:json_annotation/json_annotation.dart';

part 'profile_tag_catalog.g.dart';

@JsonSerializable()
class ProfileTagCatalog {
  @JsonKey(defaultValue: 3)
  final int maxProfileTagsPerCategory;

  @JsonKey(defaultValue: 5)
  final int maxPreferredTags;

  @JsonKey(defaultValue: <ProfileTagCategory>[])
  final List<ProfileTagCategory> categories;

  const ProfileTagCatalog({required this.maxProfileTagsPerCategory, required this.maxPreferredTags, required this.categories});

  factory ProfileTagCatalog.fromJson(Map<String, dynamic> json) => _$ProfileTagCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileTagCatalogToJson(this);
}

@JsonSerializable()
class ProfileTagCategory {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(defaultValue: '')
  final String name;

  final String? description;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  @JsonKey(defaultValue: <ProfileTag>[])
  final List<ProfileTag> tags;

  const ProfileTagCategory({required this.id, required this.code, required this.name, required this.description, required this.sortOrder, required this.tags});

  factory ProfileTagCategory.fromJson(Map<String, dynamic> json) => _$ProfileTagCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileTagCategoryToJson(this);
}

@JsonSerializable()
class ProfileTag {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: 0)
  final int categoryId;

  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(defaultValue: '')
  final String name;

  final String? description;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  const ProfileTag({required this.id, required this.categoryId, required this.code, required this.name, required this.description, required this.sortOrder});

  factory ProfileTag.fromJson(Map<String, dynamic> json) => _$ProfileTagFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileTagToJson(this);
}
