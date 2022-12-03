import 'dart:math';
import 'package:dwuid/dwuid.dart';

void main() {
  Uid.timestamp().toString(); // => 4arZkrd5dFjDAxGo2EcMM
  Uid.parse('4arZkrd5dFjDAxGo2EcMM'); // => TimestampUid

  Uid.random().toString(); // => 5LsB98o4MByiNMWV8cxni
  Uid.parse('5LsB98o4MByiNMWV8cxni'); // => RandomUid

  TimestampUid.now().toString(); // => Jbbq9G615
  TimestampUid.parse('Jbbq9G615'); // => TimestampUid
  TimestampUid.tryParse('Jbbq9G615'); // => TimestampUid
  RandomUid.parse('Jbbq9G615'); // throws FormatException
  RandomUid.tryParse('Jbbq9G615'); // => null

  final timestampUidGenerator = TimestampUidGenerator();
  timestampUidGenerator.next().toString(); // => 4arZkrd5gj9ndREUza23a
  timestampUidGenerator.next().toString(); // => 4arZkrd5gv5Gan2fDe7w3
  timestampUidGenerator.next().toString(); // => 4arZkrd5gv5Gan2fDe7w4
  timestampUidGenerator.next().toString(); // => 4arZkrd5h8pqZmCarCpyb
  timestampUidGenerator.next().toString(); // => 4arZkrd5h8pqZmCarCpyc

  final randomUidGenerator = RandomUidGenerator();
  final secureRandomUidGenerator = RandomUidGenerator(random: Random.secure());
  randomUidGenerator.next().toString(); // => 56cuNWELu2ZEqeo7QCfLn
  randomUidGenerator.next().toString(); // => 5Td5b6CEySZJGFZ6CA2iW
  randomUidGenerator.next().toString(); // => 59zXzHMpg1QRb57zJVGsQ
  randomUidGenerator.next().toString(); // => 5EraHXGw21VpRhWTUYoCa
  randomUidGenerator.next().toString(); // => 5StxyheEN6wDoM3pfsBEP

  final shortCodeGenerator = RandomUidGenerator(bits: 32);
  shortCodeGenerator.next().toString(); // => 4w3jVu
  shortCodeGenerator.next().toString(); // => 4gkbgq
  shortCodeGenerator.next().toString(); // => 54pVyr
  shortCodeGenerator.next().toString(); // => 4xKnyc
  shortCodeGenerator.next().toString(); // => 4wyANi
}
