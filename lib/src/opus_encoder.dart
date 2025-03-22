import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'opus.dart';
import 'opus_defines.dart';
import 'opus_exception.dart';

/// Max bitstream size of a single opus packet.
///
/// See [here](https://stackoverflow.com/questions/55698317/what-value-to-use-for-libopus-encoder-max-data-bytes-field)
/// for an explanation how this was calculated.
const int maxDataBytes = 3 * 1275;

/// Represents the different apllication types an [OpusEncoder] supports.
/// Setting the right apllication type when creating an encoder can improve quality.
enum Application {
  voip(OPUS_APPLICATION_VOIP),
  audio(OPUS_APPLICATION_AUDIO),
  restrictedLowdely(OPUS_APPLICATION_RESTRICTED_LOWDELAY);

  final int flag;

  const Application(this.flag);
}

class SimpleOpusEncoder {
  final int sampleRate;
  final int channels;
  final Application application;

  ///码率 默认8kbit/s 每毫秒1个字节
  ///假设采样率8k，采样位数16bit，声道数1
  ///如果是60ms数据,那么每次encode后的数据长度为60字节 8000/8/1000*60
  ///fixed bitrate
  final int? bitrate;
  bool _disposed;

  final ffi.Pointer<OpusEncoder> _encoder;

  SimpleOpusEncoder._(this._encoder,
      {this.sampleRate = 8000,
      this.channels = 1,
      this.bitrate,
      this.application = Application.voip})
      : _disposed = false;

  factory SimpleOpusEncoder(
      {int sampleRate = 8000,
      int channels = 1,
      int? bitrate,
      Application application = Application.voip}) {
    return using((area) {
      ffi.Pointer<ffi.Int> error = area<ffi.Int>(1);
      ffi.Pointer<OpusEncoder> encoder = opus.opus_encoder_create(
          sampleRate, channels, application.flag, error);

      if (error.value == OPUS_OK) {
        if (bitrate != null) {
          opus.opus_encoder_ctl_int(encoder, OPUS_SET_VBR_REQUEST, 0);
          int ret1 = opus.opus_encoder_ctl_int(
              encoder, OPUS_SET_BITRATE_REQUEST, bitrate);
          if (ret1 != OPUS_OK) {
            throw OpusException(ret1);
          }
        }
        return SimpleOpusEncoder._(encoder,
            sampleRate: sampleRate,
            channels: channels,
            bitrate: bitrate,
            application: application);
      } else {
        throw OpusException(error.value);
      }
    });
  }

  /**
   * encode audio data to opus data
   * 输入音频帧大小(Int16List)
   * 以时间分割而得，在调用的时候必须使用的是恰好的一帧(2.5ms的倍数：2.5，5，10，20，40，60ms)的音频数据。
   * Fs/ms   2.5     5       10      20      40      60
   * 8kHz   20      40      80     160     320     480
   * 16kHz   40      80      160     320     640     960
   * 48kHz   120     240     480     960     1920    2880
   */
  Uint8List encode(
      {required Int16List input, int maxOutputSizeBytes = maxDataBytes}) {
    if (_disposed) throw OpusException(OPUS_INVALID_STATE);

    return using((area) {
      ffi.Pointer<ffi.Int16> inputNative = area<ffi.Int16>(input.length);
      inputNative.asTypedList(input.length).setAll(0, input);
      ffi.Pointer<ffi.Uint8> outputNative = area<ffi.Uint8>(maxOutputSizeBytes);
      int sampleCountPerChannel = input.length ~/ channels;
      int outputLength = opus.opus_encode(
          _encoder,
          inputNative,
          sampleCountPerChannel,
          outputNative.cast<ffi.UnsignedChar>(),
          maxOutputSizeBytes);

      if (outputLength >= OPUS_OK) {
        Uint8List output =
            Uint8List.fromList(outputNative.asTypedList(outputLength));
        return output;
      } else {
        throw OpusException(outputLength);
      }
    });
  }

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      opus.opus_encoder_destroy(_encoder);
    }
  }
}
