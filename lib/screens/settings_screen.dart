import 'dart:io';

import 'package:atelier/widgets/ThemeSelector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../core/theme/atelier_theme.dart';
import '../database/database_helper.dart';
import '../services/backup_service.dart';
import '../widgets/tb_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();

  int _customerCount = 0;
  int _attachmentCount = 0;
  int _imageBytes = 0;

  bool _loadingStats = true;
  String? _busyMessage;
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadStatsAndBackupDate();
  }

  // ── Load Stats & Backup Info ────────────────────────────────────────────────

  Future<void> _loadStatsAndBackupDate() async {
    setState(() => _loadingStats = true);
    final db = DatabaseHelper();
    final customers = await db.getAllCustomers();
    final appDir = await getApplicationDocumentsDirectory();

    int totalAttachments = 0;
    int totalBytes = 0;

    for (final c in customers) {
      final id = c['id'] as int?;
      if (id == null) continue;

      final imgs = await db.getCustomerImages(id);
      totalAttachments += imgs.length;

      for (final img in imgs) {
        final relativePath = img['image_path'] as String?;
        if (relativePath != null && relativePath.isNotEmpty) {
          final fullPath = relativePath.startsWith('/')
              ? relativePath
              : path.join(appDir.path, relativePath);
          final file = File(fullPath);
          if (file.existsSync()) {
            totalBytes += file.lengthSync();
          }
        }
      }
    }

    final lastBackup = await _backupService.getLastBackupDate();

    if (mounted) {
      setState(() {
        _customerCount = customers.length;
        _attachmentCount = totalAttachments;
        _imageBytes = totalBytes;
        _lastBackupDate = lastBackup;
        _loadingStats = false;
      });
    }
  }

  // ── Backup Flow (Reusing BackupService) ────────────────────────────────────

  Future<void> _handleBackup() async {
    setState(() => _busyMessage = 'Creating backup archive…');
    try {
      final result = await _backupService.exportBackup();

      if (!mounted) return;
      setState(() => _busyMessage = null);

      if (result.success) {
        TbSnackbar.success(context, result.message);
        final date = await _backupService.getLastBackupDate();
        if (mounted) setState(() => _lastBackupDate = date);
      } else {
        TbSnackbar.error(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busyMessage = null);
        TbSnackbar.error(context, 'Backup failed: ${e.toString()}');
      }
    }
  }

  // ── Restore Flow (Reusing BackupService) ───────────────────────────────────

  Future<void> _handleRestore() async {
    final confirmed = await _confirmRestoreDialog();
    if (!confirmed) return;

    setState(() => _busyMessage = 'Restoring database & images…');
    try {
      final result = await _backupService.importBackup();

      if (!mounted) return;
      setState(() => _busyMessage = null);

      if (result.success) {
        TbSnackbar.success(context, result.message);
        // Refresh customer list in Bloc
        context.read<CustomerBloc>().add(LoadCustomers());
        // Reload screen statistics
        await _loadStatsAndBackupDate();
      } else {
        TbSnackbar.error(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busyMessage = null);
        TbSnackbar.error(context, 'Restore failed: ${e.toString()}');
      }
    }
  }

  // ── Helper Formatter ───────────────────────────────────────────────────────

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get _formattedLastBackup {
    if (_lastBackupDate == null) return 'Never backed up';
    final d = _lastBackupDate!;
    return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<bool> _confirmRestoreDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restore Backup?',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will overwrite customers with matching mobile numbers and append new client records. This action cannot be undone.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AtelierTheme.brandPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Restore',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atelier',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Digital client management for bespoke tailors.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'All client measurement data and attachments remain 100% private on your device. Backups are compiled into local .zip archives.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Version 2.0.1 ',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewSection(),
                        const SizedBox(height: 32),
                        _buildDataSection(),
                        const SizedBox(height: 32),
                        ThemeSelector(),
                        const SizedBox(height: 32),
                        _buildAboutSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Busy Overlay during Export/Import
            if (_busyMessage != null)
              Container(
                color: Colors.black.withOpacity(0.65),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AtelierTheme.brandPrimary,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _busyMessage!,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevron_left, size: 24),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ────────────────────────────────────────────────────────────────

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OVERVIEW'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _loadingStats
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AtelierTheme.brandPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Column(
                  children: [
                    _StatRow(label: 'Clients', value: '$_customerCount'),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    _StatRow(label: 'Attachments', value: '$_attachmentCount'),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    _StatRow(
                      label: 'Image storage',
                      value: _formatBytes(_imageBytes),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    _StatRow(
                      label: 'Last backup',
                      value: _formattedLastBackup,
                      isSmallValue: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DATA MANAGEMENT'),
        const SizedBox(height: 8),
        _SettingRow(
          icon: LucideIcons.cloud_upload,
          label: 'Export Backup',
          hint: 'Compress records & photos into a .zip file',
          onTap: _handleBackup,
        ),
        _SettingRow(
          icon: LucideIcons.cloud_download,
          label: 'Restore Backup',
          hint: 'Import customer records from a .zip backup',
          onTap: _handleRestore,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ABOUT'),
        const SizedBox(height: 8),
        _SettingRow(
          icon: LucideIcons.info,
          label: 'About Atelier',
          hint: 'App info & privacy philosophy',
          onTap: _showAboutDialog,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                '2.0.1',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 11,
        letterSpacing: 2.0,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-Components
// ─────────────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.isSmallValue = false,
  });

  final String label;
  final String value;
  final bool isSmallValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: isSmallValue
                ? TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  )
                : TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
