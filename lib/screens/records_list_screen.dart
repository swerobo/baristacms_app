import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/module_provider.dart';
import '../providers/record_provider.dart';
import '../widgets/record_card.dart';
import '../widgets/barcode_scanner.dart';
import 'package:intl/intl.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _moduleName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moduleName = ModalRoute.of(context)?.settings.arguments as String?;
      if (_moduleName != null) {
        context.read<RecordProvider>().loadRecords(_moduleName!);
        context.read<ModuleProvider>().loadModule(_moduleName!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && _moduleName != null) {
      // Try to parse as record ID
      final id = int.tryParse(result);
      if (id != null) {
        final record = await context
            .read<RecordProvider>()
            .findRecordById(_moduleName!, id);
        if (record != null && mounted) {
          Navigator.pushNamed(
            context,
            '/record-detail',
            arguments: {'moduleName': _moduleName, 'recordId': id},
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Record #$id not found')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleProvider = context.watch<ModuleProvider>();
    final recordProvider = context.watch<RecordProvider>();
    final module = moduleProvider.currentModule;

    return Scaffold(
      appBar: AppBar(
        title: Text(module?.displayName ?? 'Records'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_moduleName != null) {
                recordProvider.loadRecords(_moduleName!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Barcode Scanner
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                recordProvider.clearSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      recordProvider.setSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    onPressed: _openBarcodeScanner,
                    tooltip: 'Scan Barcode',
                  ),
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: recordProvider.isLoading
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
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_moduleName != null) {
                                  recordProvider.loadRecords(_moduleName!);
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : recordProvider.filteredRecords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  recordProvider.searchQuery.isNotEmpty
                                      ? 'No records match your search'
                                      : 'No records yet',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              if (_moduleName != null) {
                                await recordProvider.loadRecords(_moduleName!);
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: recordProvider.filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record =
                                    recordProvider.filteredRecords[index];
                                return RecordCard(
                                  record: record,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/record-detail',
                                      arguments: {
                                        'moduleName': _moduleName,
                                        'recordId': record.id,
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/record-edit',
            arguments: {'moduleName': _moduleName, 'recordId': null},
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
