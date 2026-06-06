import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_book/widgets/backup_widget.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _service = BackupService();

  bool _exportLoading = false;
  bool _importLoading = false;

  // null = no result banner shown yet
  ({StatusType type, String message})? _lastResult;

  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    final date = await _service.getLastBackupDate();
    if (mounted) setState(() => _lastBackupDate = date);
  }

  String get _lastBackupLabel {
    if (_lastBackupDate == null) return 'Never backed up';
    final d = _lastBackupDate!;
    return 'Last backup: ${d.day.toString().padLeft(2, '0')} '
        '${_monthName(d.month)} ${d.year}';
  }

  // ───────────────────────────── Export ──────────────────────────────────────

  Future<void> _onExport() async {
    setState(() {
      _exportLoading = true;
      _lastResult = null;
    });

    final result = await _service.exportBackup();

    if (!mounted) return;
    setState(() {
      _exportLoading = false;
      _lastResult = (
        type: result.success ? StatusType.success : StatusType.error,
        message: result.message,
      );
    });

    if (result.success) _loadLastBackupDate();
  }

  // ───────────────────────────── Import ──────────────────────────────────────

  Future<void> _onImport() async {
    final confirmed = await _showImportConfirmDialog();
    if (!confirmed) return;

    setState(() {
      _importLoading = true;
      _lastResult = null;
    });

    final result = await _service.importBackup();

    if (!mounted) return;
    setState(() {
      _importLoading = false;
      _lastResult = (
        type: result.success ? StatusType.success : StatusType.error,
        message: result.message,
      );
    });

    // Refresh the customer list on the home screen
    if (result.success && mounted) {
      context.read<CustomerBloc>().add(LoadCustomers());
    }
  }

  Future<bool> _showImportConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Backup'),
            content: const Text(
              'Restoring a backup will overwrite any customers that share '
              'the same mobile number. New customers in the backup will be '
              'added.\n\nThis cannot be undone. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final exportDescription = Platform.isAndroid
        ? 'Exports all customers and their images into a single '
              '.tailorbackup file saved to your Downloads folder.'
        : 'Exports all customers and their images into a single '
              '.tailorbackup file. You can save it to Files, iCloud Drive, or Google Drive.';

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Result banner
          if (_lastResult != null)
            StatusBanner(
              type: _lastResult!.type,
              message: _lastResult!.message,
              onDismiss: () => setState(() => _lastResult = null),
            ),

          // ── Export ────────────────────────────────────────────────────────
          const SectionHeader('EXPORT'),
          BackupActionCard(
            icon: Icons.backup,
            iconColor: Colors.deepPurple,
            title: 'Create Backup',
            description: exportDescription,
            lastRunLabel: _lastBackupLabel,
            buttonLabel: 'Create Backup',
            onPressed: _onExport,
            isLoading: _exportLoading,
          ),

          const SizedBox(height: 24),

          // ── Restore ───────────────────────────────────────────────────────
          const SectionHeader('RESTORE'),
          BackupActionCard(
            icon: Icons.restore,
            iconColor: Colors.orange,
            title: 'Restore Backup',
            description:
                'Pick a .tailorbackup file to restore your customers and images.',
            warning:
                'Customers with the same mobile number will be overwritten. '
                'New customers will be added.',
            buttonLabel: 'Restore Backup',
            onPressed: _onImport,
            isLoading: _importLoading,
          ),

          const SizedBox(height: 32),

          // ── How it works ──────────────────────────────────────────────────
          const SectionHeader('HOW IT WORKS'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  InfoTile(
                    icon: Icons.folder_zip_outlined,
                    text:
                        'The backup is a single .tailorbackup file containing '
                        'all customer records and images.',
                  ),
                  InfoTile(
                    icon: Icons.cloud_upload_outlined,
                    text:
                        'Store it in Google Drive, WhatsApp it to yourself, or '
                        'copy it to your PC — it will survive a factory reset.',
                  ),
                  InfoTile(
                    icon: Icons.smartphone,
                    text:
                        'After a reset, install the app, tap Restore, and pick '
                        'the backup file to get everything back.',
                  ),
                  InfoTile(
                    icon: Icons.warning_amber_rounded,
                    text:
                        'Always create a fresh backup before resetting your phone.',
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
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
    return names[month];
  }
}
