// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multilingual_text.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MultilingualTextAdapter extends TypeAdapter<MultilingualText> {
  @override
  final int typeId = 0;

  @override
  MultilingualText read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MultilingualText(
      translations: (fields[0] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MultilingualText obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.translations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultilingualTextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
