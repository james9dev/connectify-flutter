import 'package:json_annotation/json_annotation.dart';

part 'result_dto.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ResultDto<T> {
  final int resultCode;
  final String message;
  final T? data;

  ResultDto({required this.resultCode, required this.message, this.data});

  bool success() => resultCode >= 200 && resultCode <= 299;

  factory ResultDto.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => _$ResultDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => _$ResultDtoToJson(this, toJsonT);
}

@JsonSerializable(genericArgumentFactories: true)
class ListDto<T> {
  final int size;
  final int total;
  final List<T> values;

  ListDto({required this.size, required this.total, required this.values});

  factory ListDto.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => _$ListDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => _$ListDtoToJson(this, toJsonT);
}
