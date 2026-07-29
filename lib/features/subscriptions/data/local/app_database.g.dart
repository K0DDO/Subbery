// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, SubscriptionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<String> logo = GeneratedColumn<String>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceInCentsMeta = const VerificationMeta(
    'priceInCents',
  );
  @override
  late final GeneratedColumn<int> priceInCents = GeneratedColumn<int>(
    'price_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billingCycleMeta = const VerificationMeta(
    'billingCycle',
  );
  @override
  late final GeneratedColumn<String> billingCycle = GeneratedColumn<String>(
    'billing_cycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextPaymentDateMeta = const VerificationMeta(
    'nextPaymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextPaymentDate =
      GeneratedColumn<DateTime>(
        'next_payment_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _billingAnchorDayMeta = const VerificationMeta(
    'billingAnchorDay',
  );
  @override
  late final GeneratedColumn<int> billingAnchorDay = GeneratedColumn<int>(
    'billing_anchor_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSpentInCentsMeta = const VerificationMeta(
    'totalSpentInCents',
  );
  @override
  late final GeneratedColumn<int> totalSpentInCents = GeneratedColumn<int>(
    'total_spent_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    logo,
    category,
    priceInCents,
    billingCycle,
    startDate,
    nextPaymentDate,
    billingAnchorDay,
    status,
    totalSpentInCents,
    reminderEnabled,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('price_in_cents')) {
      context.handle(
        _priceInCentsMeta,
        priceInCents.isAcceptableOrUnknown(
          data['price_in_cents']!,
          _priceInCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceInCentsMeta);
    }
    if (data.containsKey('billing_cycle')) {
      context.handle(
        _billingCycleMeta,
        billingCycle.isAcceptableOrUnknown(
          data['billing_cycle']!,
          _billingCycleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billingCycleMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('next_payment_date')) {
      context.handle(
        _nextPaymentDateMeta,
        nextPaymentDate.isAcceptableOrUnknown(
          data['next_payment_date']!,
          _nextPaymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextPaymentDateMeta);
    }
    if (data.containsKey('billing_anchor_day')) {
      context.handle(
        _billingAnchorDayMeta,
        billingAnchorDay.isAcceptableOrUnknown(
          data['billing_anchor_day']!,
          _billingAnchorDayMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_spent_in_cents')) {
      context.handle(
        _totalSpentInCentsMeta,
        totalSpentInCents.isAcceptableOrUnknown(
          data['total_spent_in_cents']!,
          _totalSpentInCentsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      priceInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_in_cents'],
      )!,
      billingCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_cycle'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      nextPaymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_payment_date'],
      )!,
      billingAnchorDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billing_anchor_day'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalSpentInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_spent_in_cents'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class SubscriptionRecord extends DataClass
    implements Insertable<SubscriptionRecord> {
  final String id;
  final String name;
  final String? logo;
  final String category;
  final int priceInCents;
  final String billingCycle;
  final DateTime startDate;
  final DateTime nextPaymentDate;
  final int? billingAnchorDay;
  final String status;
  final int totalSpentInCents;
  final bool reminderEnabled;
  final String? notes;
  const SubscriptionRecord({
    required this.id,
    required this.name,
    this.logo,
    required this.category,
    required this.priceInCents,
    required this.billingCycle,
    required this.startDate,
    required this.nextPaymentDate,
    this.billingAnchorDay,
    required this.status,
    required this.totalSpentInCents,
    required this.reminderEnabled,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<String>(logo);
    }
    map['category'] = Variable<String>(category);
    map['price_in_cents'] = Variable<int>(priceInCents);
    map['billing_cycle'] = Variable<String>(billingCycle);
    map['start_date'] = Variable<DateTime>(startDate);
    map['next_payment_date'] = Variable<DateTime>(nextPaymentDate);
    if (!nullToAbsent || billingAnchorDay != null) {
      map['billing_anchor_day'] = Variable<int>(billingAnchorDay);
    }
    map['status'] = Variable<String>(status);
    map['total_spent_in_cents'] = Variable<int>(totalSpentInCents);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      category: Value(category),
      priceInCents: Value(priceInCents),
      billingCycle: Value(billingCycle),
      startDate: Value(startDate),
      nextPaymentDate: Value(nextPaymentDate),
      billingAnchorDay: billingAnchorDay == null && nullToAbsent
          ? const Value.absent()
          : Value(billingAnchorDay),
      status: Value(status),
      totalSpentInCents: Value(totalSpentInCents),
      reminderEnabled: Value(reminderEnabled),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SubscriptionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      logo: serializer.fromJson<String?>(json['logo']),
      category: serializer.fromJson<String>(json['category']),
      priceInCents: serializer.fromJson<int>(json['priceInCents']),
      billingCycle: serializer.fromJson<String>(json['billingCycle']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      nextPaymentDate: serializer.fromJson<DateTime>(json['nextPaymentDate']),
      billingAnchorDay: serializer.fromJson<int?>(json['billingAnchorDay']),
      status: serializer.fromJson<String>(json['status']),
      totalSpentInCents: serializer.fromJson<int>(json['totalSpentInCents']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'logo': serializer.toJson<String?>(logo),
      'category': serializer.toJson<String>(category),
      'priceInCents': serializer.toJson<int>(priceInCents),
      'billingCycle': serializer.toJson<String>(billingCycle),
      'startDate': serializer.toJson<DateTime>(startDate),
      'nextPaymentDate': serializer.toJson<DateTime>(nextPaymentDate),
      'billingAnchorDay': serializer.toJson<int?>(billingAnchorDay),
      'status': serializer.toJson<String>(status),
      'totalSpentInCents': serializer.toJson<int>(totalSpentInCents),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SubscriptionRecord copyWith({
    String? id,
    String? name,
    Value<String?> logo = const Value.absent(),
    String? category,
    int? priceInCents,
    String? billingCycle,
    DateTime? startDate,
    DateTime? nextPaymentDate,
    Value<int?> billingAnchorDay = const Value.absent(),
    String? status,
    int? totalSpentInCents,
    bool? reminderEnabled,
    Value<String?> notes = const Value.absent(),
  }) => SubscriptionRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    logo: logo.present ? logo.value : this.logo,
    category: category ?? this.category,
    priceInCents: priceInCents ?? this.priceInCents,
    billingCycle: billingCycle ?? this.billingCycle,
    startDate: startDate ?? this.startDate,
    nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
    billingAnchorDay: billingAnchorDay.present
        ? billingAnchorDay.value
        : this.billingAnchorDay,
    status: status ?? this.status,
    totalSpentInCents: totalSpentInCents ?? this.totalSpentInCents,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    notes: notes.present ? notes.value : this.notes,
  );
  SubscriptionRecord copyWithCompanion(SubscriptionsCompanion data) {
    return SubscriptionRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      logo: data.logo.present ? data.logo.value : this.logo,
      category: data.category.present ? data.category.value : this.category,
      priceInCents: data.priceInCents.present
          ? data.priceInCents.value
          : this.priceInCents,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      nextPaymentDate: data.nextPaymentDate.present
          ? data.nextPaymentDate.value
          : this.nextPaymentDate,
      billingAnchorDay: data.billingAnchorDay.present
          ? data.billingAnchorDay.value
          : this.billingAnchorDay,
      status: data.status.present ? data.status.value : this.status,
      totalSpentInCents: data.totalSpentInCents.present
          ? data.totalSpentInCents.value
          : this.totalSpentInCents,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logo: $logo, ')
          ..write('category: $category, ')
          ..write('priceInCents: $priceInCents, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('startDate: $startDate, ')
          ..write('nextPaymentDate: $nextPaymentDate, ')
          ..write('billingAnchorDay: $billingAnchorDay, ')
          ..write('status: $status, ')
          ..write('totalSpentInCents: $totalSpentInCents, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logo,
    category,
    priceInCents,
    billingCycle,
    startDate,
    nextPaymentDate,
    billingAnchorDay,
    status,
    totalSpentInCents,
    reminderEnabled,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.logo == this.logo &&
          other.category == this.category &&
          other.priceInCents == this.priceInCents &&
          other.billingCycle == this.billingCycle &&
          other.startDate == this.startDate &&
          other.nextPaymentDate == this.nextPaymentDate &&
          other.billingAnchorDay == this.billingAnchorDay &&
          other.status == this.status &&
          other.totalSpentInCents == this.totalSpentInCents &&
          other.reminderEnabled == this.reminderEnabled &&
          other.notes == this.notes);
}

class SubscriptionsCompanion extends UpdateCompanion<SubscriptionRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> logo;
  final Value<String> category;
  final Value<int> priceInCents;
  final Value<String> billingCycle;
  final Value<DateTime> startDate;
  final Value<DateTime> nextPaymentDate;
  final Value<int?> billingAnchorDay;
  final Value<String> status;
  final Value<int> totalSpentInCents;
  final Value<bool> reminderEnabled;
  final Value<String?> notes;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.logo = const Value.absent(),
    this.category = const Value.absent(),
    this.priceInCents = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.startDate = const Value.absent(),
    this.nextPaymentDate = const Value.absent(),
    this.billingAnchorDay = const Value.absent(),
    this.status = const Value.absent(),
    this.totalSpentInCents = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String id,
    required String name,
    this.logo = const Value.absent(),
    required String category,
    required int priceInCents,
    required String billingCycle,
    required DateTime startDate,
    required DateTime nextPaymentDate,
    this.billingAnchorDay = const Value.absent(),
    required String status,
    this.totalSpentInCents = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       priceInCents = Value(priceInCents),
       billingCycle = Value(billingCycle),
       startDate = Value(startDate),
       nextPaymentDate = Value(nextPaymentDate),
       status = Value(status);
  static Insertable<SubscriptionRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? logo,
    Expression<String>? category,
    Expression<int>? priceInCents,
    Expression<String>? billingCycle,
    Expression<DateTime>? startDate,
    Expression<DateTime>? nextPaymentDate,
    Expression<int>? billingAnchorDay,
    Expression<String>? status,
    Expression<int>? totalSpentInCents,
    Expression<bool>? reminderEnabled,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (logo != null) 'logo': logo,
      if (category != null) 'category': category,
      if (priceInCents != null) 'price_in_cents': priceInCents,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (startDate != null) 'start_date': startDate,
      if (nextPaymentDate != null) 'next_payment_date': nextPaymentDate,
      if (billingAnchorDay != null) 'billing_anchor_day': billingAnchorDay,
      if (status != null) 'status': status,
      if (totalSpentInCents != null) 'total_spent_in_cents': totalSpentInCents,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? logo,
    Value<String>? category,
    Value<int>? priceInCents,
    Value<String>? billingCycle,
    Value<DateTime>? startDate,
    Value<DateTime>? nextPaymentDate,
    Value<int?>? billingAnchorDay,
    Value<String>? status,
    Value<int>? totalSpentInCents,
    Value<bool>? reminderEnabled,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      category: category ?? this.category,
      priceInCents: priceInCents ?? this.priceInCents,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      billingAnchorDay: billingAnchorDay ?? this.billingAnchorDay,
      status: status ?? this.status,
      totalSpentInCents: totalSpentInCents ?? this.totalSpentInCents,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logo.present) {
      map['logo'] = Variable<String>(logo.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priceInCents.present) {
      map['price_in_cents'] = Variable<int>(priceInCents.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<String>(billingCycle.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (nextPaymentDate.present) {
      map['next_payment_date'] = Variable<DateTime>(nextPaymentDate.value);
    }
    if (billingAnchorDay.present) {
      map['billing_anchor_day'] = Variable<int>(billingAnchorDay.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalSpentInCents.present) {
      map['total_spent_in_cents'] = Variable<int>(totalSpentInCents.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logo: $logo, ')
          ..write('category: $category, ')
          ..write('priceInCents: $priceInCents, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('startDate: $startDate, ')
          ..write('nextPaymentDate: $nextPaymentDate, ')
          ..write('billingAnchorDay: $billingAnchorDay, ')
          ..write('status: $status, ')
          ..write('totalSpentInCents: $totalSpentInCents, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subscriptionIdMeta = const VerificationMeta(
    'subscriptionId',
  );
  @override
  late final GeneratedColumn<String> subscriptionId = GeneratedColumn<String>(
    'subscription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subscriptions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountInCentsMeta = const VerificationMeta(
    'amountInCents',
  );
  @override
  late final GeneratedColumn<int> amountInCents = GeneratedColumn<int>(
    'amount_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subscriptionId,
    amountInCents,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subscription_id')) {
      context.handle(
        _subscriptionIdMeta,
        subscriptionId.isAcceptableOrUnknown(
          data['subscription_id']!,
          _subscriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subscriptionIdMeta);
    }
    if (data.containsKey('amount_in_cents')) {
      context.handle(
        _amountInCentsMeta,
        amountInCents.isAcceptableOrUnknown(
          data['amount_in_cents']!,
          _amountInCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountInCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_id'],
      )!,
      amountInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_in_cents'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRecord extends DataClass implements Insertable<PaymentRecord> {
  final String id;
  final String subscriptionId;
  final int amountInCents;
  final DateTime date;
  const PaymentRecord({
    required this.id,
    required this.subscriptionId,
    required this.amountInCents,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subscription_id'] = Variable<String>(subscriptionId);
    map['amount_in_cents'] = Variable<int>(amountInCents);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      subscriptionId: Value(subscriptionId),
      amountInCents: Value(amountInCents),
      date: Value(date),
    );
  }

  factory PaymentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRecord(
      id: serializer.fromJson<String>(json['id']),
      subscriptionId: serializer.fromJson<String>(json['subscriptionId']),
      amountInCents: serializer.fromJson<int>(json['amountInCents']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subscriptionId': serializer.toJson<String>(subscriptionId),
      'amountInCents': serializer.toJson<int>(amountInCents),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  PaymentRecord copyWith({
    String? id,
    String? subscriptionId,
    int? amountInCents,
    DateTime? date,
  }) => PaymentRecord(
    id: id ?? this.id,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    amountInCents: amountInCents ?? this.amountInCents,
    date: date ?? this.date,
  );
  PaymentRecord copyWithCompanion(PaymentsCompanion data) {
    return PaymentRecord(
      id: data.id.present ? data.id.value : this.id,
      subscriptionId: data.subscriptionId.present
          ? data.subscriptionId.value
          : this.subscriptionId,
      amountInCents: data.amountInCents.present
          ? data.amountInCents.value
          : this.amountInCents,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRecord(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subscriptionId, amountInCents, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRecord &&
          other.id == this.id &&
          other.subscriptionId == this.subscriptionId &&
          other.amountInCents == this.amountInCents &&
          other.date == this.date);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRecord> {
  final Value<String> id;
  final Value<String> subscriptionId;
  final Value<int> amountInCents;
  final Value<DateTime> date;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.subscriptionId = const Value.absent(),
    this.amountInCents = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String subscriptionId,
    required int amountInCents,
    required DateTime date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subscriptionId = Value(subscriptionId),
       amountInCents = Value(amountInCents),
       date = Value(date);
  static Insertable<PaymentRecord> custom({
    Expression<String>? id,
    Expression<String>? subscriptionId,
    Expression<int>? amountInCents,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (amountInCents != null) 'amount_in_cents': amountInCents,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? subscriptionId,
    Value<int>? amountInCents,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      amountInCents: amountInCents ?? this.amountInCents,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subscriptionId.present) {
      map['subscription_id'] = Variable<String>(subscriptionId.value);
    }
    if (amountInCents.present) {
      map['amount_in_cents'] = Variable<int>(amountInCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [subscriptions, payments];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subscriptions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      required String id,
      required String name,
      Value<String?> logo,
      required String category,
      required int priceInCents,
      required String billingCycle,
      required DateTime startDate,
      required DateTime nextPaymentDate,
      Value<int?> billingAnchorDay,
      required String status,
      Value<int> totalSpentInCents,
      Value<bool> reminderEnabled,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> logo,
      Value<String> category,
      Value<int> priceInCents,
      Value<String> billingCycle,
      Value<DateTime> startDate,
      Value<DateTime> nextPaymentDate,
      Value<int?> billingAnchorDay,
      Value<String> status,
      Value<int> totalSpentInCents,
      Value<bool> reminderEnabled,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$SubscriptionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SubscriptionsTable, SubscriptionRecord> {
  $$SubscriptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PaymentsTable, List<PaymentRecord>>
  _paymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'subscriptions__id__payments__subscription_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.subscriptionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceInCents => $composableBuilder(
    column: $table.priceInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billingAnchorDay => $composableBuilder(
    column: $table.billingAnchorDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSpentInCents => $composableBuilder(
    column: $table.totalSpentInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.subscriptionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceInCents => $composableBuilder(
    column: $table.priceInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billingAnchorDay => $composableBuilder(
    column: $table.billingAnchorDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSpentInCents => $composableBuilder(
    column: $table.totalSpentInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get priceInCents => $composableBuilder(
    column: $table.priceInCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get nextPaymentDate => $composableBuilder(
    column: $table.nextPaymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billingAnchorDay => $composableBuilder(
    column: $table.billingAnchorDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalSpentInCents => $composableBuilder(
    column: $table.totalSpentInCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.subscriptionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          SubscriptionRecord,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (SubscriptionRecord, $$SubscriptionsTableReferences),
          SubscriptionRecord,
          PrefetchHooks Function({bool paymentsRefs})
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logo = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> priceInCents = const Value.absent(),
                Value<String> billingCycle = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> nextPaymentDate = const Value.absent(),
                Value<int?> billingAnchorDay = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalSpentInCents = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                logo: logo,
                category: category,
                priceInCents: priceInCents,
                billingCycle: billingCycle,
                startDate: startDate,
                nextPaymentDate: nextPaymentDate,
                billingAnchorDay: billingAnchorDay,
                status: status,
                totalSpentInCents: totalSpentInCents,
                reminderEnabled: reminderEnabled,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> logo = const Value.absent(),
                required String category,
                required int priceInCents,
                required String billingCycle,
                required DateTime startDate,
                required DateTime nextPaymentDate,
                Value<int?> billingAnchorDay = const Value.absent(),
                required String status,
                Value<int> totalSpentInCents = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                logo: logo,
                category: category,
                priceInCents: priceInCents,
                billingCycle: billingCycle,
                startDate: startDate,
                nextPaymentDate: nextPaymentDate,
                billingAnchorDay: billingAnchorDay,
                status: status,
                totalSpentInCents: totalSpentInCents,
                reminderEnabled: reminderEnabled,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubscriptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({paymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (paymentsRefs) db.payments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (paymentsRefs)
                    await $_getPrefetchedData<
                      SubscriptionRecord,
                      $SubscriptionsTable,
                      PaymentRecord
                    >(
                      currentTable: table,
                      referencedTable: $$SubscriptionsTableReferences
                          ._paymentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SubscriptionsTableReferences(
                            db,
                            table,
                            p0,
                          ).paymentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.subscriptionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      SubscriptionRecord,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (SubscriptionRecord, $$SubscriptionsTableReferences),
      SubscriptionRecord,
      PrefetchHooks Function({bool paymentsRefs})
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      required String subscriptionId,
      required int amountInCents,
      required DateTime date,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String> subscriptionId,
      Value<int> amountInCents,
      Value<DateTime> date,
      Value<int> rowid,
    });

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRecord> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubscriptionsTable _subscriptionIdTable(_$AppDatabase db) => db
      .subscriptions
      .createAlias('payments__subscription_id__subscriptions__id');

  $$SubscriptionsTableProcessedTableManager get subscriptionId {
    final $_column = $_itemColumn<String>('subscription_id')!;

    final manager = $$SubscriptionsTableTableManager(
      $_db,
      $_db.subscriptions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subscriptionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$SubscriptionsTableFilterComposer get subscriptionId {
    final $$SubscriptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableFilterComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubscriptionsTableOrderingComposer get subscriptionId {
    final $$SubscriptionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableOrderingComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$SubscriptionsTableAnnotationComposer get subscriptionId {
    final $$SubscriptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subscriptionId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRecord,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (PaymentRecord, $$PaymentsTableReferences),
          PaymentRecord,
          PrefetchHooks Function({bool subscriptionId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subscriptionId = const Value.absent(),
                Value<int> amountInCents = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                subscriptionId: subscriptionId,
                amountInCents: amountInCents,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subscriptionId,
                required int amountInCents,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                subscriptionId: subscriptionId,
                amountInCents: amountInCents,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subscriptionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subscriptionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subscriptionId,
                                referencedTable: $$PaymentsTableReferences
                                    ._subscriptionIdTable(db),
                                referencedColumn: $$PaymentsTableReferences
                                    ._subscriptionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRecord,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRecord, $$PaymentsTableReferences),
      PaymentRecord,
      PrefetchHooks Function({bool subscriptionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
}
