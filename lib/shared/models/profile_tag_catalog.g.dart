// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_tag_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileTagCatalog _$ProfileTagCatalogFromJson(Map<String, dynamic> json) => ProfileTagCatalog(
  maxProfileTagsPerCategory: (json['maxProfileTagsPerCategory'] as num?)?.toInt() ?? 3,
  maxPreferredTags: (json['maxPreferredTags'] as num?)?.toInt() ?? 5,
  categories: (json['categories'] as List<dynamic>?)?.map((e) => ProfileTagCategory.fromJson(e as Map<String, dynamic>)).toList() ?? [],
);

Map<String, dynamic> _$ProfileTagCatalogToJson(ProfileTagCatalog instance) => <String, dynamic>{
  'maxProfileTagsPerCategory': instance.maxProfileTagsPerCategory,
  'maxPreferredTags': instance.maxPreferredTags,
  'categories': instance.categories,
};

ProfileTagCategory _$ProfileTagCategoryFromJson(Map<String, dynamic> json) => ProfileTagCategory(
  id: (json['id'] as num?)?.toInt() ?? 0,
  code: json['code'] as String? ?? '',
  name: json['name'] as String? ?? '',
  description: json['description'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => ProfileTag.fromJson(e as Map<String, dynamic>)).toList() ?? [],
);

Map<String, dynamic> _$ProfileTagCategoryToJson(ProfileTagCategory instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'sortOrder': instance.sortOrder,
  'tags': instance.tags,
};

ProfileTag _$ProfileTagFromJson(Map<String, dynamic> json) => ProfileTag(
  id: (json['id'] as num?)?.toInt() ?? 0,
  categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
  code: json['code'] as String? ?? '',
  name: json['name'] as String? ?? '',
  description: json['description'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProfileTagToJson(ProfileTag instance) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'sortOrder': instance.sortOrder,
};
