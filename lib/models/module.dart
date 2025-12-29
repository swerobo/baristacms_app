import 'module_field.dart';

class ModuleConfig {
  final List<String>? statuses;
  final String? defaultStatus;
  final List<String>? features;
  final bool? enableEmail;
  final bool? enableLabelPrint;

  ModuleConfig({
    this.statuses,
    this.defaultStatus,
    this.features,
    this.enableEmail,
    this.enableLabelPrint,
  });

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      statuses: json['statuses'] != null
          ? List<String>.from(json['statuses'])
          : null,
      defaultStatus: json['defaultStatus'],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
      enableEmail: json['enableEmail'],
      enableLabelPrint: json['enableLabelPrint'],
    );
  }
}

class Module {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final String? icon;
  final int isActive;
  final ModuleConfig? config;
  final int? menuId;
  final int? parentModuleId;
  final int? useInApp;
  final List<ModuleField>? fields;
  final String createdAt;
  final String updatedAt;

  Module({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    required this.isActive,
    this.config,
    this.menuId,
    this.parentModuleId,
    this.useInApp,
    this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      icon: json['icon'],
      isActive: json['is_active'] ?? 1,
      config: json['config'] != null
          ? ModuleConfig.fromJson(json['config'])
          : null,
      menuId: json['menu_id'],
      parentModuleId: json['parent_module_id'],
      useInApp: json['use_in_app'],
      fields: json['fields'] != null
          ? (json['fields'] as List)
              .map((f) => ModuleField.fromJson(f))
              .toList()
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
