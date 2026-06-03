import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/auditLogModel.dart';
import 'package:pharmacy_wms/Services/auditLogService.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';
import 'package:pharmacy_wms/widgets/skeletons.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});
  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<AuditLogModel> _logs = [];
  List<AuditLogModel> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  bool _filtersExpanded = false;
  String _actionFilter = '';
  String _entityTypeFilter = '';
  final _fromDateCtrl = TextEditingController();
  final _toDateCtrl = TextEditingController();

  int get _activeFilterCount {
    int c = 0;
    if (_actionFilter.isNotEmpty) c++;
    if (_entityTypeFilter.isNotEmpty) c++;
    if (_fromDateCtrl.text.isNotEmpty) c++;
    if (_toDateCtrl.text.isNotEmpty) c++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _logs = await AuditLogService.getAll();
      _filter();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clearFilters() {
    setState(() {
      _actionFilter = '';
      _entityTypeFilter = '';
      _fromDateCtrl.clear();
      _toDateCtrl.clear();
      _filter();
    });
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _logs.where((log) {
        final matchesSearch = query.isEmpty ||
            log.action.toLowerCase().contains(query) ||
            log.userName.toLowerCase().contains(query) ||
            log.entityType.toLowerCase().contains(query) ||
            (log.details?.toLowerCase().contains(query) ?? false);
        final matchesAction = _actionFilter.isEmpty || log.action.contains(_actionFilter);
        final matchesEntityType = _entityTypeFilter.isEmpty || log.entityType == _entityTypeFilter;
        final matchesFrom = _fromDateCtrl.text.isEmpty || (log.timestamp.isAfter(DateTime.tryParse(_fromDateCtrl.text) ?? DateTime(2000)));
        final matchesTo = _toDateCtrl.text.isEmpty || (log.timestamp.isBefore(DateTime.tryParse(_toDateCtrl.text) ?? DateTime(2100)));
        return matchesSearch && matchesAction && matchesEntityType && matchesFrom && matchesTo;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 10),
                Text(
                  tr.auditLog,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: tr.refresh,
                  onPressed: _load,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: tr.searchAuditLog,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (_) => _filter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                          icon: AnimatedRotation(
                            turns: _filtersExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.tune, size: 18),
                          ),
                          label: Text(_filtersExpanded ? 'Hide Filters' : 'Filters'),
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                              child: Text('$_activeFilterCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ],
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 4),
                      TextButton(onPressed: _clearFilters, child: const Text('Clear All')),
                    ],
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _filtersExpanded ? _buildFilterPanel(tr, isDark) : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(tr, isDark),
          ),
          if (!_loading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              alignment: Alignment.centerRight,
              child: Text(
                tr.noOfItems(_filtered.length),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _filter();
      });
    }
  }

  Widget _buildFilterPanel(AppLocalizations tr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Action',
                    hintText: 'Filter by action',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) { _actionFilter = v; _filter(); },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Entity Type',
                    hintText: 'e.g. User, Product',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) { _entityTypeFilter = v; _filter(); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'From Date',
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    suffixIcon: const Icon(Icons.calendar_today, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onTap: () => _selectDate(context, _fromDateCtrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _toDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'To Date',
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    suffixIcon: const Icon(Icons.calendar_today, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onTap: () => _selectDate(context, _toDateCtrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations tr, bool isDark) {
    if (_loading) {
      return const AuditLogSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: Text(tr.retry),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.history_toggle_off,
        title: 'No Audit Logs',
        subtitle: 'Actions will appear here as users interact with the system.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final log = _filtered[index];
        return _LogCard(log: log, isDark: isDark);
      },
    );
  }
}

class _LogCard extends StatefulWidget {
  final AuditLogModel log;
  final bool isDark;
  const _LogCard({required this.log, required this.isDark});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  Color get _actionColor {
    final act = widget.log.action.toLowerCase();
    if (act.contains('create') || act.contains('add')) return Colors.green;
    if (act.contains('delete') || act.contains('remove')) return Colors.red;
    if (act.contains('update') || act.contains('edit') || act.contains('change')) return Colors.orange;
    if (act.contains('login')) return Colors.blue;
    if (act.contains('register')) return Colors.teal;
    return Colors.grey;
  }

  IconData get _actionIcon {
    final act = widget.log.action;
    if (act.contains('Create') || act.contains('Add')) return Icons.add_circle_outline;
    if (act.contains('Delete') || act.contains('Remove')) return Icons.remove_circle_outline;
    if (act.contains('Update') || act.contains('Edit') || act.contains('Change')) return Icons.edit_outlined;
    if (act.contains('Login')) return Icons.login;
    if (act.contains('Register')) return Icons.person_add_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = widget.log.details != null && widget.log.details!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: _expanded ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: _expanded
            ? BorderSide(color: widget.isDark ? Colors.white24 : Colors.black12, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: hasDetails ? () => setState(() => _expanded = !_expanded) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_actionIcon, size: 18, color: _actionColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.log.action,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  if (hasDetails)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.log.roleLabel == 'Manager'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.log.roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.log.roleLabel == 'Manager' ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 13, color: widget.isDark ? Colors.white60 : Colors.black54),
                  const SizedBox(width: 4),
                  Text(widget.log.userName,
                      style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white60 : Colors.black54)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 13, color: widget.isDark ? Colors.white60 : Colors.black54),
                  const SizedBox(width: 4),
                  Text(widget.log.formattedTimestamp,
                      style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
              if (hasDetails) ...[
                const SizedBox(height: 6),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_expanded)
                        Text(
                          widget.log.details!,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white54 : Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else ...[
                        const Divider(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.black26 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: widget.isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.log.details!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: widget.isDark ? Colors.lightBlueAccent.shade100 : Colors.blueGrey.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Copy Details',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.log.details!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Details copied to clipboard!'), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
