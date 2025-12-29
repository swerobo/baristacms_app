import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/record_provider.dart';
import '../providers/module_provider.dart';
import '../models/module_field.dart';
import '../widgets/dynamic_field.dart';

class RecordEditScreen extends StatefulWidget {
  const RecordEditScreen({super.key});

  @override
  State<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends State<RecordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _moduleName;
  int? _recordId;
  bool _isNew = true;

  final TextEditingController _nameController = TextEditingController();
  String _status = 'active';
  Map<String, dynamic> _fieldValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _moduleName = args?['moduleName'] as String?;
      _recordId = args?['recordId'] as int?;
      _isNew = _recordId == null;

      if (!_isNew && _moduleName != null && _recordId != null) {
        _loadRecord();
      }
    });
  }

  Future<void> _loadRecord() async {
    await context.read<RecordProvider>().loadRecord(_moduleName!, _recordId!);
    final record = context.read<RecordProvider>().currentRecord;
    if (record != null) {
      setState(() {
        _nameController.text = record.name;
        _status = record.status;
        _fieldValues = Map<String, dynamic>.from(record.data ?? {});
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final moduleProvider = context.watch<ModuleProvider>();
    final module = moduleProvider.currentModule;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Record' : 'Edit Record'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: recordProvider.isLoading ? null : _saveRecord,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: recordProvider.isLoading && !_isNew
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Status dropdown
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: (module?.config?.statuses ?? ['active', 'inactive'])
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Fields
                    if (module?.fields != null && module!.fields!.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...module.fields!.map((field) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DynamicField(
                                    field: field,
                                    value: _fieldValues[field.name],
                                    onChanged: (value) {
                                      setState(() {
                                        _fieldValues[field.name] = value;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final recordProvider = context.read<RecordProvider>();

    final data = {
      'name': _nameController.text,
      'status': _status,
      'data': _fieldValues,
    };

    bool success;
    if (_isNew) {
      success = await recordProvider.createRecord(_moduleName!, data);
    } else {
      success = await recordProvider.updateRecord(_moduleName!, _recordId!, data);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNew ? 'Record created' : 'Record updated'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(recordProvider.error ?? 'Failed to save record'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
