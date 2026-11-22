part of 'event.dart';

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      title: fields[0] as String,
      eventDateTime: fields[1] as DateTime,
      icon: eventIcon(fields[2] as int?),
      backgroundColor: Color(fields[3] as int? ?? 0xff7877e6),
      contentColor: fields[4] == null ? null : Color(fields[4] as int),
      fontFamily: fields[5] as String? ?? 'Default',
      allDayEvent: fields[6] as bool? ?? true,
      backgroundGradient: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.eventDateTime)
      ..writeByte(2)
      ..write(obj.icon?.codePoint)
      ..writeByte(3)
      ..write(obj.backgroundColor.toARGB32())
      ..writeByte(4)
      ..write(obj.contentColor?.toARGB32())
      ..writeByte(5)
      ..write(obj.fontFamily)
      ..writeByte(6)
      ..write(obj.allDayEvent)
      ..writeByte(7)
      ..write(obj.backgroundGradient);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
