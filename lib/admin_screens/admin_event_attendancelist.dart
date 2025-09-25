import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package

class AdminEventAttendanceList extends StatefulWidget {
  final String image;
  final String date;
  final String title;
  final String location;
  final List<dynamic> attendees;

  const AdminEventAttendanceList({
    Key? key,
    required this.image,
    required this.date,
    required this.title,
    required this.location,
    required this.attendees,
  }) : super(key: key);

  @override
  State<AdminEventAttendanceList> createState() => _AdminEventAttendanceListState();
}

class _AdminEventAttendanceListState extends State<AdminEventAttendanceList> {
  static const int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredAttendees {
    if (_query.isEmpty) return widget.attendees;
    final lower = _query.toLowerCase();
    return widget.attendees.where((a) {
      final name = (a['fullName'] ?? '').toString().toLowerCase();
      final email = (a['email'] ?? '').toString().toLowerCase();
      return name.contains(lower) || email.contains(lower);
    }).toList();
  }

  int get _totalPages {
    final total = _filteredAttendees.length;
    if (total == 0) return 1;
    return (total / _pageSize).ceil();
  }

  List<dynamic> get _pageItems {
    final start = (_currentPage - 1) * _pageSize;
    return _filteredAttendees.skip(start).take(_pageSize).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Parse and format the date
   String formattedDate = '';
try {
  final parsedDate = DateTime.parse(widget.date); // Parse the date string
  formattedDate = DateFormat('MMMM d, y').format(parsedDate); // Format to "Month day, year"
} catch (e) {
  formattedDate = widget.date; // Fallback to the original date if parsing fails
}
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Event Attendance List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      widget.image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search attendees by name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Attendance Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Total',
                            widget.attendees.length.toString(),
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Attended',
                            widget.attendees.where((a) => a['attended'] == true).length.toString(),
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Absent',
                            widget.attendees.where((a) => a['attended'] != true).length.toString(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Attendees List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendees List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        itemCount: _pageItems.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final attendee = _pageItems[index];
                          final attendeeName = attendee['fullName'] ?? 'Unknown';
                          final isAttended = attendee['attended'] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[200]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        child: Text(
                                          '${((_currentPage - 1) * _pageSize) + index + 1}',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          attendeeName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAttended ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isAttended ? 'Attended' : 'Not Attended',
                                    style: TextStyle(
                                      color: isAttended ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Pagination controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ' + _currentPage.toString() + ' of ' + _totalPages.toString() + ' • Total: ' + _filteredAttendees.length.toString(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() {
                                          _currentPage -= 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Prev'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                        setState(() {
                                          _currentPage += 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                                label: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}