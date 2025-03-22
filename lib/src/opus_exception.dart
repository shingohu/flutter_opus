import 'dart:convert';
import 'dart:ffi' as ffi;

import 'opus_defines.dart';

/// Thrown when a native exception occurs.
class OpusException implements Exception {
  final int errorCode;

  const OpusException(this.errorCode);

  @override
  String toString() {
    String error = _asString(opus_defines.opus_strerror(errorCode));
    return 'OpusException $errorCode: $error';
  }
}

String _asString(ffi.Pointer<ffi.Char> pointer) {
  int i = 0;
  while ((pointer + i).value != 0) {
    i++;
  }
  final int8Pointer = pointer.cast<ffi.Int8>();

  // 从指针中提取字节数据
  final buffer = int8Pointer.asTypedList(i);

  // 将字节数据转换为 Dart 字符串
  final dartString = utf8.decode(buffer);
  return dartString;
}
