library dwuid;

import 'dart:math';
import 'dart:typed_data';

final _bigInt8 = BigInt.from(8);
final _bigInt9 = BigInt.from(9);
final _bigInt10 = BigInt.from(10);
final _bigInt58 = BigInt.from(58);
final _bigInt64 = BigInt.from(64);
final _bigInt256 = BigInt.from(256);
final _timestampUidInitialValue = _bigInt8 << 48;
final _uniqueTimestampUidInitialValue = _timestampUidInitialValue << 68;
final _randomUidInitialValue = _bigInt9 << 116;
final _geohashUidInitialValue = _bigInt10 << 56;

Map<BigInt, String> _createBaseEncodingMap(String alphabet) {
  final base = alphabet.length;
  final Map<BigInt, String> encodingMap = {};
  for (int i = 0; i < base; i++) {
    final charIndex = BigInt.from(i);
    encodingMap[charIndex] = alphabet[i];
  }
  return encodingMap;
}

Map<String, BigInt> _createBaseDecodingMap(String alphabet,
    {Map<String, Set<String>>? alternatives}) {
  final base = alphabet.length;
  final Map<String, BigInt> decodingMap = {};
  for (int i = 0; i < base; i++) {
    final charIndex = BigInt.from(i);
    final char = alphabet[i];
    decodingMap[char] = charIndex;
    if (alternatives != null) {
      final alternativeChars = alternatives[char];
      if (alternativeChars != null) {
        for (final alternativeChar in alternativeChars) {
          decodingMap[alternativeChar] = charIndex;
        }
      }
    }
  }
  return decodingMap;
}

class _Base58 {
  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static final _encodingMap = _createBaseEncodingMap(_alphabet);
  static final _decodingMap = _createBaseDecodingMap(_alphabet, alternatives: {
    '1': {'I', 'l'},
    'o': {'0', 'O'}
  });

  static String encodeBigInt(BigInt value) {
    String string = '';
    while (value > BigInt.zero) {
      final charIndex = value % _bigInt58;
      final char = _encodingMap[charIndex];
      string = '$char$string';
      value ~/= _bigInt58;
    }
    return string;
  }

  static BigInt decodeBigInt(String source) {
    final length = source.length;
    BigInt value = BigInt.zero;
    for (int i = 0; i < length; i++) {
      final char = source[i];
      final charIndex = _decodingMap[char];
      if (charIndex == null) {
        throw FormatException('Invalid Base58 character', source, i);
      }
      value = (value * _bigInt58) + charIndex;
    }
    return value;
  }
}

class _Base64 {
  static const _alphabet =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
  static final _encodingMap = _createBaseEncodingMap(_alphabet);
  static final _decodingMap = _createBaseDecodingMap(_alphabet);

  static String encodeBigInt(BigInt value) {
    String string = '';
    while (value > BigInt.zero) {
      final charIndex = value % _bigInt64;
      final char = _encodingMap[charIndex];
      string = '$char$string';
      value ~/= _bigInt64;
    }
    return string;
  }

  static BigInt decodeBigInt(String source) {
    final length = source.length;
    BigInt value = BigInt.zero;
    for (int i = 0; i < length; i++) {
      final char = source[i];
      final charIndex = _decodingMap[char];
      if (charIndex == null) {
        throw FormatException('Invalid Base64 character', source, i);
      }
      value = (value * _bigInt64) + charIndex;
    }
    return value;
  }
}

BigInt _bytesToBigInt(Uint8List bytes) {
  BigInt value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) | BigInt.from(byte);
  }
  return value;
}

Uint8List _bigIntToBytes(BigInt value) {
  final length = (value.bitLength + 7) >> 3;
  final bytes = Uint8List(length);
  int offset = length - 1;
  while (offset >= 0) {
    bytes[offset--] = (value % _bigInt256).toInt();
    value >>= 8;
  }
  return bytes;
}

BigInt _randomBigInt(Random random, int bits) {
  BigInt value = BigInt.zero;
  int shift = 32;
  int max = 0x100000000;
  while (bits > 0) {
    if (bits < shift) {
      shift = bits;
      max = pow(2, bits).toInt();
    }
    final randomInt = random.nextInt(max);
    value = (value << shift) + BigInt.from(randomInt);
    bits -= shift;
  }
  return value;
}

double _degreesInRadians(double degrees) => degrees * pi / 180;

int _uidVersion(BigInt value) =>
    ((value >> (value.bitLength - 4)).toInt() & 7) + 1;

class Location {
  final double latitude;
  final double longitude;

  const Location(this.latitude, this.longitude);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Location &&
      latitude == other.latitude &&
      longitude == other.longitude;

  double distanceTo(Location other) {
    final otherLatitude = other.latitude;
    final otherLongitude = other.longitude;
    final lat1 = _degreesInRadians(latitude);
    final lat2 = _degreesInRadians(otherLatitude);
    final dLat = _degreesInRadians(otherLatitude - latitude);
    final dLon = _degreesInRadians(otherLongitude - longitude);
    return 12742000 *
        asin(sqrt(pow(sin(dLat / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2)));
  }
}

class BoundingBox {
  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  const BoundingBox(
      this.minLatitude, this.minLongitude, this.maxLatitude, this.maxLongitude);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is BoundingBox &&
      minLatitude == other.minLatitude &&
      minLongitude == other.minLongitude &&
      maxLatitude == other.maxLatitude &&
      maxLongitude == other.maxLongitude;
}

class _Geohash {
  static BigInt encode(double latitude, double longitude) {
    BigInt geohash = BigInt.zero;
    double minLatitude = -90;
    double minLongitude = -180;
    double maxLatitude = 90;
    double maxLongitude = 180;
    bool isEvenBit = true;
    for (int i = 0; i < 56; i++) {
      geohash <<= 1;
      if (isEvenBit) {
        final deltaLongitude = (minLongitude + maxLongitude) / 2;
        if (longitude > deltaLongitude) {
          geohash += BigInt.one;
          minLongitude = deltaLongitude;
        } else {
          maxLongitude = deltaLongitude;
        }
      } else {
        final deltaLatitude = (minLatitude + maxLatitude) / 2;
        if (latitude > deltaLatitude) {
          geohash += BigInt.one;
          minLatitude = deltaLatitude;
        } else {
          maxLatitude = deltaLatitude;
        }
      }
      isEvenBit = !isEvenBit;
    }
    return geohash;
  }

  static BoundingBox decode(BigInt geohash) {
    double minLatitude = -90;
    double minLongitude = -180;
    double maxLatitude = 90;
    double maxLongitude = 180;
    bool isEvenBit = true;
    for (int i = 55; i >= 0; i--) {
      final bit = (geohash >> i) & BigInt.one;
      if (isEvenBit) {
        final deltaLongitude = (minLongitude + maxLongitude) / 2;
        if (bit == BigInt.one) {
          minLongitude = deltaLongitude;
        } else {
          maxLongitude = deltaLongitude;
        }
      } else {
        final deltaLatitude = (minLatitude + maxLatitude) / 2;
        if (bit == BigInt.one) {
          minLatitude = deltaLatitude;
        } else {
          maxLatitude = deltaLatitude;
        }
      }
      isEvenBit = !isEvenBit;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }
}

enum UidEncoding { base58, base64 }

class Uid {
  static final _timestampUidGenerator = TimestampUidGenerator();
  static final _randomUidGenerator = RandomUidGenerator();
  final BigInt _value;

  static TimestampUid timestamp() => _timestampUidGenerator.next();

  static RandomUid random() => _randomUidGenerator.next();

  static GeohashUid geohash(double latitude, double longitude) =>
      GeohashUid.fromCoordinates(latitude, longitude);

  static Uid parse(String source, {UidEncoding encoding = UidEncoding.base58}) {
    final length = source.length;
    if (length < 4) {
      throw FormatException('Invalid UID length: $length', source);
    }
    final value = encoding == UidEncoding.base58
        ? _Base58.decodeBigInt(source)
        : _Base64.decodeBigInt(source);
    return Uid.fromBigInt(value);
  }

  static Uid? tryParse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    try {
      return parse(source, encoding: encoding);
    } on FormatException {
      return null;
    }
  }

  const Uid._(this._value);

  factory Uid.fromBigInt(BigInt value) {
    final bitLength = value.bitLength;
    if (bitLength < 24) {
      throw FormatException('Invalid UID bit length: $bitLength', value);
    }
    final version = _uidVersion(value);
    switch (version) {
      case 1:
        return TimestampUid.fromBigInt(value);
      case 2:
        return RandomUid.fromBigInt(value);
      case 3:
        return GeohashUid.fromBigInt(value);
      default:
        throw FormatException('Invalid UID version: $version', value);
    }
  }

  factory Uid.fromBytes(Uint8List bytes) {
    final length = bytes.length;
    if (length < 3) {
      throw FormatException('Invalid UID byte length: $length', bytes);
    }
    final value = _bytesToBigInt(bytes);
    return Uid.fromBigInt(value);
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) => other is Uid && _value == other._value;

  @override
  String toString([UidEncoding encoding = UidEncoding.base58]) {
    return encoding == UidEncoding.base58
        ? _Base58.encodeBigInt(_value)
        : _Base64.encodeBigInt(_value);
  }

  BigInt toBigInt() => _value;

  Uint8List toBytes() => _bigIntToBytes(_value);
}

class TimestampUid extends Uid {
  static int? _lastTimestamp;
  static TimestampUid? _lastTimestampUid;

  static TimestampUid now() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (timestamp != _lastTimestamp) {
      _lastTimestamp = timestamp;
      final value = _timestampUidInitialValue + BigInt.from(timestamp);
      _lastTimestampUid = TimestampUid._(value);
    }
    return _lastTimestampUid!;
  }

  static TimestampUid parse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    final length = source.length;
    if (length < 9) {
      throw FormatException('Invalid TimestampUID length: $length', source);
    }
    final value = encoding == UidEncoding.base58
        ? _Base58.decodeBigInt(source)
        : _Base64.decodeBigInt(source);
    return TimestampUid.fromBigInt(value);
  }

  static TimestampUid? tryParse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    try {
      return parse(source, encoding: encoding);
    } on FormatException {
      return null;
    }
  }

  const TimestampUid._(BigInt value) : super._(value);

  factory TimestampUid.fromBigInt(BigInt value) {
    final bitLength = value.bitLength;
    if (bitLength < 60 && bitLength != 52) {
      throw FormatException(
          'Invalid TimestampUID bit length: $bitLength', value);
    }
    final version = _uidVersion(value);
    if (version != 1) {
      throw FormatException('Invalid TimestampUID version: $version', value);
    }
    return TimestampUid._(value);
  }

  factory TimestampUid.fromBytes(Uint8List bytes) {
    final length = bytes.length;
    if (length < 7) {
      throw FormatException('Invalid TimestampUID byte length: $length', bytes);
    }
    final value = _bytesToBigInt(bytes);
    return TimestampUid.fromBigInt(value);
  }

  factory TimestampUid.fromDateTime(DateTime dateTime) {
    final value = _timestampUidInitialValue +
        BigInt.from(dateTime.millisecondsSinceEpoch);
    return TimestampUid._(value);
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TimestampUid && _value == other._value;

  DateTime toDateTime() {
    final millisecondsSinceEpoch =
        ((_value >> (_value.bitLength - 52)) - _timestampUidInitialValue)
            .toInt();
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }
}

class RandomUid extends Uid {
  static RandomUid parse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    final length = source.length;
    if (length < 4) {
      throw FormatException('Invalid RandomUID length: $length', source);
    }
    final value = encoding == UidEncoding.base58
        ? _Base58.decodeBigInt(source)
        : _Base64.decodeBigInt(source);
    return RandomUid.fromBigInt(value);
  }

  static RandomUid? tryParse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    try {
      return parse(source, encoding: encoding);
    } on FormatException {
      return null;
    }
  }

  const RandomUid._(BigInt value) : super._(value);

  factory RandomUid.fromBigInt(BigInt value) {
    final bitLength = value.bitLength;
    if (bitLength < 24) {
      throw FormatException('Invalid RandomUID bit length: $bitLength', value);
    }
    final version = _uidVersion(value);
    if (version != 2) {
      throw FormatException('Invalid RandomUID version: $version', value);
    }
    return RandomUid._(value);
  }

  factory RandomUid.fromBytes(Uint8List bytes) {
    final length = bytes.length;
    if (length < 3) {
      throw FormatException('Invalid RandomUID byte length: $length', bytes);
    }
    final value = _bytesToBigInt(bytes);
    return RandomUid.fromBigInt(value);
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is RandomUid && _value == other._value;
}

class GeohashUid extends Uid {
  static GeohashUid parse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    final length = source.length;
    if (length < 10) {
      throw FormatException('Invalid GeohashUID length: $length', source);
    }
    final value = encoding == UidEncoding.base58
        ? _Base58.decodeBigInt(source)
        : _Base64.decodeBigInt(source);
    return GeohashUid.fromBigInt(value);
  }

  static GeohashUid? tryParse(String source,
      {UidEncoding encoding = UidEncoding.base58}) {
    try {
      return parse(source, encoding: encoding);
    } on FormatException {
      return null;
    }
  }

  const GeohashUid._(BigInt value) : super._(value);

  factory GeohashUid.fromBigInt(BigInt value) {
    final bitLength = value.bitLength;
    if (bitLength != 60) {
      throw FormatException('Invalid GeohashUID bit length: $bitLength', value);
    }
    final version = _uidVersion(value);
    if (version != 3) {
      throw FormatException('Invalid GeohashUID version: $version', value);
    }
    return GeohashUid._(value);
  }

  factory GeohashUid.fromBytes(Uint8List bytes) {
    final length = bytes.length;
    if (length < 8) {
      throw FormatException('Invalid GeohashUID byte length: $length', bytes);
    }
    final value = _bytesToBigInt(bytes);
    return GeohashUid.fromBigInt(value);
  }

  factory GeohashUid.fromCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw RangeError.range(latitude, -90, 90, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw RangeError.range(longitude, -180, 180, 'longitude');
    }
    final value =
        _geohashUidInitialValue + _Geohash.encode(latitude, longitude);
    return GeohashUid._(value);
  }

  factory GeohashUid.fromLocation(Location location) =>
      GeohashUid.fromCoordinates(location.latitude, location.longitude);

  BoundingBox toBoundingBox() {
    return _Geohash.decode(_value - _geohashUidInitialValue);
  }

  Location toLocation() {
    final boundingBox = toBoundingBox();
    final deltaLatitude =
        (boundingBox.minLatitude + boundingBox.maxLatitude) / 2;
    final deltaLongitude =
        (boundingBox.minLongitude + boundingBox.maxLongitude) / 2;
    final normalizedLatitude = deltaLatitude.toStringAsFixed(6);
    final normalizedLongitude = deltaLongitude.toStringAsFixed(6);
    final latitude = double.parse(normalizedLatitude);
    final longitude = double.parse(normalizedLongitude);
    return Location(latitude, longitude);
  }
}

abstract class UidGenerator {
  Uid next();
}

class TimestampUidGenerator implements UidGenerator {
  final int _uniqueBits;
  final BigInt _initialValue;
  final Random _random;
  int _lastTimestamp = 0;
  BigInt _timestampValue = BigInt.zero;
  BigInt _uniqueValue = BigInt.zero;

  TimestampUidGenerator._(this._uniqueBits, this._initialValue, this._random);

  factory TimestampUidGenerator({int bits = 120, Random? random}) {
    int uniqueBits;
    BigInt initialValue;
    if (bits != 120) {
      if (bits < 60) {
        throw RangeError.range(bits, 60, null, 'bits');
      }
      uniqueBits = bits - 52;
      initialValue = _bigInt8 << uniqueBits;
    } else {
      uniqueBits = 68;
      initialValue = _uniqueTimestampUidInitialValue;
    }
    random ??= Random();
    return TimestampUidGenerator._(uniqueBits, initialValue, random);
  }

  @override
  TimestampUid next() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (timestamp != _lastTimestamp) {
      _lastTimestamp = timestamp;
      _timestampValue = _initialValue + (BigInt.from(timestamp) << _uniqueBits);
      _uniqueValue = _randomBigInt(_random, _uniqueBits);
    } else {
      _uniqueValue += BigInt.one;
      if (_uniqueValue.bitLength > _uniqueBits) {
        _uniqueValue = BigInt.zero;
      }
    }
    final value = _timestampValue + _uniqueValue;
    return TimestampUid._(value);
  }
}

class RandomUidGenerator implements UidGenerator {
  final int _randomBits;
  final BigInt _initialValue;
  final Random _random;

  RandomUidGenerator._(this._randomBits, this._initialValue, this._random);

  factory RandomUidGenerator({int bits = 120, Random? random}) {
    int randomBits;
    BigInt initialValue;
    if (bits != 120) {
      if (bits < 24) {
        throw RangeError.range(bits, 24, null, 'bits');
      }
      randomBits = bits - 4;
      initialValue = _bigInt9 << randomBits;
    } else {
      randomBits = 116;
      initialValue = _randomUidInitialValue;
    }
    random ??= Random();
    return RandomUidGenerator._(randomBits, initialValue, random);
  }

  @override
  RandomUid next() {
    final value = _initialValue + _randomBigInt(_random, _randomBits);
    return RandomUid._(value);
  }
}
