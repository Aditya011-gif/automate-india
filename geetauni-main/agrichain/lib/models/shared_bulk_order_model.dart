library;

/// Model: Shared Multi-FPO Bulk Orders & Independent Contribution Records
/// Guarantees that each participating FPO retains isolated ownership, contribution commits, and individual settlements.

enum BulkOrderStatus {
  newOrder,
  confirmed,
  inventoryReserved,
  routePlanned,
  truckAssigned,
  pickupInProgress,
  inTransit,
  deliveredAwaitingInspection,
  accepted,
  settled,
  disputed,
  cancelled,
}

enum InspectionStatus {
  pendingArrival,
  inspectionWindowActive24h,
  accepted,
  disputed,
}

enum DisputeReason {
  qualityDefect, // e.g. Moisture > agreed limit, high foreign matter
  quantityShortage, // e.g. Weighbridge variance
  deliveryDelay,
  contractBreach,
  other,
}

enum CommercialSettlementStatus {
  pending,
  escrowed,
  readyForSettlement,
  settled,
  onHold,
  disputed,
}

class FpoContributionRecord {
  final String fpoId;
  final String fpoName;
  final String warehouseName;
  final double warehouseLat;
  final double warehouseLng;
  final double contributedQuantityMT;
  final double reservedQuantityMT;
  final double ratePerMT;
  final double ratePerQtl;
  final double grossPayableAmount;
  final double freightShare;
  final double applicableDeductions;
  final double netPayableAmount;
  final String pickupStatus; // 'pending', 'truck_arrived', 'loaded_and_weighed', 'departed'
  final DateTime? pickupTimestamp;
  final String? weighbridgeSlipNumber;
  final CommercialSettlementStatus settlementStatus;
  final String? settlementUtr;
  final DateTime? settledAt;

  const FpoContributionRecord({
    required this.fpoId,
    required this.fpoName,
    required this.warehouseName,
    this.warehouseLat = 29.6857,
    this.warehouseLng = 76.9905,
    required this.contributedQuantityMT,
    required this.reservedQuantityMT,
    required this.ratePerMT,
    required this.ratePerQtl,
    required this.grossPayableAmount,
    this.freightShare = 0.0,
    this.applicableDeductions = 0.0,
    required this.netPayableAmount,
    this.pickupStatus = 'pending',
    this.pickupTimestamp,
    this.weighbridgeSlipNumber,
    this.settlementStatus = CommercialSettlementStatus.escrowed,
    this.settlementUtr,
    this.settledAt,
  });

  FpoContributionRecord copyWith({
    String? pickupStatus,
    DateTime? pickupTimestamp,
    String? weighbridgeSlipNumber,
    CommercialSettlementStatus? settlementStatus,
    String? settlementUtr,
    DateTime? settledAt,
  }) {
    return FpoContributionRecord(
      fpoId: fpoId,
      fpoName: fpoName,
      warehouseName: warehouseName,
      warehouseLat: warehouseLat,
      warehouseLng: warehouseLng,
      contributedQuantityMT: contributedQuantityMT,
      reservedQuantityMT: reservedQuantityMT,
      ratePerMT: ratePerMT,
      ratePerQtl: ratePerQtl,
      grossPayableAmount: grossPayableAmount,
      freightShare: freightShare,
      applicableDeductions: applicableDeductions,
      netPayableAmount: netPayableAmount,
      pickupStatus: pickupStatus ?? this.pickupStatus,
      pickupTimestamp: pickupTimestamp ?? this.pickupTimestamp,
      weighbridgeSlipNumber: weighbridgeSlipNumber ?? this.weighbridgeSlipNumber,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      settlementUtr: settlementUtr ?? this.settlementUtr,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'fpoId': fpoId,
    'fpoName': fpoName,
    'warehouseName': warehouseName,
    'warehouseLat': warehouseLat,
    'warehouseLng': warehouseLng,
    'contributedQuantityMT': contributedQuantityMT,
    'reservedQuantityMT': reservedQuantityMT,
    'ratePerMT': ratePerMT,
    'ratePerQtl': ratePerQtl,
    'grossPayableAmount': grossPayableAmount,
    'freightShare': freightShare,
    'applicableDeductions': applicableDeductions,
    'netPayableAmount': netPayableAmount,
    'pickupStatus': pickupStatus,
    'pickupTimestamp': pickupTimestamp?.toIso8601String(),
    'weighbridgeSlipNumber': weighbridgeSlipNumber,
    'settlementStatus': settlementStatus.name,
    'settlementUtr': settlementUtr,
    'settledAt': settledAt?.toIso8601String(),
  };

  factory FpoContributionRecord.fromMap(Map<String, dynamic> map) => FpoContributionRecord(
    fpoId: map['fpoId'] ?? '',
    fpoName: map['fpoName'] ?? '',
    warehouseName: map['warehouseName'] ?? 'FPO Warehouse',
    warehouseLat: (map['warehouseLat'] as num?)?.toDouble() ?? 29.6857,
    warehouseLng: (map['warehouseLng'] as num?)?.toDouble() ?? 76.9905,
    contributedQuantityMT: (map['contributedQuantityMT'] as num?)?.toDouble() ?? 0.0,
    reservedQuantityMT: (map['reservedQuantityMT'] as num?)?.toDouble() ?? 0.0,
    ratePerMT: (map['ratePerMT'] as num?)?.toDouble() ?? 35600.0,
    ratePerQtl: (map['ratePerQtl'] as num?)?.toDouble() ?? 3560.0,
    grossPayableAmount: (map['grossPayableAmount'] as num?)?.toDouble() ?? 0.0,
    freightShare: (map['freightShare'] as num?)?.toDouble() ?? 0.0,
    applicableDeductions: (map['applicableDeductions'] as num?)?.toDouble() ?? 0.0,
    netPayableAmount: (map['netPayableAmount'] as num?)?.toDouble() ?? 0.0,
    pickupStatus: map['pickupStatus'] ?? 'pending',
    pickupTimestamp: map['pickupTimestamp'] != null ? DateTime.tryParse(map['pickupTimestamp']) : null,
    weighbridgeSlipNumber: map['weighbridgeSlipNumber'],
    settlementStatus: CommercialSettlementStatus.values.firstWhere(
      (e) => e.name == map['settlementStatus'],
      orElse: () => CommercialSettlementStatus.escrowed,
    ),
    settlementUtr: map['settlementUtr'],
    settledAt: map['settledAt'] != null ? DateTime.tryParse(map['settledAt']) : null,
  );
}

class SharedBulkOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String cropName;
  final String variety;
  final String qualityGrade;
  final double totalRequiredMT;
  final double totalFulfilledMT;
  final double consolidatedRatePerMT;
  final double totalOrderValue;
  final String originClusterName;
  final double clusterRadiusKm;
  final String destinationPlantName;
  final double destinationLat;
  final double destinationLng;
  final DateTime requiredDeliveryDate;
  final List<FpoContributionRecord> contributions;
  final BulkOrderStatus orderStatus;
  final InspectionStatus inspectionStatus;
  final DateTime? inspectionWindowExpiresAt;
  final CommercialSettlementStatus settlementStatus;
  final String? contractId;
  final String? shipmentId;
  final String? disputeReason;
  final String? disputeNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedBulkOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.cropName,
    required this.variety,
    required this.qualityGrade,
    required this.totalRequiredMT,
    required this.totalFulfilledMT,
    required this.consolidatedRatePerMT,
    required this.totalOrderValue,
    required this.originClusterName,
    this.clusterRadiusKm = 6.8,
    required this.destinationPlantName,
    this.destinationLat = 28.5355,
    this.destinationLng = 77.3910,
    required this.requiredDeliveryDate,
    required this.contributions,
    this.orderStatus = BulkOrderStatus.confirmed,
    this.inspectionStatus = InspectionStatus.pendingArrival,
    this.inspectionWindowExpiresAt,
    this.settlementStatus = CommercialSettlementStatus.escrowed,
    this.contractId,
    this.shipmentId,
    this.disputeReason,
    this.disputeNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSharedOrder => contributions.length > 1;

  /// Returns the specific contribution record for a given FPO ID
  FpoContributionRecord? getContributionForFpo(String fpoId) {
    try {
      return contributions.firstWhere((c) => c.fpoId == fpoId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'cropName': cropName,
    'variety': variety,
    'qualityGrade': qualityGrade,
    'totalRequiredMT': totalRequiredMT,
    'totalFulfilledMT': totalFulfilledMT,
    'consolidatedRatePerMT': consolidatedRatePerMT,
    'totalOrderValue': totalOrderValue,
    'originClusterName': originClusterName,
    'clusterRadiusKm': clusterRadiusKm,
    'destinationPlantName': destinationPlantName,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'requiredDeliveryDate': requiredDeliveryDate.toIso8601String(),
    'contributions': contributions.map((c) => c.toMap()).toList(),
    'orderStatus': orderStatus.name,
    'inspectionStatus': inspectionStatus.name,
    'inspectionWindowExpiresAt': inspectionWindowExpiresAt?.toIso8601String(),
    'settlementStatus': settlementStatus.name,
    'contractId': contractId,
    'shipmentId': shipmentId,
    'disputeReason': disputeReason,
    'disputeNotes': disputeNotes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SharedBulkOrder.fromMap(Map<String, dynamic> map, String id) => SharedBulkOrder(
    id: id,
    buyerId: map['buyerId'] ?? '',
    buyerName: map['buyerName'] ?? 'Institutional Buyer',
    cropName: map['cropName'] ?? 'Wheat',
    variety: map['variety'] ?? 'Milling Grade',
    qualityGrade: map['qualityGrade'] ?? 'Grade A',
    totalRequiredMT: (map['totalRequiredMT'] as num?)?.toDouble() ?? 300.0,
    totalFulfilledMT: (map['totalFulfilledMT'] as num?)?.toDouble() ?? 300.0,
    consolidatedRatePerMT: (map['consolidatedRatePerMT'] as num?)?.toDouble() ?? 35610.0,
    totalOrderValue: (map['totalOrderValue'] as num?)?.toDouble() ?? 10683000.0,
    originClusterName: map['originClusterName'] ?? 'Karnal-Taraori Agri Cluster',
    clusterRadiusKm: (map['clusterRadiusKm'] as num?)?.toDouble() ?? 6.8,
    destinationPlantName: map['destinationPlantName'] ?? 'AgroFoods Milling Plant, Kundli',
    destinationLat: (map['destinationLat'] as num?)?.toDouble() ?? 28.8785,
    destinationLng: (map['destinationLng'] as num?)?.toDouble() ?? 77.1275,
    requiredDeliveryDate: map['requiredDeliveryDate'] != null
        ? DateTime.tryParse(map['requiredDeliveryDate']) ?? DateTime.now().add(const Duration(days: 3))
        : DateTime.now().add(const Duration(days: 3)),
    contributions: (map['contributions'] as List<dynamic>?)
            ?.map((c) => FpoContributionRecord.fromMap(c as Map<String, dynamic>))
            .toList() ??
        const [],
    orderStatus: BulkOrderStatus.values.firstWhere(
      (e) => e.name == map['orderStatus'],
      orElse: () => BulkOrderStatus.confirmed,
    ),
    inspectionStatus: InspectionStatus.values.firstWhere(
      (e) => e.name == map['inspectionStatus'],
      orElse: () => InspectionStatus.pendingArrival,
    ),
    inspectionWindowExpiresAt: map['inspectionWindowExpiresAt'] != null
        ? DateTime.tryParse(map['inspectionWindowExpiresAt'])
        : null,
    settlementStatus: CommercialSettlementStatus.values.firstWhere(
      (e) => e.name == map['settlementStatus'],
      orElse: () => CommercialSettlementStatus.escrowed,
    ),
    contractId: map['contractId'] ?? 'CONTRACT-BPO-84920',
    shipmentId: map['shipmentId'] ?? 'SHP-MULTI-300MT',
    disputeReason: map['disputeReason'],
    disputeNotes: map['disputeNotes'],
    createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now() : DateTime.now(),
  );
}
