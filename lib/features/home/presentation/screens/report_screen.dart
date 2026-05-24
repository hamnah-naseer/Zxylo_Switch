import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../auth/services/auth_service.dart';

/// Displays the monthly ML energy report fetched directly from Firestore.
/// Path: homes/{homeId}/ml_reports/{YYYY-MM}
class ReportScreen extends StatefulWidget {
  // hfSpaceUrl kept for API compatibility but not used for report display
  final String hfSpaceUrl;

  const ReportScreen({Key? key, required this.hfSpaceUrl}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _report;
  String? _error;
  String _periodLabel = '';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;

    if (homeId == null) {
      setState(() {
        _error = 'Home ID not found. Please log in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();
      final period = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

      // Fetch this month's ML report from Firestore
      final reportDoc = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('ml_reports')
          .doc(period)
          .get();

      if (!reportDoc.exists) {
        // Try the previous month as a fallback
        final prevMonth = DateTime(now.year, now.month - 1);
        final prevPeriod = '${prevMonth.year.toString().padLeft(4, '0')}-${prevMonth.month.toString().padLeft(2, '0')}';
        final prevDoc = await FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .collection('ml_reports')
            .doc(prevPeriod)
            .get();

        if (!prevDoc.exists) {
          setState(() {
            _error = 'No report found for this home yet.\nThe ML report is generated automatically at the end of each month.';
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _report = prevDoc.data();
          _periodLabel = prevDoc.data()?['period_label'] ?? prevPeriod;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _report = reportDoc.data();
        _periodLabel = reportDoc.data()?['period_label'] ?? period;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading report: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text(
          _periodLabel.isNotEmpty ? '$_periodLabel Report' : 'Energy Report',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      )
          : _error != null
          ? _buildErrorWidget()
          : _report == null
          ? const Center(child: Text('No report data available.'))
          : _buildContent(),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined, color: Colors.indigo, size: 60),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Content ──────────────────────────────────────────────────────────

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 20),
          _buildForecastCard(),
          const SizedBox(height: 20),
          _buildRoomBreakdownSection(),
          const SizedBox(height: 20),
          _buildWeeklyBreakdownSection(),
          const SizedBox(height: 20),
          _buildAnomalySection(),
          const SizedBox(height: 20),
          _buildRecommendationsSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Overview Cards ─────────────────────────────────────────────────────────

  Widget _buildOverviewCards() {
    final totalKwh = (_report?['total_kwh'] ?? 0.0) as num;
    final avgDaily = (_report?['avg_daily_kwh'] ?? 0.0) as num;
    final peakDayKwh = (_report?['peak_day_kwh'] ?? 0.0) as num;
    final daysInReport = (_report?['days_in_report'] ?? 0) as num;
    final peakDay = _report?['peak_day'] ?? '';

    // Format peak day nicely e.g. "2026-05-10 00:00:00" → "May 10"
    String peakDayLabel = peakDay;
    try {
      final dt = DateTime.parse(peakDay);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      peakDayLabel = '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _periodLabel,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
            ),
        ),
        Text(
          '$daysInReport days tracked',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Usage', '${totalKwh.toStringAsFixed(1)} kWh', Icons.electric_bolt, Colors.indigo)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Daily Avg', '${avgDaily.toStringAsFixed(1)} kWh', Icons.today, Colors.teal)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Peak Day', peakDayLabel, Icons.trending_up, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Peak Usage', '${peakDayKwh.toStringAsFixed(1)} kWh', Icons.flash_on, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── Forecast Card ─────────────────────────────────────────────────────────

  Widget _buildForecastCard() {
    final nextMonthKwh = (_report?['predicted_next_month_kwh'] ?? 0.0) as num;
    final peakDayKwh = (_report?['predicted_peak_day_kwh'] ?? 0.0) as num;

    return Card(
      elevation: 3,
      shadowColor: Colors.purple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text('ML Predictions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildForecastItem('Next Month', '${nextMonthKwh.toStringAsFixed(1)} kWh', Icons.calendar_month, Colors.purple),
                Container(height: 30, width: 1, color: Colors.grey[200]),
                _buildForecastItem('Peak Day Est.', '${peakDayKwh.toStringAsFixed(1)} kWh', Icons.bolt, Colors.deepOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  // ─── Room Breakdown ─────────────────────────────────────────────────────────

  Widget _buildRoomBreakdownSection() {
    final rooms = _report?['room_breakdown'] as List?;
    if (rooms == null || rooms.isEmpty) return const SizedBox.shrink();

    final List<Color> roomColors = [
      Colors.indigo, Colors.teal, Colors.orange, Colors.purple,
      Colors.green, Colors.red, Colors.blue,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Room Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...rooms.asMap().entries.map((entry) {
          final i = entry.key;
          final room = entry.value as Map<String, dynamic>;
          final label = room['label'] ?? room['room'] ?? 'Room';
          final kwh = (room['kwh'] ?? 0.0) as num;
          final pct = (room['pct'] ?? 0.0) as num;
          final color = roomColors[i % roomColors.length];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.room, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${kwh.toStringAsFixed(2)} kWh', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0).toDouble(),
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Weekly Breakdown ───────────────────────────────────────────────────────

  Widget _buildWeeklyBreakdownSection() {
    final weeks = _report?['weekly_breakdown'] as List?;
    if (weeks == null || weeks.isEmpty) return const SizedBox.shrink();

    // Find max for bar scaling
    final maxKwh = weeks.map((w) => (w['kwh'] ?? 0.0) as num).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weekly Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: weeks.map((week) {
                final label = week['label'] ?? 'Week';
                final kwh = (week['kwh'] ?? 0.0) as num;
                final fraction = maxKwh > 0 ? (kwh / maxKwh).clamp(0.0, 1.0).toDouble() : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: Colors.indigo.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                            minHeight: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${kwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Anomaly Section ────────────────────────────────────────────────────────

  Widget _buildAnomalySection() {
    final anomalyDays = (_report?['anomaly_days'] as List?) ?? [];
    final anomalyCount = (_report?['anomaly_count'] ?? 0) as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Anomalies & Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (anomalyCount == 0)
          Card(
            color: Colors.green[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade100),
            ),
            child: const ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              title: Text(
                'No anomalous days detected this month.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          Card(
            color: Colors.orange[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.shade100),
            ),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              title: Text(
                '$anomalyCount anomalous day(s) detected.',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
              ),
              subtitle: anomalyDays.isNotEmpty
                  ? Text('Dates: ${anomalyDays.join(", ")}', style: TextStyle(color: Colors.orange[800]))
                  : null,
            ),
          ),
      ],
    );
  }

  // ─── Recommendations ────────────────────────────────────────────────────────

  Widget _buildRecommendationsSection() {
    final recs = (_report?['recommendations'] as List?) ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Tips & Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...recs.map((rec) {
          final text = rec.toString();
          Color cardColor = Colors.green[50]!;
          Color borderColor = Colors.green.shade100;
          Color iconColor = Colors.green;
          IconData icon = Icons.lightbulb_outline;

          if (text.startsWith('🔴')) {
            cardColor = Colors.red[50]!;
            borderColor = Colors.red.shade100;
            iconColor = Colors.red;
            icon = Icons.warning_amber_rounded;
          } else if (text.startsWith('🟡')) {
            cardColor = Colors.amber[50]!;
            borderColor = Colors.amber.shade100;
            iconColor = Colors.amber[800]!;
            icon = Icons.info_outline;
          } else if (text.startsWith('📅')) {
            cardColor = Colors.blue[50]!;
            borderColor = Colors.blue.shade100;
            iconColor = Colors.blue;
            icon = Icons.calendar_today;
          } else if (text.startsWith('⚠️')) {
            cardColor = Colors.orange[50]!;
            borderColor = Colors.orange.shade100;
            iconColor = Colors.orange;
            icon = Icons.warning_amber_outlined;
          }

          return Card(
            color: cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(icon, color: iconColor, size: 20),
              title: Text(
                text,
                style: TextStyle(color: iconColor.withOpacity(0.9), fontWeight: FontWeight.w500, fontSize: 11),
              ),
            ),
          );
        }),
      ],
    );
  }
}