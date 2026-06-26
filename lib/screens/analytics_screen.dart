import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('complaints')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.purple.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.list_alt),
                      title: const Text('Total Complaints'),
                      trailing: Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Card(
                    color: Colors.orange.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions),
                      title: const Text('Pending'),
                      trailing: Text(
                        '$pending',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Card(
                    color: Colors.blue.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.autorenew),
                      title: const Text('In Progress'),
                      trailing: Text(
                        '$inProgress',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Card(
                    color: Colors.green.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle),
                      title: const Text('Resolved'),
                      trailing: Text(
                        '$resolved',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
    );
  }
}