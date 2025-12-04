class ChartDataPoint {
  final String date;
  final double value;

  ChartDataPoint({
    required this.date,
    required this.value,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
    };
  }
}

class StatsData {
  final int signups;
  final int activeSessions;
  final double revenue;
  final int completedCourses;
  final List<ChartDataPoint> chartData;

  StatsData({
    required this.signups,
    required this.activeSessions,
    required this.revenue,
    required this.completedCourses,
    required this.chartData,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    final chartDataList = (json['chartData'] as List<dynamic>?) ?? [];

    return StatsData(
      signups: summary['signups'] ?? 0,
      activeSessions: summary['activeSessions'] ?? 0,
      revenue: (summary['revenue'] ?? 0).toDouble(),
      completedCourses: summary['completedCourses'] ?? 0,
      chartData: chartDataList
          .map((item) => ChartDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': {
        'signups': signups,
        'activeSessions': activeSessions,
        'revenue': revenue,
        'completedCourses': completedCourses,
      },
      'chartData': chartData.map((item) => item.toJson()).toList(),
    };
  }
}
