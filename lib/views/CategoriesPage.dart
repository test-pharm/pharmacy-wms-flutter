import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Services/CategoryService.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CategoryService.getCategories();
      setState(() {
        _categories = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    bool loading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = context.tr;
          return AlertDialog(
            title: Text(tr.createCategory),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr.categoryName,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => dialogError = tr.required);
                          return;
                        }
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });
                        try {
                          await CategoryService.createCategory(name);
                          Navigator.pop(context);
                          _loadCategories();
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          setDialogState(() => loading = false);
                        }
                      },
                child: Text(loading ? tr.loading : tr.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final nameCtrl = TextEditingController(text: category['name']);
    final id = category['id'] as int;
    bool loading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = context.tr;
          return AlertDialog(
            title: Text('${tr.edit}: ${category['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr.categoryName,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => dialogError = tr.required);
                          return;
                        }
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });
                        try {
                          await CategoryService.updateCategory(id, name);
                          Navigator.pop(context);
                          _loadCategories();
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          setDialogState(() => loading = false);
                        }
                      },
                child: Text(loading ? tr.loading : tr.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.confirmDelete),
        content: Text('Are you sure you want to delete category: ${category['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CategoryService.deleteCategory(category['id'] as int);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.success)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1A1F) : const Color(0xFFF5F9FA);
    final cardColor = isDark ? const Color(0xFF1A2F35) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF1CA0A5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(tr.createCategory, style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 10),
                Text(
                  tr.categoriesManagement,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: tr.refresh,
                  onPressed: _loadCategories,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildContent(cardColor, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color cardColor, bool isDark) {
    final tr = context.tr;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCategories,
              child: Text(tr.retry),
            ),
          ],
        ),
      );
    }
    if (_categories.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Found',
        subtitle: 'Create product categories to organize your inventory.',
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 110,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return Card(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1CA0A5).withOpacity(0.12),
                  child: const Icon(Icons.folder_outlined, color: Color(0xFF1CA0A5)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cat['name'] ?? tr.uncategorized,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditCategoryDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteCategory(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
