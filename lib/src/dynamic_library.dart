import 'dart:ffi';
import 'dart:io';

const String _libName = 'opus';

/// The dynamic library in which the symbols for [OpusBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

DynamicLibrary get dylib => _dylib;
