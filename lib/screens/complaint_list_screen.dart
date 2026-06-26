import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../widgets/complaint_card.dart';
import '../services/complaint_service.dart';

class ComplaintListScreen extends StatefulWidget {
  final bool showOnlyMyComplaints;
  final bool isFaculty;

  const ComplaintListScreen({
    super.key,
    this.showOnlyMyComplaints = false,
    required this.isFaculty,
  });

  @override
  State<ComplaintListScreen> createState() =>
      _ComplaintListScreenState();
}

class _ComplaintListScreenState
    extends State<ComplaintListScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by title or ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: 'Infrastructure',
                  child: Text('Infrastructure'),
                ),
                DropdownMenuItem(
                  value: 'Academic',
                  child: Text('Academic'),
                ),
                DropdownMenuItem(
                  value: 'Hostel',
                  child: Text('Hostel'),
                ),
                DropdownMenuItem(
                  value: 'Canteen',
                  child: Text('Canteen'),
                ),
                DropdownMenuItem(
                  value: 'Transport',
                  child: Text('Transport'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Complaint>>(
                  stream: widget.showOnlyMyComplaints
                  ? ComplaintService().getMyComplaintsStream()
                  : ComplaintService().getComplaintsStream(),
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

                final complaints = snapshot.data ?? [];

                final filteredComplaints =
                    complaints.where((complaint) {
                  bool matchesSearch =
                      complaint.title
                              .toLowerCase()
                              .contains(searchQuery) ||
                          complaint.complaintId
                              .toLowerCase()
                              .contains(searchQuery);

                  bool matchesCategory =
                      selectedCategory == 'All' ||
                          complaint.category ==
                              selectedCategory;

                  return matchesSearch &&
                      matchesCategory;
                }).toList();

                final pendingComplaints =
                    filteredComplaints.where(
                  (complaint) =>
                      complaint.status == 'Pending',
                ).toList();

                final inProgressComplaints =
                    filteredComplaints.where(
                  (complaint) =>
                      complaint.status == 'In Progress',
                ).toList();

                final resolvedComplaints =
                    filteredComplaints.where(
                  (complaint) =>
                      complaint.status == 'Resolved',
                ).toList();


                pendingComplaints.sort(
                  (a, b) => a.createdAt.compareTo(b.createdAt),
                );

                inProgressComplaints.sort(
                  (a, b) => a.createdAt.compareTo(b.createdAt),
                );

                resolvedComplaints.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );


                if (searchQuery.isNotEmpty) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        color: Colors.blue.shade50,
                        child: const Text(
                          'Showing results from all complaint statuses',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      Expanded(
                        child: filteredComplaints.isEmpty
                            ? const Center(
                                child: Text(
                                  'No complaints found',
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredComplaints.length,
                                itemBuilder: (context, index) {
                                  return ComplaintCard(
                                    complaint: filteredComplaints[index],
                                    isFaculty: widget.isFaculty,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }

                return TabBarView(
                  controller: tabController,
                  children: [
                    // Pending
                    pendingComplaints.isEmpty
                        ? const Center(
                            child: Text(
                              'No pending complaints',
                            ),
                          )
                        : ListView.builder(
                            itemCount: pendingComplaints.length,
                            itemBuilder: (context, index) {
                              return ComplaintCard(
                                complaint: pendingComplaints[index],
                                isFaculty: widget.isFaculty,
                              );
                            },
                          ),

                    // In Progress
                    inProgressComplaints.isEmpty
                        ? const Center(
                            child: Text(
                              'No complaints in progress',
                            ),
                          )
                        : ListView.builder(
                            itemCount: inProgressComplaints.length,
                            itemBuilder: (context, index) {
                              return ComplaintCard(
                                complaint: inProgressComplaints[index],
                                isFaculty: widget.isFaculty,
                              );
                            },
                          ),

                    // Resolved
                    resolvedComplaints.isEmpty
                        ? const Center(
                            child: Text(
                              'No resolved complaints',
                            ),
                          )
                        : ListView.builder(
                            itemCount: resolvedComplaints.length,
                            itemBuilder: (context, index) {
                              return ComplaintCard(
                                complaint: resolvedComplaints[index],
                                isFaculty: widget.isFaculty,
                              );
                            },
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}