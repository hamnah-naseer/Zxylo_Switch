import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class EnergyConsumptionScreen extends StatefulWidget {
  const EnergyConsumptionScreen({super.key});

  @override
  State<EnergyConsumptionScreen> createState() => _EnergyConsumptionScreenState();
}

class _EnergyConsumptionScreenState extends State<EnergyConsumptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  // Real-time values
  double _todayEnergy = 0.0;
  double _weekEnergy = 0.0;
  double _monthEnergy = 0.0;
  Map<String, double> _dailyHistory = {
    'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0, 'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0
  };

  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _historySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    
    // Start listening to Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startEnergyListeners();
    });
  }

  void _startEnergyListeners() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;
    if (homeId == null) return;

    final firestore = FirebaseFirestore.instance;

    // 1. Listen to Realtime Totals
    _realtimeSubscription = firestore
        .collection('homes')
        .doc(homeId)
        .collection('energy_stats')
        .doc('realtime')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _todayEnergy = (data['today'] ?? 0.0).toDouble();
          _weekEnergy = (data['week'] ?? 0.0).toDouble();
          _monthEnergy = (data['month'] ?? 0.0).toDouble();
        });
      }
    });

    // 2. Listen to Daily Consumption for Charts (Last 7 Days)
    _historySubscription = firestore
        .collection('homes')
        .doc(homeId)
        .collection('daily_consumption')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Always generate the last 7 days up to today to ensure correct chronological order on X-axis
        final Map<String, double> last7Days = {};
        for (int i = 6; i >= 0; i--) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dayName = DateFormat('E').format(date);
          last7Days[dayName] = 0.0; // Default to 0.0
        }
        
        final List<QueryDocumentSnapshot> sortedDocs = snapshot.docs.reversed.toList();
        
        for (var doc in sortedDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            final dayName = DateFormat('E').format(date);
            // If the document falls within our 7-day window, update its value
            if (last7Days.containsKey(dayName)) {
               last7Days[dayName] = (data['total'] ?? 0.0).toDouble();
            }
          }
        }

        setState(() {
          _dailyHistory = last7Days;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0ABAB5), // Tiffany Blue
                  Color(0xFF0095B6), // Bondi Blue
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const DashboardScreen()), 
                    (route) => false,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Energy Consumption',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.bolt, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Summary Cards
                  _buildSummaryCards(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedTabIndex == 0 ? 'Line Chart View' : 'Bar Graph View',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
                        ),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF757575),
                      labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Trends'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),

                  // Tab Content
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLineChart(),
                        _buildBarGraph(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Today',
                value: '${_todayEnergy.toStringAsFixed(1)} kWh',
                icon: Icons.today,
                color: const Color(0xFF0095B6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                title: 'Week',
                value: '${_weekEnergy.toStringAsFixed(1)} kWh',
                icon: Icons.calendar_view_week,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                title: 'Month',
                value: '${_monthEnergy.toStringAsFixed(1)} kWh',
                icon: Icons.calendar_month,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3BCFB6).withValues(alpha: 0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6FDFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3BCFB6).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3BCFB6).withValues(alpha: 0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6FDFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3BCFB6).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trend',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha :0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha :0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final days = _dailyHistory.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha :0.3)),
                ),
                minX: 0,
                maxX: (_dailyHistory.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY() + 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyHistory.values.toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF0095B6),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0095B6).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_dailyHistory.isEmpty) return 10.0;
    double max = 5.0;
    for (var v in _dailyHistory.values) {
      if (v > max) max = v;
    }
    return max;
  }

  Widget _buildBarGraph() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3BCFB6).withValues(alpha: 0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6FDFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3BCFB6).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Usage',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY() + 1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = _dailyHistory.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                barGroups: _dailyHistory.values.toList().asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: const Color(0xFF0095B6),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Energy Used (kWh)', const Color(0xFF0095B6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
