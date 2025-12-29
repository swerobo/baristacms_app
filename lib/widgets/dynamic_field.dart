import 'package:flutter/material.dart';
import '../models/module_field.dart';

class DynamicField extends StatelessWidget {
  final ModuleField field;
  final dynamic value;
  final Function(dynamic) onChanged;

  const DynamicField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.fieldType) {
      case 'text':
      case 'email':
      case 'url':
        return _buildTextField();
      case 'number':
        return _buildNumberField();
      case 'textarea':
        return _buildTextArea();
      case 'select':
        return _buildDropdown();
      case 'boolean':
        return _buildSwitch();
      case 'date':
        return _buildDatePicker(context);
      default:
        return _buildTextField();
    }
  }

  Widget _buildTextField() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        labelText: field.displayName,
        border: const OutlineInputBorder(),
        suffixText: field.isRequired == 1 ? '*' : null,
      ),
      keyboardType: field.fieldType == 'email'
          ? TextInputType.emailAddress
          : field.fieldType == 'url'
              ? TextInputType.url
              : TextInputType.text,
      validator: field.isRequired == 1
          ? (val) => val?.isEmpty == true ? '${field.displayName} is required' : null
          : null,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        labelText: field.displayName,
        border: const OutlineInputBorder(),
        suffixText: field.isRequired == 1 ? '*' : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: field.isRequired == 1
          ? (val) => val?.isEmpty == true ? '${field.displayName} is required' : null
          : null,
      onChanged: (val) {
        final parsed = num.tryParse(val);
        onChanged(parsed ?? val);
      },
    );
  }

  Widget _buildTextArea() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        labelText: field.displayName,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      validator: field.isRequired == 1
          ? (val) => val?.isEmpty == true ? '${field.displayName} is required' : null
          : null,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown() {
    final options = field.options ?? [];
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: field.displayName,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      validator: field.isRequired == 1
          ? (val) => val == null ? '${field.displayName} is required' : null
          : null,
      onChanged: (val) => onChanged(val),
    );
  }

  Widget _buildSwitch() {
    final boolValue = value == true || value == 1 || value == '1' || value == 'true';
    return SwitchListTile(
      title: Text(field.displayName),
      value: boolValue,
      onChanged: (val) => onChanged(val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    DateTime? dateValue;
    if (value != null) {
      if (value is DateTime) {
        dateValue = value;
      } else if (value is String && value.isNotEmpty) {
        dateValue = DateTime.tryParse(value);
      }
    }

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dateValue ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().split('T').first);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.displayName,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          dateValue != null
              ? '${dateValue.year}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}'
              : 'Select date',
          style: TextStyle(
            color: dateValue != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
