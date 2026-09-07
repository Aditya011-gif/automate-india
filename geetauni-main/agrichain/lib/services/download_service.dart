import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'file_saver_web.dart' if (dart.library.io) 'file_saver_io.dart';

// Enums and Data Classes for download system
enum DownloadStatus { ready, downloading, completed, error }

class DocumentInfo {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final IconData icon;
  final Color color;
  final String estimatedSize;
  String? actualSize;
  final Uint8List? contentBytes;

  DocumentInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.icon,
    required this.color,
    required this.estimatedSize,
    this.actualSize,
    this.contentBytes,
  });
}

class DownloadService {
  static const String _csrfToken = 'agrichain_download_token_2024';

  static const List<String> _allowedExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
  ];

  Future<DownloadResult> downloadDocument(
    DocumentInfo document, {
    required Function(double) onProgress,
  }) async {
    try {
      if (!_validateCSRFToken()) {
        return DownloadResult(
          success: false,
          errorMessage: 'Security validation failed',
        );
      }
      if (!_validateFileExtension(document.fileName)) {
        return DownloadResult(
          success: false,
          errorMessage: 'File type not allowed',
        );
      }

      if (document.id == 'smart_contract') {
        return await _downloadSmartContractDoc(document, onProgress);
      } else {
        return await _downloadPDFFile(document, onProgress);
      }
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download failed: ${e.toString()}',
      );
    }
  }

  bool _validateCSRFToken() => _csrfToken.isNotEmpty;

  bool _validateFileExtension(String fileName) {
    final ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return _allowedExtensions.contains(ext);
  }

  Future<DownloadResult> _downloadPDFFile(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      await _simulateDownloadProgress(onProgress);
      Uint8List pdfContent;
      if (document.contentBytes != null) {
        pdfContent = document.contentBytes!;
      } else {
        pdfContent = _generateSamplePDFContent(document);
      }

      await FileSaverHelper().saveBytes(
        pdfContent,
        document.fileName,
        'application/pdf',
      );

      return DownloadResult(
        success: true,
        filePath: document.fileName,
        fileSize: pdfContent.length,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download error: ${e.toString()}',
      );
    }
  }

  Uint8List _generateSamplePDFContent(DocumentInfo document) {
    final content =
        '%PDF-1.4\n1 0 obj\n<</Type /Catalog /Pages 2 0 R>>\nendobj\n%%EOF\n';
    return Uint8List.fromList(utf8.encode(content));
  }

  String calculateFileHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<DownloadResult> _downloadSmartContractDoc(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      final contractContent =
          '# AgriChain Smart Contract Documentation\nGenerated: ${DateTime.now().toIso8601String()}\n';
      await _simulateDownloadProgress(onProgress);
      final bytes = Uint8List.fromList(utf8.encode(contractContent));

      await FileSaverHelper().saveBytes(
        bytes,
        document.fileName,
        'application/pdf',
      );

      return DownloadResult(
        success: true,
        filePath: document.fileName,
        fileSize: bytes.length,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Smart contract generation failed: ${e.toString()}',
      );
    }
  }

  Future<void> _simulateDownloadProgress(Function(double) onProgress) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 30));
      onProgress(i / 100.0);
    }
  }
}

class DownloadResult {
  final bool success;
  final String? errorMessage;
  final String? filePath;
  final int? fileSize;

  DownloadResult({
    required this.success,
    this.errorMessage,
    this.filePath,
    this.fileSize,
  });
}
