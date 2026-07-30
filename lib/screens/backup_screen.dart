// // lib/screens/backup_screen.dart
// import 'dart:io' show Platform;

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:tailor_book/core/theme/app_txt_styles.dart';
// import 'package:tailor_book/widgets/tb_button.dart';
// import 'package:tailor_book/widgets/tb_card.dart';
// import 'package:tailor_book/widgets/tb_msc_widget.dart';

// import '../bloc/customer_bloc.dart';
// import '../bloc/customer_event.dart';
// import '../core/theme/app_colors.dart';
// import '../services/backup_service.dart';

// class BackupScreen extends StatefulWidget {
//   const BackupScreen({super.key});

//   @override
//   State<BackupScreen> createState() => _BackupScreenState();
// }

// class _BackupScreenState extends State<BackupScreen> {
//   final _service = BackupService();
//   bool _exportLoading = false;
//   bool _importLoading = false;
//   ({bool success, String message})? _result;
//   DateTime? _lastBackup;

//   @override
//   void initState() {
//     super.initState();
//     _service.getLastBackupDate().then((d) {
//       if (mounted) setState(() => _lastBackup = d);
//     });
//   }

//   String get _lastBackupLabel {
//     if (_lastBackup == null) return 'Never backed up';
//     final d = _lastBackup!;
//     return 'Last backup: ${d.day.toString().padLeft(2, '0')} '
//         '${_monthName(d.month)} ${d.year}  •  '
//         '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
//   }

//   Future<void> _export() async {
//     setState(() {
//       _exportLoading = true;
//       _result = null;
//     });
//     final r = await _service.exportBackup();
//     if (!mounted) return;
//     setState(() {
//       _exportLoading = false;
//       _result = (success: r.success, message: r.message);
//     });
//     if (r.success) {
//       _service.getLastBackupDate().then((d) {
//         if (mounted) setState(() => _lastBackup = d);
//       });
//     }
//   }

//   Future<void> _import() async {
//     final ok = await _confirm();
//     if (!ok) return;
//     setState(() {
//       _importLoading = true;
//       _result = null;
//     });
//     final r = await _service.importBackup();
//     if (!mounted) return;
//     setState(() {
//       _importLoading = false;
//       _result = (success: r.success, message: r.message);
//     });
//     if (r.success && mounted) {
//       context.read<CustomerBloc>().add(LoadCustomers());
//     }
//   }

//   Future<bool> _confirm() async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             title: const Text('Restore Backup'),
//             content: const Text(
//               'This will overwrite customers with matching mobile numbers '
//               'and add new ones. This cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx, false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx, true),
//                 style: TextButton.styleFrom(foregroundColor: AppColors.warning),
//                 child: const Text('Restore'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
//           children: [
//             // ── Page title ────────────────────────────────────────────────────
//             Text('Data Management', style: AppTextStyles.headlineMd()),
//             const SizedBox(height: 4),
//             Text(
//               'Secure your client data and restore when needed.',
//               style: AppTextStyles.bodyMd(),
//             ),

//             const SizedBox(height: 24),

//             // ── Result banner ─────────────────────────────────────────────────
//             if (_result != null) ...[
//               _ResultBanner(
//                 success: _result!.success,
//                 message: _result!.message,
//                 onDismiss: () => setState(() => _result = null),
//               ),
//               const SizedBox(height: 16),
//             ],

//             // ── Export card ───────────────────────────────────────────────────
//             TbCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       _IconBox(
//                         icon: Icons.cloud_upload_outlined,
//                         color: AppColors.primaryAccent,
//                       ),
//                       const Spacer(),
//                       _StatusDot(ready: !_exportLoading),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   Text('Export Database', style: AppTextStyles.headlineSm()),
//                   const SizedBox(height: 6),
//                   Text(
//                     Platform.isAndroid
//                         ? 'Exports all clients and images to a .zip file in your Downloads folder.'
//                         : 'Exports all clients and images. Share it to Files, iCloud, or Google Drive.',
//                     style: AppTextStyles.bodySm(),
//                   ),
//                   const SizedBox(height: 12),
//                   // Last backup chip
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.surfaceContHigh,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.history,
//                           size: 13,
//                           color: AppColors.muted,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(_lastBackupLabel, style: AppTextStyles.labelMd()),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TbButton(
//                     label: 'EXPORT NOW',
//                     icon: Icons.cloud_upload_outlined,
//                     onPressed: _export,
//                     isLoading: _exportLoading,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // ── Restore card ──────────────────────────────────────────────────
//             TbCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _IconBox(
//                     icon: Icons.cloud_download_outlined,
//                     color: AppColors.muted,
//                   ),
//                   const SizedBox(height: 14),
//                   Text('Restore Data', style: AppTextStyles.headlineSm()),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Recover your customer database from a .zip file.',
//                     style: AppTextStyles.bodySm(),
//                   ),
//                   const SizedBox(height: 12),
//                   // Warning chip
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.warning.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: AppColors.warning.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.warning_amber_rounded,
//                           size: 13,
//                           color: AppColors.warning,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           'Will overwrite matching records',
//                           style: AppTextStyles.labelMd(
//                             color: AppColors.warning,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TbButton(
//                     label: 'RESTORE NOW',
//                     icon: Icons.restore,
//                     onPressed: _import,
//                     isLoading: _importLoading,
//                     variant: TbButtonVariant.secondary,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 32),

//             // ── How it works stepper ──────────────────────────────────────────
//             TbCard(
//               color: AppColors.surfaceCont,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('HOW IT WORKS', style: AppTextStyles.labelMd()),
//                   const SizedBox(height: 16),
//                   const _StepRow(
//                     steps: ['Create Backup', 'Store Safely', 'Restore Anytime'],
//                   ),
//                   const SizedBox(height: 16),
//                   TbInfoRow(
//                     icon: Icons.folder_zip_outlined,
//                     text:
//                         'One .zip file contains all your client records and images.',
//                   ),
//                   const SizedBox(height: 4),
//                   TbInfoRow(
//                     icon: Icons.cloud_outlined,
//                     text: 'Upload to Google Drive or WhatsApp yourself.',
//                   ),
//                   const SizedBox(height: 4),
//                   TbInfoRow(
//                     icon: Icons.warning_amber_rounded,
//                     text:
//                         'Always backup before uninstalling the app or  resetting your phone.',
//                     iconColor: AppColors.warning,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _monthName(int m) {
//     const n = [
//       '',
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     return n[m];
//   }
// }

// // ── Local widgets ──────────────────────────────────────────────────────────────

// class _IconBox extends StatelessWidget {
//   const _IconBox({required this.icon, required this.color});
//   final IconData icon;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceContHigh,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Icon(icon, color: color, size: 22),
//     );
//   }
// }

// class _StatusDot extends StatelessWidget {
//   const _StatusDot({required this.ready});
//   final bool ready;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text('STATUS', style: AppTextStyles.labelMd(color: AppColors.muted)),
//         const SizedBox(width: 8),
//         Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: ready ? AppColors.secondary : AppColors.muted,
//           ),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           ready ? 'Ready' : 'Working…',
//           style: AppTextStyles.labelMd(
//             color: ready ? AppColors.secondary : AppColors.muted,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ResultBanner extends StatelessWidget {
//   const _ResultBanner({
//     required this.success,
//     required this.message,
//     required this.onDismiss,
//   });
//   final bool success;
//   final String message;
//   final VoidCallback onDismiss;

//   @override
//   Widget build(BuildContext context) {
//     final color = success ? AppColors.secondary : AppColors.error;
//     final icon = success ? Icons.check_circle_outline : Icons.error_outline;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 18),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(message, style: AppTextStyles.bodyMd(color: color)),
//           ),
//           GestureDetector(
//             onTap: onDismiss,
//             child: Icon(Icons.close, color: color, size: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StepRow extends StatelessWidget {
//   const _StepRow({required this.steps});
//   final List<String> steps;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: List.generate(steps.length * 2 - 1, (i) {
//         if (i.isOdd) {
//           return Expanded(
//             child: Container(height: 1, color: AppColors.outlineVariant),
//           );
//         }
//         final si = i ~/ 2;
//         return Column(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: AppColors.outlineVariant),
//                 color: AppColors.surfaceContHigh,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 '${si + 1}',
//                 style: AppTextStyles.labelMd(color: AppColors.onSurfaceVariant),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               steps[si],
//               style: AppTextStyles.bodyMd().copyWith(fontSize: 12),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         );
//       }),
//     );
//   }
// }
