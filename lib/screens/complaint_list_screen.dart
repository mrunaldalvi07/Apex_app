import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../widgets/complaint_card.dart';
import '../services/complaint_service.dart';
import '../theme/complaint_theme.dart';

class ComplaintListScreen extends StatefulWidget {
  final bool showOnlyMyComplaints;
  final bool isFaculty;

  const ComplaintListScreen({
    super.key,
    this.showOnlyMyComplaints = false,
    required this.isFaculty,
  });

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryFilter() async {
    const categories = [
      'All',
      'Infrastructure',
      'Academic',
      'Hostel',
      'Canteen',
      'Transport',
      'Other',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              const ListTile(
                leading: Icon(Icons.filter_alt_rounded),
                title: Text(
                  'Filter by category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...categories.map(
                (category) => ListTile(
                  leading: Icon(
                    category == 'All'
                        ? Icons.filter_alt_off_rounded
                        : Icons.label_outline_rounded,
                  ),
                  title: Text(category),
                  trailing: category == selectedCategory
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, category),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => selectedCategory = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ComplaintPalette.theme(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ComplaintPalette.white,
          flexibleSpace: const DecoratedBox(
            decoration:
                BoxDecoration(gradient: ComplaintPalette.primaryGradient),
          ),
          title: const Text('Complaints'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          icon: Tooltip(
                            message: 'Pending complaints',
                            child: Icon(Icons.hourglass_top_rounded),
                          ),
                        ),
                        Tab(
                          icon: Tooltip(
                            message: 'Complaints in progress',
                            child: Icon(Icons.autorenew_rounded),
                          ),
                        ),
                        Tab(
                          icon: Tooltip(
                            message: 'Resolved complaints',
                            child: Icon(Icons.task_alt_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: selectedCategory == 'All'
                        ? 'Filter by category'
                        : 'Category: $selectedCategory',
                    onPressed: _showCategoryFilter,
                    icon: Icon(
                      selectedCategory == 'All'
                          ? Icons.tune_rounded
                          : Icons.filter_alt_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration:
              const BoxDecoration(gradient: ComplaintPalette.pageGradient),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
              Expanded(
                child: StreamBuilder<List<Complaint>>(
                  stream: widget.showOnlyMyComplaints
                      ? ComplaintService().getMyComplaintsStream()
                      : ComplaintService().getComplaintsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final complaints = snapshot.data ?? [];

                    final filteredComplaints = complaints.where((complaint) {
                      bool matchesSearch =
                          complaint.title.toLowerCase().contains(searchQuery) ||
                              complaint.complaintId
                                  .toLowerCase()
                                  .contains(searchQuery);

                      bool matchesCategory = selectedCategory == 'All' ||
                          complaint.category == selectedCategory;

                      return matchesSearch && matchesCategory;
                    }).toList();

                    final pendingComplaints = filteredComplaints
                        .where((complaint) => complaint.status == 'Pending')
                        .toList();

                    final inProgressComplaints = filteredComplaints
                        .where((complaint) => complaint.status == 'In Progress')
                        .toList();

                    final resolvedComplaints = filteredComplaints
                        .where((complaint) => complaint.status == 'Resolved')
                        .toList();

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
                            color: ComplaintPalette.skyBlue,
                            child: const Text(
                              'Showing results from all complaint statuses',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: filteredComplaints.isEmpty
                                ? const Center(
                                    child: Text('No complaints found'))
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
                            ? const Center(child: Text('No pending complaints'))
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
                                child: Text('No complaints in progress'))
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
                                child: Text('No resolved complaints'))
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
        ),
      ),
    );
  }
}
