import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class EnergyConsumptionScreen extends StatefulWidget {
  const EnergyConsumptionScreen({super.key});

  @override
  State<EnergyConsumptionScreen> createState() => _EnergyConsumptionScreenState();
}

class _EnergyConsumptionScreenState extends State<EnergyConsumptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Sample data for energy consumption
  final List<Map<String, dynamic>> _energyData = [
    {'hour': '00:00', 'monday': 2.1, 'tuesday': 1.8, 'wednesday': 2.3, 'thursday': 1.9, 'friday': 2.0, 'saturday': 1.7, 'sunday': 1.6},
    {'hour': '01:00', 'monday': 1.5, 'tuesday': 1.4, 'wednesday': 1.6, 'thursday': 1.3, 'friday': 1.5, 'saturday': 1.2, 'sunday': 1.1},
    {'hour': '02:00', 'monday': 1.2, 'tuesday': 1.1, 'wednesday': 1.3, 'thursday': 1.0, 'friday': 1.2, 'saturday': 0.9, 'sunday': 0.8},
    {'hour': '03:00', 'monday': 1.0, 'tuesday': 0.9, 'wednesday': 1.1, 'thursday': 0.8, 'friday': 1.0, 'saturday': 0.7, 'sunday': 0.6},
    {'hour': '04:00', 'monday': 0.8, 'tuesday': 0.7, 'wednesday': 0.9, 'thursday': 0.6, 'friday': 0.8, 'saturday': 0.5, 'sunday': 0.4},
    {'hour': '05:00', 'monday': 1.2, 'tuesday': 1.1, 'wednesday': 1.3, 'thursday': 1.0, 'friday': 1.2, 'saturday': 0.9, 'sunday': 0.8},
    {'hour': '06:00', 'monday': 2.5, 'tuesday': 2.3, 'wednesday': 2.7, 'thursday': 2.2, 'friday': 2.4, 'saturday': 2.0, 'sunday': 1.9},
    {'hour': '07:00', 'monday': 4.2, 'tuesday': 4.0, 'wednesday': 4.5, 'thursday': 3.8, 'friday': 4.1, 'saturday': 3.5, 'sunday': 3.3},
    {'hour': '08:00', 'monday': 5.8, 'tuesday': 5.5, 'wednesday': 6.0, 'thursday': 5.2, 'friday': 5.7, 'saturday': 4.8, 'sunday': 4.6},
    {'hour': '09:00', 'monday': 6.5, 'tuesday': 6.2, 'wednesday': 6.8, 'thursday': 5.9, 'friday': 6.4, 'saturday': 5.5, 'sunday': 5.3},
    {'hour': '10:00', 'monday': 7.2, 'tuesday': 6.9, 'wednesday': 7.5, 'thursday': 6.6, 'friday': 7.1, 'saturday': 6.2, 'sunday': 6.0},
    {'hour': '11:00', 'monday': 7.8, 'tuesday': 7.5, 'wednesday': 8.1, 'thursday': 7.2, 'friday': 7.7, 'saturday': 6.8, 'sunday': 6.6},
    {'hour': '12:00', 'monday': 8.5, 'tuesday': 8.2, 'wednesday': 8.8, 'thursday': 7.9, 'friday': 8.4, 'saturday': 7.5, 'sunday': 7.3},
    {'hour': '13:00', 'monday': 8.2, 'tuesday': 7.9, 'wednesday': 8.5, 'thursday': 7.6, 'friday': 8.1, 'saturday': 7.2, 'sunday': 7.0},
    {'hour': '14:00', 'monday': 7.8, 'tuesday': 7.5, 'wednesday': 8.1, 'thursday': 7.2, 'friday': 7.7, 'saturday': 6.8, 'sunday': 6.6},
    {'hour': '15:00', 'monday': 7.5, 'tuesday': 7.2, 'wednesday': 7.8, 'thursday': 6.9, 'friday': 7.4, 'saturday': 6.5, 'sunday': 6.3},
    {'hour': '16:00', 'monday': 8.1, 'tuesday': 7.8, 'wednesday': 8.4, 'thursday': 7.5, 'friday': 8.0, 'saturday': 7.1, 'sunday': 6.9},
    {'hour': '17:00', 'monday': 8.8, 'tuesday': 8.5, 'wednesday': 9.1, 'thursday': 8.2, 'friday': 8.7, 'saturday': 7.8, 'sunday': 7.6},
    {'hour': '18:00', 'monday': 9.5, 'tuesday': 9.2, 'wednesday': 9.8, 'thursday': 8.9, 'friday': 9.4, 'saturday': 8.5, 'sunday': 8.3},
    {'hour': '19:00', 'monday': 9.2, 'tuesday': 8.9, 'wednesday': 9.5, 'thursday': 8.6, 'friday': 9.1, 'saturday': 8.2, 'sunday': 8.0},
    {'hour': '20:00', 'monday': 8.8, 'tuesday': 8.5, 'wednesday': 9.1, 'thursday': 8.2, 'friday': 8.7, 'saturday': 7.8, 'sunday': 7.6},
    {'hour': '21:00', 'monday': 7.5, 'tuesday': 7.2, 'wednesday': 7.8, 'thursday': 6.9, 'friday': 7.4, 'saturday': 6.5, 'sunday': 6.3},
    {'hour': '22:00', 'monday': 6.2, 'tuesday': 5.9, 'wednesday': 6.5, 'thursday': 5.6, 'friday': 6.1, 'saturday': 5.2, 'sunday': 5.0},
    {'hour': '23:00', 'monday': 4.8, 'tuesday': 4.5, 'wednesday': 5.1, 'thursday': 4.2, 'friday': 4.7, 'saturday': 3.8, 'sunday': 3.6},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Energy Consumption',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
    body: Container(
       decoration: const BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: [
                 Colors.white,
                 Color(0xFF20B2AA),
                 Color(0xFF483D8B),
              ],
              stops: [0.0, 0.3, 1.0],
          ),
        ),
      child: SafeArea(
        child: Column(
          children: [
            // Summary Cards
            _buildSummaryCards(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                _selectedTabIndex == 0 ? '📈 Line Chart View' : '📊 Bar Graph View',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            // Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF4CAF50),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Line Chart'),
                  Tab(text: 'Bar Graph'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLineChart(),
                  _buildBarGraph(),
                ],
              ),
            ),
          ],
        ),
      ),
     ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Today',
              value: '45.2 kWh',
              icon: Icons.today,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'This Week',
              value: '312.8 kWh',
              icon: Icons.calendar_view_week,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'This Month',
              value: '1,245.6 kWh',
              icon: Icons.calendar_month,
              color: const Color(0xFFFF9800),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha :0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha :0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Energy Consumption Trend',
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
                  verticalInterval: 4,
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
                  rightTitles:  AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _energyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _energyData[value.toInt()]['hour'],
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
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} kWh',
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
                maxX: (_energyData.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  // Monday line
                  LineChartBarData(
                    spots: _energyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['monday']);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF4CAF50),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData:  FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4CAF50).withValues(alpha :0.1),
                    ),
                  ),
                  // Tuesday line
                  LineChartBarData(
                    spots: _energyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['tuesday']);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF2196F3),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData:  FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2196F3).withValues(alpha :0.1),
                    ),
                  ),
                  // Wednesday line
                  LineChartBarData(
                    spots: _energyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['wednesday']);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFFFF9800),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData:  FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF9800).withValues(alpha :0.1),
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

  Widget _buildBarGraph() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha :0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Energy Consumption by Hour',
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
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:  AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles:  AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _energyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _energyData[value.toInt()]['hour'],
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
                      interval: 4,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} kWh',
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
                barGroups: _energyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['monday'],
                        color: const Color(0xFF4CAF50),
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: entry.value['tuesday'],
                        color: const Color(0xFF2196F3),
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: entry.value['wednesday'],
                        color: const Color(0xFFFF9800),
                        width: 8,
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
                      color: Colors.grey.withValues(alpha :0.3),
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
        _buildLegendItem('Monday', const Color(0xFF4CAF50)),
        const SizedBox(width: 16),
        _buildLegendItem('Tuesday', const Color(0xFF2196F3)),
        const SizedBox(width: 16),
        _buildLegendItem('Wednesday', const Color(0xFFFF9800)),
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
