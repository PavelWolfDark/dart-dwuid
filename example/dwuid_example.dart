import 'package:dwuid/dwuid.dart';

void main() {
  print(Uid.timestamp()); // => 4arZkrd5dFjDAxGo2EcMM
  print(Uid.parse(
      '4arZkrd5dFjDAxGo2EcMM')); // => TimestampUid(4arZkrd5dFjDAxGo2EcMM)

  print(Uid.random()); // => 5LsB98o4MByiNMWV8cxni
  print(Uid.parse(
      '5LsB98o4MByiNMWV8cxni')); // => RandomUid(5LsB98o4MByiNMWV8cxni)

  print(Uid.geohash(0.123456, 0.123456)); // => 2oHjQuePNCD
  print(Uid.parse('2oHjQuePNCD')); // => GeohashUid(2oHjQuePNCD)

  print(TimestampUid.now()); // => Jbbq9G615
  print(TimestampUid.parse('Jbbq9G615')); // => Jbbq9G615
  print(TimestampUid.tryParse('Jbbq9G615')); // => Jbbq9G615
//  print(RandomUid.parse('Jbbq9G615')); // throws FormatException
  print(RandomUid.tryParse('Jbbq9G615')); // => null

  print(GeohashUid.fromCoordinates(-45.123456, -90.123456)); // => 2gctpGXKR4c
  print(GeohashUid.fromCoordinates(45.123456, 90.123456)); // => 2q7EUgg3MZF
  print(GeohashUid.parse('2gctpGXKR4c')
      .toLocation()); // => Location(-45.123456, -90.123456)
  print(GeohashUid.parse('2q7EUgg3MZF')
      .toLocation()); // => Location(45.123456, 90.123456)

  final timestampUidGenerator = TimestampUidGenerator();
  print(timestampUidGenerator.next()); // => 4arZkrd5gj9ndREUza23a
  print(timestampUidGenerator.next()); // => 4arZkrd5gv5Gan2fDe7w3
  print(timestampUidGenerator.next()); // => 4arZkrd5gv5Gan2fDe7w4
  print(timestampUidGenerator.next()); // => 4arZkrd5h8pqZmCarCpyb
  print(timestampUidGenerator.next()); // => 4arZkrd5h8pqZmCarCpyc

  final randomUidGenerator = RandomUidGenerator();
//  final secureRandomUidGenerator = RandomUidGenerator(random: Random.secure());
  print(randomUidGenerator.next()); // => 56cuNWELu2ZEqeo7QCfLn
  print(randomUidGenerator.next()); // => 5Td5b6CEySZJGFZ6CA2iW
  print(randomUidGenerator.next()); // => 59zXzHMpg1QRb57zJVGsQ
  print(randomUidGenerator.next()); // => 5EraHXGw21VpRhWTUYoCa
  print(randomUidGenerator.next()); // => 5StxyheEN6wDoM3pfsBEP
}
