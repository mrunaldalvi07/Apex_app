import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  // Used only for search filtering.
  // This avoids rebuilding the whole StreamBuilder while typing.
  final ValueNotifier<String> _searchTextNotifier =
      ValueNotifier<String>("");

  String _selectedFilter = "ALL";

  // Classroom UI Colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Color(0xFFF5F0EB);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          "Classroom Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,
      ),

      // Allows the body to resize when the keyboard opens.
      resizeToAvoidBottomInset: true,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classrooms')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading classrooms",
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryNavy,
              ),
            );
          }

          final classrooms = snapshot.data?.docs ?? [];

          if (classrooms.isEmpty) {
            return const Center(
              child: Text(
                "No classrooms found",
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          // --------------------------------------------------
          // COUNT CLASSROOMS
          // --------------------------------------------------

          int freeCount = 0;
          int temporaryCount = 0;
          int bookedCount = 0;

          for (final doc in classrooms) {
            final data =
                doc.data() as Map<String, dynamic>;

            final status =
                data['status']
                        ?.toString()
                        .toUpperCase() ??
                    "";

            if (status == "FREE") {
              freeCount++;
            } else if (status ==
                "TEMPORARILY RESERVED") {
              temporaryCount++;
            } else if (status == "BOOKED") {
              bookedCount++;
            }
          }

          // --------------------------------------------------
          // RESPONSIVE LAYOUT
          // --------------------------------------------------

          return LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),

                  // IMPORTANT:
                  // The complete classroom screen scrolls.
                  // This prevents bottom overflow when the
                  // mobile keyboard is visible.
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,

                    padding: const EdgeInsets.only(
                      bottom: 20,
                    ),

                    child: Column(
                      children: [

                        // --------------------------------------------------
                        // BLUE GRADIENT HEADER
                        // --------------------------------------------------

                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            12,
                            12,
                            12,
                            6,
                          ),

                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(18),

                            decoration: BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  darkNavy,
                                  primaryNavy,
                                ],
                                begin:
                                    Alignment.centerLeft,
                                end:
                                    Alignment.centerRight,
                              ),

                              borderRadius:
                                  BorderRadius.circular(17),
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  "Classroom Overview",

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  "$freeCount Free  •  "
                                  "$temporaryCount Temporary  •  "
                                  "$bookedCount Booked",

                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --------------------------------------------------
                        // STATUS CARDS
                        // --------------------------------------------------

                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            12,
                            6,
                            12,
                            6,
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: _countCard(
                                  title: "FREE",
                                  count: freeCount,
                                  color: Colors.green,
                                  icon:
                                      Icons.check_circle,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: _countCard(
                                  title: "TEMPORARY",
                                  count: temporaryCount,
                                  color: Colors.orange,
                                  icon:
                                      Icons.access_time,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: _countCard(
                                  title: "BOOKED",
                                  count: bookedCount,
                                  color: Colors.red,
                                  icon:
                                      Icons.event_busy,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------------------
                        // SEARCH
                        // --------------------------------------------------

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          child: TextField(
                            controller:
                                _searchController,

                            focusNode:
                                _searchFocusNode,

                            // IMPORTANT:
                            // No setState here.
                            // This keeps the search input stable
                            // while typing.
                            onChanged: (value) {
                              _searchTextNotifier.value =
                                  value;
                            },

                            decoration:
                                InputDecoration(
                              hintText:
                                  "Search classroom number",

                              prefixIcon:
                                  const Icon(
                                Icons.search,
                                color: darkNavy,
                              ),

                              suffixIcon:
                                  ValueListenableBuilder<
                                      String>(
                                valueListenable:
                                    _searchTextNotifier,

                                builder: (
                                  context,
                                  searchText,
                                  child,
                                ) {
                                  if (searchText.isEmpty) {
                                    return const SizedBox
                                        .shrink();
                                  }

                                  return IconButton(
                                    icon:
                                        const Icon(
                                      Icons.clear,
                                      color: darkNavy,
                                    ),

                                    onPressed: () {
                                      _searchController
                                          .clear();

                                      _searchTextNotifier
                                          .value = "";

                                      // Keep search field active.
                                      _searchFocusNode
                                          .requestFocus();
                                    },
                                  );
                                },
                              ),

                              filled: true,
                              fillColor: Colors.white,

                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    BorderSide.none,
                              ),

                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    BorderSide.none,
                              ),

                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color: primaryNavy,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // --------------------------------------------------
                        // FILTER BUTTONS
                        // --------------------------------------------------

                        SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),

                          child: Row(
                            children: [
                              _filterButton("ALL"),

                              const SizedBox(width: 8),

                              _filterButton("FREE"),

                              const SizedBox(width: 8),

                              _filterButton(
                                "TEMPORARILY RESERVED",
                              ),

                              const SizedBox(width: 8),

                              _filterButton("BOOKED"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // --------------------------------------------------
                        // CLASSROOM LIST
                        // --------------------------------------------------

                        ValueListenableBuilder<String>(
                          valueListenable:
                              _searchTextNotifier,

                          builder: (
                            context,
                            searchText,
                            child,
                          ) {
                            final search = searchText
                                .trim()
                                .toLowerCase();

                            final filteredClassrooms =
                                classrooms.where((doc) {
                              final data =
                                  doc.data()
                                      as Map<String,
                                          dynamic>;

                              final roomNo =
                                  data['roomNo']
                                          ?.toString()
                                          .toLowerCase() ??
                                      "";

                              final status =
                                  data['status']
                                          ?.toString()
                                          .toUpperCase() ??
                                      "";

                              final matchesSearch =
                                  roomNo.contains(search);

                              bool matchesFilter = true;

                              if (_selectedFilter ==
                                  "FREE") {
                                matchesFilter =
                                    status == "FREE";
                              } else if (_selectedFilter ==
                                  "TEMPORARILY RESERVED") {
                                matchesFilter =
                                    status ==
                                        "TEMPORARILY RESERVED";
                              } else if (_selectedFilter ==
                                  "BOOKED") {
                                matchesFilter =
                                    status == "BOOKED";
                              }

                              return matchesSearch &&
                                  matchesFilter;
                            }).toList();

                            if (filteredClassrooms
                                .isEmpty) {
                              return const Padding(
                                padding:
                                    EdgeInsets.all(30),

                                child: Center(
                                  child: Text(
                                    "No classrooms match your search/filter",

                                    textAlign:
                                        TextAlign.center,

                                    style: TextStyle(
                                      color: darkNavy,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // IMPORTANT:
                            // The outer SingleChildScrollView
                            // handles scrolling.
                            //
                            // This ListView only calculates its
                            // required height and does NOT scroll
                            // independently.
                            return ListView.builder(
                              shrinkWrap: true,

                              physics:
                                  const NeverScrollableScrollPhysics(),

                              itemCount:
                                  filteredClassrooms.length,

                              itemBuilder:
                                  (context, index) {
                                final classroom =
                                    filteredClassrooms[
                                            index]
                                        .data()
                                        as Map<String,
                                            dynamic>;

                                final roomNo =
                                    classroom['roomNo']
                                            ?.toString() ??
                                        "N/A";

                                final status =
                                    classroom['status']
                                            ?.toString()
                                            .toUpperCase() ??
                                        "UNKNOWN";

                                final course =
                                    classroom['course']
                                            ?.toString() ??
                                        "";

                                // --------------------------------------------------
                                // STATUS COLORS
                                // --------------------------------------------------

                                Color statusColor;
                                IconData statusIcon;

                                if (status == "FREE") {
                                  statusColor =
                                      Colors.green;
                                  statusIcon =
                                      Icons.check_circle;
                                } else if (status ==
                                    "TEMPORARILY RESERVED") {
                                  statusColor =
                                      Colors.orange;
                                  statusIcon =
                                      Icons.access_time;
                                } else if (status ==
                                    "BOOKED") {
                                  statusColor =
                                      Colors.red;
                                  statusIcon =
                                      Icons.event_busy;
                                } else {
                                  statusColor =
                                      primaryNavy;
                                  statusIcon =
                                      Icons.help_outline;
                                }

                                // --------------------------------------------------
                                // CLASSROOM CARD
                                // --------------------------------------------------

                                return Card(
                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),

                                  elevation: 2,

                                  color: Colors.white,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(17),
                                  ),

                                  child: Padding(
                                    padding:
                                        const EdgeInsets
                                            .all(14),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        // --------------------------------------------------
                                        // ROOM HEADER
                                        // --------------------------------------------------

                                        Container(
                                          width:
                                              double.infinity,

                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical: 15,
                                          ),

                                          decoration:
                                              BoxDecoration(
                                            color:
                                                statusColor,

                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              12,
                                            ),
                                          ),

                                          child: Text(
                                            "ROOM $roomNo",

                                            textAlign:
                                                TextAlign
                                                    .center,

                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize: 21,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 12,
                                        ),

                                        if (course.isNotEmpty)
                                          Text(
                                            "Course: $course",

                                            style:
                                                const TextStyle(
                                              fontSize: 16,
                                              color: darkNavy,
                                              fontWeight:
                                                  FontWeight
                                                      .w500,
                                            ),
                                          ),

                                        if (course.isNotEmpty)
                                          const SizedBox(
                                            height: 7,
                                          ),

                                        // --------------------------------------------------
                                        // STATUS
                                        // --------------------------------------------------

                                        Row(
                                          children: [
                                            Icon(
                                              statusIcon,
                                              color:
                                                  statusColor,
                                              size: 20,
                                            ),

                                            const SizedBox(
                                              width: 7,
                                            ),

                                            Expanded(
                                              child: Text(
                                                "Status: $status",

                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      15,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                  color:
                                                      statusColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // COUNT CARD
  // --------------------------------------------------

  Widget _countCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: color,
            size: 24,
          ),

          const SizedBox(height: 4),

          Text(
            "$count",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FILTER BUTTON
  // --------------------------------------------------

  Widget _filterButton(String filter) {
    final isSelected =
        _selectedFilter == filter;

    String displayText;

    if (filter == "ALL") {
      displayText = "All";
    } else if (filter == "FREE") {
      displayText = "Free";
    } else if (filter ==
        "TEMPORARILY RESERVED") {
      displayText = "Temporary Reserved";
    } else {
      displayText = "Booked";
    }

    return ChoiceChip(
      label: Text(displayText),

      selected: isSelected,

      selectedColor: primaryNavy,

      backgroundColor: Colors.white,

      side: BorderSide(
        color: isSelected
            ? primaryNavy
            : Colors.grey.shade300,
      ),

      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : darkNavy,
        fontWeight: FontWeight.w600,
      ),

      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }
}