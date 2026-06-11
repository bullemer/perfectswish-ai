// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calibration_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCalibrationProfileCollection on Isar {
  IsarCollection<CalibrationProfile> get calibrationProfiles =>
      this.collection();
}

const CalibrationProfileSchema = CollectionSchema(
  name: r'CalibrationProfile',
  id: 8149835937359011631,
  properties: {
    r'calibrationType': PropertySchema(
      id: 0,
      name: r'calibrationType',
      type: IsarType.string,
    ),
    r'depthMetersPerPixel': PropertySchema(
      id: 1,
      name: r'depthMetersPerPixel',
      type: IsarType.double,
    ),
    r'gpsBucket': PropertySchema(
      id: 2,
      name: r'gpsBucket',
      type: IsarType.string,
    ),
    r'gymName': PropertySchema(
      id: 3,
      name: r'gymName',
      type: IsarType.string,
    ),
    r'hFloorMToPx': PropertySchema(
      id: 4,
      name: r'hFloorMToPx',
      type: IsarType.doubleList,
    ),
    r'hFloorPxToM': PropertySchema(
      id: 5,
      name: r'hFloorPxToM',
      type: IsarType.doubleList,
    ),
    r'homographyInliers': PropertySchema(
      id: 6,
      name: r'homographyInliers',
      type: IsarType.long,
    ),
    r'imageHeight': PropertySchema(
      id: 7,
      name: r'imageHeight',
      type: IsarType.long,
    ),
    r'imageWidth': PropertySchema(
      id: 8,
      name: r'imageWidth',
      type: IsarType.long,
    ),
    r'isPartialCalibration': PropertySchema(
      id: 9,
      name: r'isPartialCalibration',
      type: IsarType.bool,
    ),
    r'lensInfo': PropertySchema(
      id: 10,
      name: r'lensInfo',
      type: IsarType.string,
    ),
    r'orientation': PropertySchema(
      id: 11,
      name: r'orientation',
      type: IsarType.long,
    ),
    r'pixelsPerMeterAtHoop': PropertySchema(
      id: 12,
      name: r'pixelsPerMeterAtHoop',
      type: IsarType.double,
    ),
    r'reprojectionError': PropertySchema(
      id: 13,
      name: r'reprojectionError',
      type: IsarType.double,
    ),
    r'rimCenterX': PropertySchema(
      id: 14,
      name: r'rimCenterX',
      type: IsarType.double,
    ),
    r'rimCenterY': PropertySchema(
      id: 15,
      name: r'rimCenterY',
      type: IsarType.double,
    ),
    r'rimConfidence': PropertySchema(
      id: 16,
      name: r'rimConfidence',
      type: IsarType.double,
    ),
    r'rimDiameterPx': PropertySchema(
      id: 17,
      name: r'rimDiameterPx',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 18,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _calibrationProfileEstimateSize,
  serialize: _calibrationProfileSerialize,
  deserialize: _calibrationProfileDeserialize,
  deserializeProp: _calibrationProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'gymName': IndexSchema(
      id: -9222903619251786189,
      name: r'gymName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'gymName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'gpsBucket': IndexSchema(
      id: 691395510398642655,
      name: r'gpsBucket',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'gpsBucket',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _calibrationProfileGetId,
  getLinks: _calibrationProfileGetLinks,
  attach: _calibrationProfileAttach,
  version: '3.1.0+1',
);

int _calibrationProfileEstimateSize(
  CalibrationProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.calibrationType.length * 3;
  {
    final value = object.gpsBucket;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.gymName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.hFloorMToPx;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.hFloorPxToM;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.lensInfo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _calibrationProfileSerialize(
  CalibrationProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.calibrationType);
  writer.writeDouble(offsets[1], object.depthMetersPerPixel);
  writer.writeString(offsets[2], object.gpsBucket);
  writer.writeString(offsets[3], object.gymName);
  writer.writeDoubleList(offsets[4], object.hFloorMToPx);
  writer.writeDoubleList(offsets[5], object.hFloorPxToM);
  writer.writeLong(offsets[6], object.homographyInliers);
  writer.writeLong(offsets[7], object.imageHeight);
  writer.writeLong(offsets[8], object.imageWidth);
  writer.writeBool(offsets[9], object.isPartialCalibration);
  writer.writeString(offsets[10], object.lensInfo);
  writer.writeLong(offsets[11], object.orientation);
  writer.writeDouble(offsets[12], object.pixelsPerMeterAtHoop);
  writer.writeDouble(offsets[13], object.reprojectionError);
  writer.writeDouble(offsets[14], object.rimCenterX);
  writer.writeDouble(offsets[15], object.rimCenterY);
  writer.writeDouble(offsets[16], object.rimConfidence);
  writer.writeDouble(offsets[17], object.rimDiameterPx);
  writer.writeDateTime(offsets[18], object.timestamp);
}

CalibrationProfile _calibrationProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CalibrationProfile();
  object.calibrationType = reader.readString(offsets[0]);
  object.depthMetersPerPixel = reader.readDoubleOrNull(offsets[1]);
  object.gpsBucket = reader.readStringOrNull(offsets[2]);
  object.gymName = reader.readStringOrNull(offsets[3]);
  object.hFloorMToPx = reader.readDoubleList(offsets[4]);
  object.hFloorPxToM = reader.readDoubleList(offsets[5]);
  object.homographyInliers = reader.readLongOrNull(offsets[6]);
  object.id = id;
  object.imageHeight = reader.readLong(offsets[7]);
  object.imageWidth = reader.readLong(offsets[8]);
  object.isPartialCalibration = reader.readBool(offsets[9]);
  object.lensInfo = reader.readStringOrNull(offsets[10]);
  object.orientation = reader.readLong(offsets[11]);
  object.pixelsPerMeterAtHoop = reader.readDoubleOrNull(offsets[12]);
  object.reprojectionError = reader.readDoubleOrNull(offsets[13]);
  object.rimCenterX = reader.readDoubleOrNull(offsets[14]);
  object.rimCenterY = reader.readDoubleOrNull(offsets[15]);
  object.rimConfidence = reader.readDoubleOrNull(offsets[16]);
  object.rimDiameterPx = reader.readDoubleOrNull(offsets[17]);
  object.timestamp = reader.readDateTime(offsets[18]);
  return object;
}

P _calibrationProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleList(offset)) as P;
    case 5:
      return (reader.readDoubleList(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _calibrationProfileGetId(CalibrationProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _calibrationProfileGetLinks(
    CalibrationProfile object) {
  return [];
}

void _calibrationProfileAttach(
    IsarCollection<dynamic> col, Id id, CalibrationProfile object) {
  object.id = id;
}

extension CalibrationProfileQueryWhereSort
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QWhere> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CalibrationProfileQueryWhere
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QWhereClause> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gymNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gymName',
        value: [null],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gymNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'gymName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gymNameEqualTo(String? gymName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gymName',
        value: [gymName],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gymNameNotEqualTo(String? gymName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gymName',
              lower: [],
              upper: [gymName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gymName',
              lower: [gymName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gymName',
              lower: [gymName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gymName',
              lower: [],
              upper: [gymName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gpsBucketIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gpsBucket',
        value: [null],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gpsBucketIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'gpsBucket',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gpsBucketEqualTo(String? gpsBucket) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gpsBucket',
        value: [gpsBucket],
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterWhereClause>
      gpsBucketNotEqualTo(String? gpsBucket) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gpsBucket',
              lower: [],
              upper: [gpsBucket],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gpsBucket',
              lower: [gpsBucket],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gpsBucket',
              lower: [gpsBucket],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gpsBucket',
              lower: [],
              upper: [gpsBucket],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CalibrationProfileQueryFilter
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QFilterCondition> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calibrationType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'calibrationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'calibrationType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calibrationType',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      calibrationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'calibrationType',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'depthMetersPerPixel',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'depthMetersPerPixel',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'depthMetersPerPixel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'depthMetersPerPixel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'depthMetersPerPixel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      depthMetersPerPixelBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'depthMetersPerPixel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gpsBucket',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gpsBucket',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gpsBucket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gpsBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gpsBucket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gpsBucket',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gpsBucketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gpsBucket',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gymName',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gymName',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gymName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gymName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gymName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gymName',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      gymNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gymName',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hFloorMToPx',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hFloorMToPx',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hFloorMToPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hFloorMToPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hFloorMToPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hFloorMToPx',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorMToPxLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorMToPx',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hFloorPxToM',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hFloorPxToM',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hFloorPxToM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hFloorPxToM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hFloorPxToM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hFloorPxToM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      hFloorPxToMLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hFloorPxToM',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'homographyInliers',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'homographyInliers',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'homographyInliers',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'homographyInliers',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'homographyInliers',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      homographyInliersBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'homographyInliers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageHeightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageHeightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageHeightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageWidthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageWidth',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageWidthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageWidth',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageWidthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageWidth',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      imageWidthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageWidth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      isPartialCalibrationEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPartialCalibration',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lensInfo',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lensInfo',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lensInfo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lensInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lensInfo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lensInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      lensInfoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lensInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      orientationEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orientation',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      orientationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orientation',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      orientationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orientation',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      orientationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orientation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pixelsPerMeterAtHoop',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pixelsPerMeterAtHoop',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pixelsPerMeterAtHoop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pixelsPerMeterAtHoop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pixelsPerMeterAtHoop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      pixelsPerMeterAtHoopBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pixelsPerMeterAtHoop',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reprojectionError',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reprojectionError',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reprojectionError',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reprojectionError',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reprojectionError',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      reprojectionErrorBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reprojectionError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rimCenterX',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rimCenterX',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rimCenterX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rimCenterX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rimCenterX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterXBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rimCenterX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rimCenterY',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rimCenterY',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rimCenterY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rimCenterY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rimCenterY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimCenterYBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rimCenterY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rimConfidence',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rimConfidence',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rimConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rimConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rimConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rimConfidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rimDiameterPx',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rimDiameterPx',
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rimDiameterPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rimDiameterPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rimDiameterPx',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      rimDiameterPxBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rimDiameterPx',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CalibrationProfileQueryObject
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QFilterCondition> {}

extension CalibrationProfileQueryLinks
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QFilterCondition> {}

extension CalibrationProfileQuerySortBy
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QSortBy> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByCalibrationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calibrationType', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByCalibrationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calibrationType', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByDepthMetersPerPixel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depthMetersPerPixel', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByDepthMetersPerPixelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depthMetersPerPixel', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByGpsBucket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsBucket', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByGpsBucketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsBucket', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByGymName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymName', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByGymNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymName', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByHomographyInliers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homographyInliers', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByHomographyInliersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homographyInliers', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByImageHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageHeight', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByImageHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageHeight', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByImageWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageWidth', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByImageWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageWidth', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByIsPartialCalibration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCalibration', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByIsPartialCalibrationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCalibration', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByLensInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lensInfo', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByLensInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lensInfo', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByPixelsPerMeterAtHoop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pixelsPerMeterAtHoop', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByPixelsPerMeterAtHoopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pixelsPerMeterAtHoop', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByReprojectionError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reprojectionError', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByReprojectionErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reprojectionError', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimCenterX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterX', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimCenterXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterX', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimCenterY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterY', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimCenterYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterY', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimConfidence', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimConfidence', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimDiameterPx() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimDiameterPx', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByRimDiameterPxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimDiameterPx', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension CalibrationProfileQuerySortThenBy
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QSortThenBy> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByCalibrationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calibrationType', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByCalibrationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calibrationType', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByDepthMetersPerPixel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depthMetersPerPixel', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByDepthMetersPerPixelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depthMetersPerPixel', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByGpsBucket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsBucket', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByGpsBucketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsBucket', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByGymName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymName', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByGymNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymName', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByHomographyInliers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homographyInliers', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByHomographyInliersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homographyInliers', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByImageHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageHeight', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByImageHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageHeight', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByImageWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageWidth', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByImageWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageWidth', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByIsPartialCalibration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCalibration', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByIsPartialCalibrationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCalibration', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByLensInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lensInfo', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByLensInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lensInfo', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByPixelsPerMeterAtHoop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pixelsPerMeterAtHoop', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByPixelsPerMeterAtHoopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pixelsPerMeterAtHoop', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByReprojectionError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reprojectionError', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByReprojectionErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reprojectionError', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimCenterX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterX', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimCenterXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterX', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimCenterY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterY', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimCenterYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimCenterY', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimConfidence', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimConfidence', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimDiameterPx() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimDiameterPx', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByRimDiameterPxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rimDiameterPx', Sort.desc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension CalibrationProfileQueryWhereDistinct
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct> {
  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByCalibrationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calibrationType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByDepthMetersPerPixel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'depthMetersPerPixel');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByGpsBucket({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gpsBucket', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByGymName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gymName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByHFloorMToPx() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hFloorMToPx');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByHFloorPxToM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hFloorPxToM');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByHomographyInliers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'homographyInliers');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByImageHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageHeight');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByImageWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageWidth');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByIsPartialCalibration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPartialCalibration');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByLensInfo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lensInfo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orientation');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByPixelsPerMeterAtHoop() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pixelsPerMeterAtHoop');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByReprojectionError() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reprojectionError');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByRimCenterX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rimCenterX');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByRimCenterY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rimCenterY');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByRimConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rimConfidence');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByRimDiameterPx() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rimDiameterPx');
    });
  }

  QueryBuilder<CalibrationProfile, CalibrationProfile, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension CalibrationProfileQueryProperty
    on QueryBuilder<CalibrationProfile, CalibrationProfile, QQueryProperty> {
  QueryBuilder<CalibrationProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CalibrationProfile, String, QQueryOperations>
      calibrationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calibrationType');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      depthMetersPerPixelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'depthMetersPerPixel');
    });
  }

  QueryBuilder<CalibrationProfile, String?, QQueryOperations>
      gpsBucketProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gpsBucket');
    });
  }

  QueryBuilder<CalibrationProfile, String?, QQueryOperations>
      gymNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gymName');
    });
  }

  QueryBuilder<CalibrationProfile, List<double>?, QQueryOperations>
      hFloorMToPxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hFloorMToPx');
    });
  }

  QueryBuilder<CalibrationProfile, List<double>?, QQueryOperations>
      hFloorPxToMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hFloorPxToM');
    });
  }

  QueryBuilder<CalibrationProfile, int?, QQueryOperations>
      homographyInliersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'homographyInliers');
    });
  }

  QueryBuilder<CalibrationProfile, int, QQueryOperations>
      imageHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageHeight');
    });
  }

  QueryBuilder<CalibrationProfile, int, QQueryOperations> imageWidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageWidth');
    });
  }

  QueryBuilder<CalibrationProfile, bool, QQueryOperations>
      isPartialCalibrationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPartialCalibration');
    });
  }

  QueryBuilder<CalibrationProfile, String?, QQueryOperations>
      lensInfoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lensInfo');
    });
  }

  QueryBuilder<CalibrationProfile, int, QQueryOperations>
      orientationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orientation');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      pixelsPerMeterAtHoopProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pixelsPerMeterAtHoop');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      reprojectionErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reprojectionError');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      rimCenterXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rimCenterX');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      rimCenterYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rimCenterY');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      rimConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rimConfidence');
    });
  }

  QueryBuilder<CalibrationProfile, double?, QQueryOperations>
      rimDiameterPxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rimDiameterPx');
    });
  }

  QueryBuilder<CalibrationProfile, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
