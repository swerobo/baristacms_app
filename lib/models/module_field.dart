class ModuleField {
  final int id;
  final int moduleId;
  final String name;
  final String displayName;
  final String fieldType;
  final int isRequired;
  final List<String>? options;
  final String? defaultValue;
  final String? relationModule;
  final int? warningYellowDays;
  final int? warningRedDays;
  final String? warningMode;
  final int sortOrder;
  final int? weight;
  final String createdAt;

  ModuleField({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.displayName,
    required this.fieldType,
    required this.isRequired,
    this.options,
    this.defaultValue,
    this.relationModule,
    this.warningYellowDays,
    this.warningRedDays,
    this.warningMode,
    required this.sortOrder,
    this.weight,
    required this.createdAt,
  });

  factory ModuleField.fromJson(Map<String, dynamic> json) {
    return ModuleField(
      id: json['id'],
      moduleId: json['module_id'],
      name: json['name'],
      displayName: json['display_name'],
      fieldType: json['field_type'] ?? 'text',
      isRequired: json['is_required'] ?? 0,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      defaultValue: json['default_value'],
      relationModule: json['relation_module'],
      warningYellowDays: json['warning_yellow_days'],
      warningRedDays: json['warning_red_days'],
      warningMode: json['warning_mode'],
      sortOrder: json['sort_order'] ?? 0,
      weight: json['weight'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
