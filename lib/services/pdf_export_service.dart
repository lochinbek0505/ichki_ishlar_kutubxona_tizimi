import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/user_model.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._internal();

  PdfExportService._internal();

  /// A'zolik kartasini PDF shaklida yaratadi
  Future<Uint8List> generateReaderCardPdf(UserModel user) async {
    final pdf = pw.Document();

    pw.MemoryImage? profileImage;
    if (user.imagePath != null && user.imagePath!.isNotEmpty) {
      try {
        final file = File(user.imagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          profileImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    pw.MemoryImage? litseyImage;
    try {
      final litseyBytes = await rootBundle.load('assets/icons/litsey.png');
      litseyImage = pw.MemoryImage(litseyBytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#1E3A8A'),
                width: 3,
              ),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColor.fromHex('#F8FAFC'),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Litsey Logo
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E3A8A'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          if (litseyImage != null)
                            pw.Container(
                              width: 26,
                              height: 26,
                              margin: const pw.EdgeInsets.only(right: 6),
                              child: pw.Image(litseyImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'ICHKI ISHLAR VAZIRLIGI LITSEYI',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'KUTUBXONA A\'ZOLIK KARTASI',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#D4AF37'), // Gold
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#A38020'),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          user.readerCardId,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Main Content Body
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Rasm joyi
                      pw.Container(
                        width: 70,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 1),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: PdfColors.grey200,
                        ),
                        child: profileImage != null
                            ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                            : pw.Center(
                                child: pw.Text(
                                  'RASM',
                                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                                ),
                              ),
                      ),
                      pw.SizedBox(width: 10),

                      // Foydalanuvchi ma'lumotlari
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Text(
                              user.fullName,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#0F172A'),
                              ),
                              maxLines: 2,
                            ),
                            pw.SizedBox(height: 4),

                            if (user.bosqichName != null)
                              _buildInfoRow('Bosqich:', user.bosqichName!),
                            if (user.guruhName != null)
                              _buildInfoRow('Guruh:', user.guruhName!),
                            if (user.phone != null && user.phone!.isNotEmpty)
                              _buildInfoRow('Tel:', user.phone!),
                            _buildInfoRow('Sana:', user.createdAt.split('T').first),
                          ],
                        ),
                      ),

                      // QR kodi
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: user.readerCardId,
                            width: 55,
                            height: 55,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'QR KOD',
                            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Ushbu karta kutubxona mulki hisoblanadi.',
                      style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'IIV Litseyi Kutubxona Tizimi',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E3A8A'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 45,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E293B'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PDF faylni printerni qo'llash yoki chop etish uchun interfeys
  Future<void> printOrSaveReaderCard(UserModel user) async {
    final pdfBytes = await generateReaderCardPdf(user);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Azolik_Kartasi_${user.readerCardId}',
    );
  }
}
