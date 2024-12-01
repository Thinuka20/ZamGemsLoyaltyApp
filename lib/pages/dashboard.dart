import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/salesreport.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Main Menu', // or 'Sales Report' for sales page
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 33,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Skynet Pro Sales Reports Button
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.bar_chart,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    'SKYNET PRO Sales Reports',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Get.to(() => const SalesReportPage());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
