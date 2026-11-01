import 'dart:io';

import 'package:flutter/material.dart';

import '../services/attendance_export_service.dart';

class AttendanceExportScreen extends StatefulWidget {
  final String filePath;

  const AttendanceExportScreen({
    super.key,
    required this.filePath,
  });

  @override
  State<AttendanceExportScreen> createState() =>
      _AttendanceExportScreenState();
}

class _AttendanceExportScreenState
    extends State<AttendanceExportScreen> {
  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color successGreen = Color(0xFF159957);
  static const Color background = Color(0xFFF5F8FC);

  final AttendanceExportService _service =
      AttendanceExportService();

  bool isDownloading = false;
  bool isExporting = false;

  Future<void> _download() async {
    if (isDownloading) return;

    setState(() => isDownloading = true);

    try {
      await _service.downloadWorkbook(widget.filePath);
    } catch (e) {
      _showMessage('Download failed: $e');
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  Future<void> _export() async {
    if (isExporting) return;

    setState(() => isExporting = true);

    try {
      await _service.shareWorkbook(widget.filePath);
    } catch (e) {
      _showMessage('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Export Attendance'),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: File(widget.filePath).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data != true) {
            return const Center(
              child: Text(
                'Workbook not found. Please generate Preview again.',
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.table_chart,
                    size: 55,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Attendance Workbook Ready',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Both actions use the same generated Excel workbook with all 12 monthly sheets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isDownloading ? null : _download,
                    icon: const Icon(Icons.download),
                    label: Text(
                      isDownloading
                          ? 'Downloading...'
                          : 'Download Excel',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isExporting ? null : _export,
                    icon: const Icon(Icons.share),
                    label: Text(
                      isExporting ? 'Exporting...' : 'Export / Share',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}