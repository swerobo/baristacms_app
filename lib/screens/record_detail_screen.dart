import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/record_provider.dart';
import '../providers/module_provider.dart';
import '../models/module_field.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  String? _moduleName;
  int? _recordId;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _moduleName = args?['moduleName'] as String?;
      _recordId = args?['recordId'] as int?;

      if (_moduleName != null && _recordId != null) {
        context.read<RecordProvider>().loadRecord(_moduleName!, _recordId!);
      }
    });
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    // Get services before async gap
    final authService = context.read<AuthService>();
    final recordProvider = context.read<RecordProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    XFile? pickedFile;

    try {
      pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false, // Better for iOS Limited Photo Access
      );
    } catch (e) {
      debugPrint('Image picker error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Could not access photos: ${e.toString()}')),
      );
      return;
    }

    if (pickedFile == null) {
      debugPrint('No image selected');
      return;
    }

    if (mounted) setState(() => _isUploading = true);

    try {
      // Read file and convert to base64
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine mime type from extension
      final ext = pickedFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Image';

      // Upload image
      final apiService = ApiService(authService);
      await apiService.uploadImage(_moduleName!, _recordId!, dataUrl);

      // Reload record to show new image
      await recordProvider.loadRecord(_moduleName!, _recordId!);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      debugPrint('Image upload error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final moduleProvider = context.watch<ModuleProvider>();
    final record = recordProvider.currentRecord;
    final module = moduleProvider.currentModule;

    return Scaffold(
      appBar: AppBar(
        title: Text(record?.name ?? 'Record Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/record-edit',
                arguments: {'moduleName': _moduleName, 'recordId': _recordId},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: record != null
          ? FloatingActionButton(
              onPressed: _isUploading ? null : _showImageSourcePicker,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_a_photo, color: Colors.white),
            )
          : null,
      body: recordProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : recordProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        recordProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : record == null
                  ? const Center(child: Text('Record not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          record.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _StatusBadge(status: record.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${record.id}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${_formatDate(record.createdAt)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (record.createdBy != null)
                                    Text(
                                      'By: ${record.createdBy}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Images
                          if (record.images != null &&
                              record.images!.isNotEmpty) ...[
                            const Text(
                              'Images',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: record.images!.length,
                                itemBuilder: (context, index) {
                                  final image = record.images![index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '${AppConfig.apiBaseUrl}${image.imagePath}',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Fields
                          if (record.data != null &&
                              record.data!.isNotEmpty) ...[
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: record.data!.entries.map((entry) {
                                    final field = module?.fields?.cast<ModuleField?>().firstWhere(
                                      (f) => f?.name == entry.key,
                                      orElse: () => null,
                                    );
                                    final displayName = field?.displayName ?? entry.key;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              entry.value?.toString() ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
            'Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_moduleName != null && _recordId != null) {
                final success = await context
                    .read<RecordProvider>()
                    .deleteRecord(_moduleName!, _recordId!);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record deleted')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
