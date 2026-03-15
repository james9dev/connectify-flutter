import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ProfilePhotoDraft extends Equatable {
  final String id;
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  ProfilePhotoDraft({required this.id, required Uint8List bytes, required this.fileName, required this.contentType}) : bytes = Uint8List.fromList(bytes);

  factory ProfilePhotoDraft.create({required List<int> bytes, required String fileName, required String contentType}) {
    return ProfilePhotoDraft(id: DateTime.now().microsecondsSinceEpoch.toString(), bytes: Uint8List.fromList(bytes), fileName: fileName, contentType: contentType);
  }

  ProfilePhotoDraft clone() {
    return ProfilePhotoDraft(id: id, bytes: bytes, fileName: fileName, contentType: contentType);
  }

  @override
  List<Object?> get props => [id, fileName, contentType, bytes.length];
}
