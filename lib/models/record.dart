class ModuleRecord {
  final int id;
  final int moduleId;
  final String name;
  final Map<String, dynamic>? data;
  final String status;
  final int? parentRecordId;
  final String? assignedTo;
  final String? createdBy;
  final String? updatedBy;
  final String createdAt;
  final String updatedAt;
  final String? thumbnail;
  final List<RecordImage>? images;
  final bool? isViewed;

  ModuleRecord({
    required this.id,
    required this.moduleId,
    required this.name,
    this.data,
    required this.status,
    this.parentRecordId,
    this.assignedTo,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnail,
    this.images,
    this.isViewed,
  });

  factory ModuleRecord.fromJson(Map<String, dynamic> json) {
    return ModuleRecord(
      id: json['id'],
      moduleId: json['module_id'],
      name: json['name'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      status: json['status'] ?? 'active',
      parentRecordId: json['parent_record_id'],
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      thumbnail: json['thumbnail'],
      images: json['images'] != null
          ? (json['images'] as List)
              .map((i) => RecordImage.fromJson(i))
              .toList()
          : null,
      isViewed: json['is_viewed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'data': data,
      'status': status,
      'assigned_to': assignedTo,
    };
  }
}

class RecordImage {
  final int id;
  final int moduleId;
  final int recordId;
  final String imagePath;
  final int sortOrder;
  final String? createdBy;
  final String createdAt;

  RecordImage({
    required this.id,
    required this.moduleId,
    required this.recordId,
    required this.imagePath,
    required this.sortOrder,
    this.createdBy,
    required this.createdAt,
  });

  factory RecordImage.fromJson(Map<String, dynamic> json) {
    return RecordImage(
      id: json['id'],
      moduleId: json['module_id'],
      recordId: json['record_id'],
      imagePath: json['image_path'],
      sortOrder: json['sort_order'] ?? 0,
      createdBy: json['created_by'],
      createdAt: json['created_at'],
    );
  }
}
