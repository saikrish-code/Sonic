import 'package:drift/drift.dart';

/// Table storing user-taught personalized sound prototypes.
class TaughtSounds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  IntColumn get iconCode => integer()();
  IntColumn get colorValue => integer()();
  TextColumn get embeddingJson => text()(); // 128-dim embedding as JSON array
  IntColumn get sampleCount => integer().withDefault(const Constant(3))();
  RealColumn get threshold => real().withDefault(const Constant(0.85))();
  IntColumn get consecutiveThumbsDown => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table storing past sound detection alerts with confidence and user feedback.
class AlertHistory extends Table {
  TextColumn get id => text()();
  TextColumn get soundName => text()();
  TextColumn get category => text()();
  BoolColumn get isPersonal => boolean().withDefault(const Constant(false))();
  TextColumn get prototypeId => text().nullable()();
  RealColumn get confidence => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get feedback => integer().withDefault(const Constant(0))(); // 0=none, 1=up, -1=down

  @override
  Set<Column> get primaryKey => {id};
}

/// Table storing per-category sensitivity settings.
class CategorySettings extends Table {
  TextColumn get categoryKey => text()();
  RealColumn get threshold => real().withDefault(const Constant(0.70))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {categoryKey};
}
