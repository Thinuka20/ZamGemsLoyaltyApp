import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class SalesSummary {
  final String locationName;
  final double totalIncomeLKR;
  final double cashIncomeLKR;
  final double cardIncomeLKR;
  final double lkr;
  final double usd;
  final double aed;
  final double gbp;
  final double eur;
  final double jpy;
  final double aud;
  final double cad;
  final double chf;
  final double cny;
  final double hkd;
  final double nzd;
  final double sgd;
  final double visaLKR;
  final double masterLKR;
  final double unionPayLKR;
  final double amexLKR;
  final double weChatLKR;

  SalesSummary.fromJson(Map<String, dynamic> json)
      : locationName = json['locationName'] ?? '',
        totalIncomeLKR = (json['totalIncomeLKR'] ?? 0).toDouble(),
        cashIncomeLKR = (json['cashIncomeLKR'] ?? 0).toDouble(),
        cardIncomeLKR = (json['cardIncomeLKR'] ?? 0).toDouble(),
        lkr = (json['lkr'] ?? 0).toDouble(),
        usd = (json['usd'] ?? 0).toDouble(),
        aed = (json['aed'] ?? 0).toDouble(),
        gbp = (json['gbp'] ?? 0).toDouble(),
        eur = (json['eur'] ?? 0).toDouble(),
        jpy = (json['jpy'] ?? 0).toDouble(),
        aud = (json['aud'] ?? 0).toDouble(),
        cad = (json['cad'] ?? 0).toDouble(),
        chf = (json['chf'] ?? 0).toDouble(),
        cny = (json['cny'] ?? 0).toDouble(),
        hkd = (json['hkd'] ?? 0).toDouble(),
        nzd = (json['nzd'] ?? 0).toDouble(),
        sgd = (json['sgd'] ?? 0).toDouble(),
        visaLKR = (json['visaLKR'] ?? 0).toDouble(),
        masterLKR = (json['masterLKR'] ?? 0).toDouble(),
        unionPayLKR = (json['unionPayLKR'] ?? 0).toDouble(),
        amexLKR = (json['amexLKR'] ?? 0).toDouble(),
        weChatLKR = (json['weChatLKR'] ?? 0).toDouble();
}

class SalesReportService {
  final Dio _dio;
  final String baseUrl;

  SalesReportService()
      // : baseUrl = 'https://10.0.2.2:7153/Reports',
      : baseUrl = 'http://124.43.70.220:7072/Reports',
        _dio = Dio() {
    // Configure Dio for development environment
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    // Add logging for debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<List<SalesSummary>> getSalesSummary(
      DateTime startDate, DateTime endDate) async {
    try {
      if (kDebugMode) {
        print('Fetching sales summary for dates: $startDate to $endDate');
      }

      final response = await _dio.get(
        '$baseUrl/salessummary',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SalesSummary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sales summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getSalesSummary: $e');
      }
      throw Exception('Error fetching sales summary: $e');
    }
  }
}

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  SalesReportPageState createState() => SalesReportPageState();
}

class SalesReportPageState extends State<SalesReportPage> {
  final SalesReportService _service = SalesReportService();
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  List<SalesSummary> reportData = [];
  bool showReport = false;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A2359),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2A2359),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showReport = false;
    });

    try {
      final data = await _service.getSalesSummary(fromDate!, toDate!);
      setState(() {
        reportData = data;
        showReport = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generatePDF() async {
    setState(() => isLoading = true);
    try {
      final pdf = pw.Document();
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(image, width: 100),
                    pw.Text(
                      'Sales Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'From: ${DateFormat('yyyy-MM-dd').format(fromDate!)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'To: ${DateFormat('yyyy-MM-dd').format(toDate!)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              _buildPDFTable(),
              pw.Footer(
                leading: pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                trailing: pw.Text(
                  'SKYNET PRO Powered By Ceylon Innovations',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'sales_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  pw.Widget _buildPDFTable() {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: _getHeaders(),
      data: _getPDFData(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignments: Map.fromIterables(
        List<int>.generate(22, (index) => index),
        List<pw.Alignment>.generate(22,
                (index) => index == 0 ? pw.Alignment.centerLeft : pw.Alignment.centerRight),
      ),
    );
  }

  List<String> _getHeaders() {
    return [
      'Location',
      'Total Income (LKR)',
      'Cash Income (LKR)',
      'Card Income (LKR)',
      'LKR',
      'USD',
      'AED',
      'GBP',
      'Euro',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'CNY',
      'HKD',
      'NZD',
      'SGD',
      'Visa (LKR)',
      'Master (LKR)',
      'Union Pay (LKR)',
      'Amex (LKR)',
      'WeChat (LKR)',
    ];
  }

  List<List<String>> _getPDFData() {
    final List<List<String>> data = reportData.map((item) => [
      item.locationName,
      NumberFormat('#,##0.00').format(item.totalIncomeLKR),
      NumberFormat('#,##0.00').format(item.cashIncomeLKR),
      NumberFormat('#,##0.00').format(item.cardIncomeLKR),
      NumberFormat('#,##0.00').format(item.lkr),
      NumberFormat('#,##0.00').format(item.usd),
      NumberFormat('#,##0.00').format(item.aed),
      NumberFormat('#,##0.00').format(item.gbp),
      NumberFormat('#,##0.00').format(item.eur),
      NumberFormat('#,##0.00').format(item.jpy),
      NumberFormat('#,##0.00').format(item.aud),
      NumberFormat('#,##0.00').format(item.cad),
      NumberFormat('#,##0.00').format(item.chf),
      NumberFormat('#,##0.00').format(item.cny),
      NumberFormat('#,##0.00').format(item.hkd),
      NumberFormat('#,##0.00').format(item.nzd),
      NumberFormat('#,##0.00').format(item.sgd),
      NumberFormat('#,##0.00').format(item.visaLKR),
      NumberFormat('#,##0.00').format(item.masterLKR),
      NumberFormat('#,##0.00').format(item.unionPayLKR),
      NumberFormat('#,##0.00').format(item.amexLKR),
      NumberFormat('#,##0.00').format(item.weChatLKR),
    ]).toList();

    // Add totals row
    data.add(_calculateTotalsRow());

    return data;
  }

  List<String> _calculateTotalsRow() {
    double totalIncomeLKR = 0;
    double cashIncomeLKR = 0;
    double cardIncomeLKR = 0;
    double lkr = 0;
    double usd = 0;
    double aed = 0;
    double gbp = 0;
    double eur = 0;
    double jpy = 0;
    double aud = 0;
    double cad = 0;
    double chf = 0;
    double cny = 0;
    double hkd = 0;
    double nzd = 0;
    double sgd = 0;
    double visaLKR = 0;
    double masterLKR = 0;
    double unionPayLKR = 0;
    double amexLKR = 0;
    double weChatLKR = 0;

    for (var item in reportData) {
      totalIncomeLKR += item.totalIncomeLKR;
      cashIncomeLKR += item.cashIncomeLKR;
      cardIncomeLKR += item.cardIncomeLKR;
      lkr += item.lkr;
      usd += item.usd;
      aed += item.aed;
      gbp += item.gbp;
      eur += item.eur;
      jpy += item.jpy;
      aud += item.aud;
      cad += item.cad;
      chf += item.chf;
      cny += item.cny;
      hkd += item.hkd;
      nzd += item.nzd;
      sgd += item.sgd;
      visaLKR += item.visaLKR;
      masterLKR += item.masterLKR;
      unionPayLKR += item.unionPayLKR;
      amexLKR += item.amexLKR;
      weChatLKR += item.weChatLKR;
    }

    return [
    'GRAND TOTAL',
    NumberFormat('#,##0.00').format(totalIncomeLKR),
    NumberFormat('#,##0.00').format(cashIncomeLKR),
    NumberFormat('#,##0.00').format(cardIncomeLKR),
    NumberFormat('#,##0.00').format(lkr),
    NumberFormat('#,##0.00').format(usd),
    NumberFormat('#,##0.00').format(aed),
    NumberFormat('#,##0.00').format(gbp),
    NumberFormat('#,##0.00').format(eur),
    NumberFormat('#,##0.00').format(jpy),
    NumberFormat('#,##0.00').format(aud),
    NumberFormat('#,##0.00').format(cad),
    NumberFormat('#,##0.00').format(chf),
    NumberFormat('#,##0.00').format(cny),
    NumberFormat('#,##0.00').format(hkd),
    NumberFormat('#,##0.00').format(nzd),
    NumberFormat('#,##0.00').format(sgd),
      NumberFormat('#,##0.00').format(visaLKR),
      NumberFormat('#,##0.00').format(masterLKR),
      NumberFormat('#,##0.00').format(unionPayLKR),
      NumberFormat('#,##0.00').format(amexLKR),
      NumberFormat('#,##0.00').format(weChatLKR),
    ];
  }

  List<DataRow> _generateTableRows() {
    final List<DataRow> rows = reportData.map((item) {
      return DataRow(
        cells: [
          DataCell(Text(item.locationName)), // Left-aligned (default)
          // All other cells are center-aligned with fixed width
          ...[ // Using spread operator for the remaining cells
            item.totalIncomeLKR,
            item.cashIncomeLKR,
            item.cardIncomeLKR,
            item.lkr,
            item.usd,
            item.aed,
            item.gbp,
            item.eur,
            item.jpy,
            item.aud,
            item.cad,
            item.chf,
            item.cny,
            item.hkd,
            item.nzd,
            item.sgd,
            item.visaLKR,
            item.masterLKR,
            item.unionPayLKR,
            item.amexLKR,
            item.weChatLKR,
          ].map((value) => DataCell(
            Container(
              alignment: Alignment.centerRight,
              child: Text(
                NumberFormat('#,##0.00').format(value),
              ),
            ),
          )),
        ],
      );
    }).toList();

    // Add total row
    if (reportData.isNotEmpty) {
      rows.add(DataRow(
        cells: _calculateTotalsRow()
            .asMap()
            .map((index, value) => MapEntry(
          index,
          DataCell(
            Container(
              width: index == 0 ? null : 130,
              alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ))
            .values
            .toList(),
      ));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  label: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
            ),
            Text(
              'Sales Report',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 33,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Date',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fromDate != null
                                  ? DateFormat('yyyy-MM-dd').format(fromDate!)
                                  : 'Select Date',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Date',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              toDate != null
                                  ? DateFormat('yyyy-MM-dd').format(toDate!)
                                  : 'Select Date',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                'Generate Report',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (showReport) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _generatePDF,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  'Generate PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 10,
                  columnSpacing: 10,
                  columns: _getHeaders()
                      .map((header) => DataColumn(label: Text(header)))
                      .toList(),
                  rows: _generateTableRows(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}