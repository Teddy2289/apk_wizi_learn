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
  final double conversionRate;
  final List<ChartDataPoint> chartData;

  StatsData({
    required this.signups,
    required this.activeSessions,
    required this.revenue,
    required this.completedCourses,
    required this.conversionRate,
    required this.chartData,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    // Check if the response is from Laravel (data key) or Node (direct)
    final Map<String, dynamic> responseData = json['data'] ?? json;
    final summary = responseData['summary'] ?? {};
    
    // Handle both camelCase (Node) and snake_case (Laravel)
    final int signups = summary['totalSignups'] ?? summary['total_signups'] ?? 0;
    final int active = summary['activeStudents'] ?? summary['active_students'] ?? 0;
    final double rev = (summary['revenue'] ?? summary['estimated_revenue'] ?? 0).toDouble();
    final int completed = summary['completedCourses'] ?? summary['total_quizzes_taken'] ?? 0;
    final double conversion = (summary['conversionRate'] ?? summary['conversion_rate'] ?? 0).toDouble();

    // Handle both 'chartData' and 'signupTrends' or 'signup_trends'
    final chartDataList = (responseData['chartData'] as List<dynamic>?) ?? 
                        (responseData['signupTrends'] as List<dynamic>?) ?? 
                        (responseData['signup_trends'] as List<dynamic>?) ?? 
                        [];

    return StatsData(
      signups: signups,
      activeSessions: active,
      revenue: rev,
      completedCourses: completed,
      conversionRate: conversion,
      chartData: chartDataList
          .map((item) => ChartDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': {
        'totalSignups': signups,
        'activeStudents': activeSessions,
        'revenue': revenue,
        'completedCourses': completedCourses,
        'conversionRate': conversionRate,
      },
      'chartData': chartData.map((item) => item.toJson()).toList(),
    };
  }
}
