// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultDto<T> _$ResultDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ResultDto<T>(
  resultCode: (json['resultCode'] as num).toInt(),
  message: json['message'] as String,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

Map<String, dynamic> _$ResultDtoToJson<T>(
  ResultDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'resultCode': instance.resultCode,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

ListDto<T> _$ListDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ListDto<T>(
  size: (json['size'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  values: (json['values'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$ListDtoToJson<T>(
  ListDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'size': instance.size,
  'total': instance.total,
  'values': instance.values.map(toJsonT).toList(),
};
