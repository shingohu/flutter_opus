import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'opus.dart';
import 'opus_defines.dart';
import 'opus_exception.dart';

int _packetDuration(int samples, int channels, int sampleRate) =>
    ((1000 * samples) ~/ (channels)) ~/ sampleRate;

int _durationToSamples(int duration, int channels, int sampleRate) =>
    duration * channels * sampleRate ~/ 1000;

/// Calculates, how much sampels a single opus package at [sampleRate] with [channels] may contain.
///
/// A single package may contain up 120ms of audio. This value is reached by combining up to 3 frames of 40ms audio.
int maxSamplesPerPacket(int sampleRate, int channels) => ((sampleRate *
            channels *
            120) /
        1000)
    .ceil(); //Some sample rates may not be dividable by 1000, so use ceiling instead of integer division.

class SimpleOpusDecoder {
  final int sampleRate;
  final int channels;
  final ffi.Pointer<OpusDecoder> _decoder;
  bool _disposed;

  int? get lastPacketDurationMs => _lastPacketDurationMs;
  int? _lastPacketDurationMs;
  final int _maxSamplesPerPacket;

  SimpleOpusDecoder._(this._decoder,
      {this.sampleRate = 8000, this.channels = 1})
      : _disposed = false,
        this._maxSamplesPerPacket = maxSamplesPerPacket(sampleRate, channels);

  factory SimpleOpusDecoder({int sampleRate = 8000, int channels = 1}) {
    return using((area) {
      ffi.Pointer<ffi.Int> error = area<ffi.Int>(1);
      ffi.Pointer<OpusDecoder> encoder =
          opus.opus_decoder_create(sampleRate, channels, error);

      if (error.value == OPUS_OK) {
        return SimpleOpusDecoder._(encoder,
            sampleRate: sampleRate, channels: channels);
      } else {
        throw OpusException(error.value);
      }
    });
  }

  /// Decodes an opus packet to s16le samples, represented as [Int16List].
  /// Use `null` as [input] to indicate packet loss.
  ///
  /// On packet loss, the [loss] parameter needs to be exactly the duration
  /// of audio that is missing in milliseconds, otherwise the decoder will
  /// not be in the optimal state to decode the next incoming packet.
  /// If you don't know the duration, leave it `null` and [lastPacketDurationMs]
  /// will be used as an estimate instead.
  ///
  /// If you want to use forward error correction, don't report packet loss
  /// by calling this method with `null` as input (unless it is a real packet
  /// loss), but instead, wait for the next packet and call this method with
  /// the recieved packet, [fec] set to `true` and [loss] to the missing duration
  /// of the missing audio in ms (as above). Then, call this method a second time with
  /// the same packet, but with [fec] set to `false`. You can read more about the
  /// correct usage of forward error correction [here](https://stackoverflow.com/questions/49427579/how-to-use-fec-feature-for-opus-codec).
  /// Note: A real packet loss occurse if you lose two or more packets in a row.
  /// You are only able to restore the last lost packet and the other packets are
  /// really lost. So for them, you have to report packet loss.
  ///
  /// The input bytes need to represent a whole packet!
  Int16List decode({Uint8List? input, bool fec = false, int? loss}) {
    if (_disposed) throw OpusException(OPUS_INVALID_STATE);
    return using((area) {
      ffi.Pointer<ffi.Int16> outputNative =
          area<ffi.Int16>(_maxSamplesPerPacket);
      ffi.Pointer<ffi.Uint8> inputNative;
      if (input != null) {
        inputNative = area<ffi.Uint8>(input.length);
        inputNative.asTypedList(input.length).setAll(0, input);
      } else {
        inputNative = ffi.nullptr;
      }
      int frameSize;
      if (input == null || fec) {
        frameSize = _durationToSamples(
            _estimateLoss(loss, lastPacketDurationMs), channels, sampleRate);
      } else {
        frameSize = _maxSamplesPerPacket;
      }
      int outputSamplesPerChannel = opus.opus_decode(
          _decoder,
          inputNative.cast<ffi.UnsignedChar>(),
          input?.length ?? 0,
          outputNative,
          frameSize,
          fec ? 1 : 0);

      if (outputSamplesPerChannel >= OPUS_OK) {
        _lastPacketDurationMs =
            _packetDuration(outputSamplesPerChannel, channels, sampleRate);
        return Int16List.fromList(
            outputNative.asTypedList(outputSamplesPerChannel * channels));
      } else {
        throw OpusException(outputSamplesPerChannel);
      }
    });
  }

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      opus.opus_decoder_destroy(_decoder);
    }
  }

  int _estimateLoss(int? loss, int? lastPacketDurationMs) {
    if (loss != null) {
      return loss;
    } else if (lastPacketDurationMs != null) {
      return lastPacketDurationMs;
    } else {
      throw new StateError(
          'Tried to estimate the loss based on the last packets duration, but there was no last packet!\n' +
              'This happend because you called a decode function with no input (null as input in SimpleOpusDecoder or 0 as inputBufferIndex in BufferedOpusDecoder), but failed to specify how many milliseconds were lost.\n' +
              'And since there was no previous sucessfull decoded packet, the decoder could not estimate how many milliseconds are missing.');
    }
  }
}
