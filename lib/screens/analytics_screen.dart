import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/complaint_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ComplaintPalette.darkNavy,
        foregroundColor: ComplaintPalette.white,
        iconTheme: const IconThemeData(color: ComplaintPalette.white),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: ComplaintPalette.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration:
            const BoxDecoration(gradient: ComplaintPalette.pageGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('complaints').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('No data found'),
              );
            }

            final complaints = snapshot.data!.docs;

            int total = complaints.length;

            int pending = 0;
            int inProgress = 0;
            int resolved = 0;

            int infrastructure = 0;
            int academic = 0;
            int hostel = 0;
            int canteen = 0;
            int transport = 0;
            int other = 0;

            for (var doc in complaints) {
              final data = doc.data() as Map<String, dynamic>;

              final status = data['status'] ?? '';
              final category = data['category'] ?? 'Other';

              switch (status) {
                case 'Pending':
                  pending++;
                  break;
                case 'In Progress':
                  inProgress++;
                  break;
                case 'Resolved':
                  resolved++;
                  break;
              }

              switch (category) {
                case 'Infrastructure':
                  infrastructure++;
                  break;
                case 'Academic':
                  academic++;
                  break;
                case 'Hostel':
                  hostel++;
                  break;
                case 'Canteen':
                  canteen++;
                  break;
                case 'Transport':
                  transport++;
                  break;
                default:
                  other++;
              }
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.purple.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.list_alt,
                            color: Color(0xFF542B7E)),
                        title: const Text('Total Complaints',
                            style: TextStyle(
                                color: Color(0xFF321A4D),
                                fontWeight: FontWeight.w700)),
                        trailing: Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF321A4D),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.orange.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.pending_actions,
                            color: Color(0xFF9A5200)),
                        title: const Text('Pending',
                            style: TextStyle(
                                color: Color(0xFF603000),
                                fontWeight: FontWeight.w700)),
                        trailing: Text(
                          '$pending',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF603000),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.blue.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.autorenew,
                            color: Color(0xFF075C9A)),
                        title: const Text('In Progress',
                            style: TextStyle(
                                color: Color(0xFF053C65),
                                fontWeight: FontWeight.w700)),
                        trailing: Text(
                          '$inProgress',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF053C65),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.green.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Color(0xFF137B44)),
                        title: const Text('Resolved',
                            style: TextStyle(
                                color: Color(0xFF0B4D2A),
                                fontWeight: FontWeight.w700)),
                        trailing: Text(
                          '$resolved',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B4D2A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Category Breakdown',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        title: const Text('Infrastructure'),
                        trailing: Text('$infrastructure'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Academic'),
                        trailing: Text('$academic'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Hostel'),
                        trailing: Text('$hostel'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Canteen'),
                        trailing: Text('$canteen'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Transport'),
                        trailing: Text('$transport'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Other'),
                        trailing: Text('$other'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
