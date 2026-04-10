import 'dart:convert';
import 'dart:typed_data';

class LanSharePayloadCodec {
  static const int payloadVersion = 1;
  static const String payloadFragmentPrefix = 'c1:';
  static const String compactFragmentPrefix = 'c2:';
  static const String base85Alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!\$%&()*+-;<=>?@^_~[]:,.';

  static final Map<int, int> _base85DecodeMap = <int, int>{
    for (var index = 0; index < base85Alphabet.length; index++)
      base85Alphabet.codeUnitAt(index): index,
  };

  @Deprecated('Use payloadFragmentPrefix or compactFragmentPrefix instead.')
  static const String fragmentPrefix = payloadFragmentPrefix;

  static String encode({
    required String token,
    required int port,
    required List<String> lanIps,
    required String fileName,
    required int fileSize,
    required DateTime expiresAt,
    String? wifiName,
  }) {
    final builder = BytesBuilder(copy: false);
    final tokenBytes = ascii.encode(token);
    final fileNameBytes = utf8.encode(fileName);
    final wifiNameBytes = wifiName == null || wifiName.isEmpty
        ? const <int>[]
        : utf8.encode(wifiName);

    builder.add(<int>[payloadVersion]);
    _writeVarInt(builder, tokenBytes.length);
    builder.add(tokenBytes);
    builder.add(_uint16Bytes(port));
    _writeVarInt(builder, lanIps.length);
    for (final ip in lanIps) {
      builder.add(_ipv4ToBytes(ip));
    }
    _writeVarInt(builder, fileSize);
    _writeVarInt(builder, expiresAt.millisecondsSinceEpoch);
    _writeVarInt(builder, fileNameBytes.length);
    builder.add(fileNameBytes);
    _writeVarInt(builder, wifiNameBytes.length);
    builder.add(wifiNameBytes);

    return _encodeBase85(builder.takeBytes());
  }

  static Map<String, dynamic> decode(String payload) {
    final bytes = _decodeBase85(payload);
    var offset = 0;

    if (bytes.isEmpty) {
      throw const FormatException('Share payload is empty.');
    }

    final version = bytes[offset++];
    if (version != payloadVersion) {
      throw FormatException('Unsupported share payload version: $version');
    }

    final tokenResult = _readLengthPrefixedAscii(bytes, offset);
    final token = tokenResult.text;
    offset = tokenResult.offset;

    if (offset + 2 > bytes.length) {
      throw const FormatException('Share payload is truncated before port.');
    }
    final port = _readUint16(bytes, offset);
    offset += 2;

    final ipCountResult = _readVarInt(bytes, offset);
    final ipCount = ipCountResult.value;
    offset = ipCountResult.offset;

    final lanIps = <String>[];
    for (var index = 0; index < ipCount; index++) {
      if (offset + 4 > bytes.length) {
        throw const FormatException(
          'Share payload is truncated before LAN address list ends.',
        );
      }
      lanIps.add(_bytesToIpv4(bytes, offset));
      offset += 4;
    }

    final fileSizeResult = _readVarInt(bytes, offset);
    final fileSize = fileSizeResult.value;
    offset = fileSizeResult.offset;

    final expiresAtResult = _readVarInt(bytes, offset);
    final expiresAtMilliseconds = expiresAtResult.value;
    offset = expiresAtResult.offset;

    final fileNameResult = _readLengthPrefixedUtf8(bytes, offset);
    final fileName = fileNameResult.text;
    offset = fileNameResult.offset;

    final wifiNameResult = _readLengthPrefixedUtf8(bytes, offset);
    final wifiName = wifiNameResult.text;
    offset = wifiNameResult.offset;

    if (offset != bytes.length) {
      throw const FormatException(
        'Share payload contains unexpected trailing bytes.',
      );
    }

    return <String, dynamic>{
      'token': token,
      'port': port,
      'lanIps': lanIps,
      'fileName': fileName,
      'fileSize': fileSize,
      'expiresAt': DateTime.fromMillisecondsSinceEpoch(
        expiresAtMilliseconds,
      ).toIso8601String(),
      'networkName': wifiName.isEmpty ? null : wifiName,
    };
  }

  static String encodeCompactRoute({
    required String shareKey,
    required int port,
    required List<String> lanIps,
  }) {
    if (shareKey.isEmpty) {
      throw ArgumentError.value(
        shareKey,
        'shareKey',
        'shareKey cannot be empty.',
      );
    }
    final normalizedIps = lanIps.map(_ipv4ToHex).join('.');
    return '$shareKey@${port.toRadixString(36)}@$normalizedIps';
  }

  static Map<String, dynamic> decodeCompactRoute(String payload) {
    final normalized = Uri.decodeComponent(payload.trim());
    final parts = normalized.split('@');
    if (parts.length != 3) {
      throw const FormatException(
        'Compact route payload must contain 3 parts.',
      );
    }

    final shareKey = parts[0].trim();
    if (shareKey.isEmpty) {
      throw const FormatException('Compact route shareKey cannot be empty.');
    }

    final port = int.tryParse(parts[1], radix: 36);
    if (port == null || port < 1 || port > 0xffff) {
      throw FormatException('Invalid compact route port: ${parts[1]}');
    }

    final lanIps = parts[2]
        .split('.')
        .where((item) => item.isNotEmpty)
        .map(_hexToIpv4)
        .toList(growable: false);
    if (lanIps.isEmpty) {
      throw const FormatException(
        'Compact route must contain at least one LAN IP.',
      );
    }

    return <String, dynamic>{
      'shareKey': shareKey,
      'port': port,
      'lanIps': lanIps,
    };
  }

  static void _writeVarInt(BytesBuilder builder, int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'VarInt cannot be negative.');
    }

    var remaining = value;
    while (remaining >= 0x80) {
      builder.addByte((remaining & 0x7f) | 0x80);
      remaining >>= 7;
    }
    builder.addByte(remaining);
  }

  static ({int value, int offset}) _readVarInt(Uint8List bytes, int offset) {
    var result = 0;
    var shift = 0;
    var cursor = offset;

    while (cursor < bytes.length) {
      final byte = bytes[cursor++];
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return (value: result, offset: cursor);
      }
      shift += 7;
      if (shift > 63) {
        throw const FormatException('VarInt is too large.');
      }
    }

    throw const FormatException(
      'Unexpected end of payload while reading VarInt.',
    );
  }

  static ({String text, int offset}) _readLengthPrefixedAscii(
    Uint8List bytes,
    int offset,
  ) {
    final lengthResult = _readVarInt(bytes, offset);
    final length = lengthResult.value;
    final start = lengthResult.offset;
    final end = start + length;
    if (end > bytes.length) {
      throw const FormatException('ASCII field extends beyond payload size.');
    }
    return (text: ascii.decode(bytes.sublist(start, end)), offset: end);
  }

  static ({String text, int offset}) _readLengthPrefixedUtf8(
    Uint8List bytes,
    int offset,
  ) {
    final lengthResult = _readVarInt(bytes, offset);
    final length = lengthResult.value;
    final start = lengthResult.offset;
    final end = start + length;
    if (end > bytes.length) {
      throw const FormatException('UTF-8 field extends beyond payload size.');
    }
    return (text: utf8.decode(bytes.sublist(start, end)), offset: end);
  }

  static Uint8List _uint16Bytes(int value) {
    if (value < 0 || value > 0xffff) {
      throw ArgumentError.value(value, 'value', 'Port must fit in uint16.');
    }
    return Uint8List.fromList(<int>[(value >> 8) & 0xff, value & 0xff]);
  }

  static int _readUint16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static Uint8List _ipv4ToBytes(String ip) {
    final segments = ip.split('.');
    if (segments.length != 4) {
      throw FormatException('Invalid IPv4 address: $ip');
    }
    return Uint8List.fromList(
      segments
          .map((segment) {
            final value = int.tryParse(segment);
            if (value == null || value < 0 || value > 255) {
              throw FormatException('Invalid IPv4 address: $ip');
            }
            return value;
          })
          .toList(growable: false),
    );
  }

  static String _ipv4ToHex(String ip) {
    final bytes = _ipv4ToBytes(ip);
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static String _hexToIpv4(String value) {
    if (value.length != 8) {
      throw FormatException('Invalid IPv4 hex payload: $value');
    }
    final segments = <String>[];
    for (var index = 0; index < 8; index += 2) {
      final part = int.tryParse(value.substring(index, index + 2), radix: 16);
      if (part == null) {
        throw FormatException('Invalid IPv4 hex payload: $value');
      }
      segments.add(part.toString());
    }
    return segments.join('.');
  }

  static String _bytesToIpv4(Uint8List bytes, int offset) {
    return [
      bytes[offset],
      bytes[offset + 1],
      bytes[offset + 2],
      bytes[offset + 3],
    ].join('.');
  }

  static String _encodeBase85(Uint8List data) {
    if (data.isEmpty) {
      return '';
    }

    final output = StringBuffer();
    var offset = 0;
    while (offset < data.length) {
      final remaining = data.length - offset;
      final chunkLength = remaining >= 4 ? 4 : remaining;
      var value = 0;
      for (var index = 0; index < 4; index++) {
        value <<= 8;
        if (index < chunkLength) {
          value |= data[offset + index];
        }
      }

      final digits = List<int>.filled(5, 0);
      for (var index = 4; index >= 0; index--) {
        digits[index] = value % 85;
        value ~/= 85;
      }

      final outputLength = chunkLength == 4 ? 5 : chunkLength + 1;
      for (var index = 0; index < outputLength; index++) {
        output.writeCharCode(base85Alphabet.codeUnitAt(digits[index]));
      }

      offset += chunkLength;
    }

    return output.toString();
  }

  static Uint8List _decodeBase85(String input) {
    if (input.isEmpty) {
      return Uint8List(0);
    }
    if (input.length % 5 == 1) {
      throw const FormatException('Invalid Base85 input length.');
    }

    final output = BytesBuilder(copy: false);
    var offset = 0;

    while (offset < input.length) {
      final remaining = input.length - offset;
      final chunkLength = remaining >= 5 ? 5 : remaining;
      var value = 0;

      for (var index = 0; index < 5; index++) {
        final digit = index < chunkLength
            ? _decodeBase85Digit(input.codeUnitAt(offset + index))
            : 84;
        value = value * 85 + digit;
      }

      final chunkBytes = Uint8List.fromList(<int>[
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ]);
      final outputLength = chunkLength == 5 ? 4 : chunkLength - 1;
      output.add(chunkBytes.sublist(0, outputLength));
      offset += chunkLength;
    }

    return output.takeBytes();
  }

  static int _decodeBase85Digit(int codeUnit) {
    final value = _base85DecodeMap[codeUnit];
    if (value == null) {
      throw FormatException(
        'Invalid Base85 character: ${String.fromCharCode(codeUnit)}',
      );
    }
    return value;
  }
}
