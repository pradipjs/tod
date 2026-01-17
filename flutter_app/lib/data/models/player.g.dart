// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 3;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String,
      colorIndex: fields[3] as int,
      score: fields[4] as int,
      truthsCompleted: fields[5] as int,
      daresCompleted: fields[6] as int,
      forfeits: fields[7] as int,
      streak: fields[8] as int,
      bestStreak: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.colorIndex)
      ..writeByte(4)
      ..write(obj.score)
      ..writeByte(5)
      ..write(obj.truthsCompleted)
      ..writeByte(6)
      ..write(obj.daresCompleted)
      ..writeByte(7)
      ..write(obj.forfeits)
      ..writeByte(8)
      ..write(obj.streak)
      ..writeByte(9)
      ..write(obj.bestStreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
