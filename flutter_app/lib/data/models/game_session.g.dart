// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameSessionAdapter extends TypeAdapter<GameSession> {
  @override
  final int typeId = 4;

  @override
  GameSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSession(
      id: fields[0] as String,
      mode: fields[1] as String,
      turnMode: fields[2] as String,
      categoryIds: (fields[3] as List).cast<String>(),
      players: (fields[6] as List).cast<Player>(),
      startedAt: fields[9] as DateTime,
      timerSeconds: fields[5] as int,
      currentPlayerIndex: fields[7] as int,
      roundsPlayed: fields[8] as int,
      endedAt: fields[10] as DateTime?,
      adultConsentGiven: fields[11] as bool,
      usedTaskIds: (fields[12] as List).cast<String>(),
      ageGroup: fields[13] as String,
      language: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameSession obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.turnMode)
      ..writeByte(3)
      ..write(obj.categoryIds)
      ..writeByte(5)
      ..write(obj.timerSeconds)
      ..writeByte(6)
      ..write(obj.players)
      ..writeByte(7)
      ..write(obj.currentPlayerIndex)
      ..writeByte(8)
      ..write(obj.roundsPlayed)
      ..writeByte(9)
      ..write(obj.startedAt)
      ..writeByte(10)
      ..write(obj.endedAt)
      ..writeByte(11)
      ..write(obj.adultConsentGiven)
      ..writeByte(12)
      ..write(obj.usedTaskIds)
      ..writeByte(13)
      ..write(obj.ageGroup)
      ..writeByte(14)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
