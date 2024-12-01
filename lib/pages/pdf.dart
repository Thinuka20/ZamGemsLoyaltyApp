import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';


class PDFGenerator {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Map<String, dynamic>> filteredData;
  final BuildContext context;

  PDFGenerator({
    required this.fromDate,
    required this.toDate,
    required this.filteredData,
    required this.context,
  });

  Future<void> generateAndShowPDF() async {
    try {
      final pdf = await _createPDF();
      final pdfBytes = await pdf.save();

      if (!context.mounted) return;

      await _showPDFDialog(pdfBytes);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorMessage('Error generating PDF: ${e.toString()}');
    }
  }

  Future<pw.Document> _createPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildPage(context),
      ),
    );

    return pdf;
  }

  pw.Widget _buildPage(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        pw.SizedBox(height: 20),
        _buildTitle(),
        pw.SizedBox(height: 20),
        _buildTable(),
        pw.Spacer(),
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SKYNET PRO',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'DISTRIBUTED ERP',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Text(
          'From : ${DateFormat('yyyy-MM-dd').format(fromDate)} To : ${DateFormat('yyyy-MM-dd').format(toDate)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildTitle() {
    return pw.Text(
      'SKYNET Pro Sales Reports',
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildTable() {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _buildTableHeader(),
        ...filteredData.map(_buildDataRow),
        _buildTotalRow(),
      ],
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      children: [
        'Location',
        'BusinessType',
        'Total\nSale(LKR)',
        'Cash',
        'Card',
        'Credit',
        'Advance',
      ].map((text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          textAlign: pw.TextAlign.right,
        ),
      )).toList(),
    );
  }

  pw.TableRow _buildDataRow(Map<String, dynamic> data) {
    return pw.TableRow(
      children: [
        _buildCell(data['location']),
        _buildCell(data['businessType']),
        ...['totalSales', 'cash', 'card', 'credit', 'advance']
            .map((key) => _buildCell(
          NumberFormat('#,##0.00').format(data[key]),
          align: pw.TextAlign.right,
        )),
      ],
    );
  }

  pw.Widget _buildCell(
      String text, {
        pw.TextAlign align = pw.TextAlign.left,
        bool isBold = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : null,
        ),
        textAlign: align,
      ),
    );
  }

  pw.TableRow _buildTotalRow() {
    return pw.TableRow(
      children: [
        _buildCell('Income', isBold: true),
        _buildCell('Grand Total', isBold: true),
        ...['totalSales', 'cash', 'card', 'credit', 'advance'].map((key) {
          final total = filteredData.fold<double>(
            0,
                (sum, item) => sum + (item[key] as double),
          );
          return _buildCell(
            NumberFormat('#,##0.00').format(total),
            align: pw.TextAlign.right,
            isBold: true,
          );
        }),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      children: [
        pw.Text(
          'SKYNET Pro',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          ' Powered By Ceylon Innovation',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _showPDFDialog(List<int> pdfBytes) async {
    final Uint8List uint8List = Uint8List.fromList(pdfBytes);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PDF Preview', style: GoogleFonts.poppins()),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                        ElevatedButton(
                          onPressed: () => _savePDF(pdfBytes),
                          child: Text('Save', style: GoogleFonts.poppins()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  maxPageWidth: 700,
                  build: (format) async => uint8List,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: "sales_report.pdf",
                  previewPageMargin: const EdgeInsets.all(10),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePDF(List<int> pdfBytes) async {
    try {
      Navigator.pop(context);
      String formattedDate = DateFormat('yyyy_MM_dd').format(DateTime.now());

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sales Report',
        fileName: 'sales_report_$formattedDate.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        lockParentWindow: true,
      );

      if (result != null) {
        String filePath = result.endsWith('.pdf') ? result : '$result.pdf';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        _showSuccessMessage('PDF saved successfully to: ${file.path}');
      }
    } catch (e) {
      _showErrorMessage('Failed to save PDF: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}