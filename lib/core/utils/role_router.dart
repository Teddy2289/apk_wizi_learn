import 'package:wizi_learn/core/constants/route_constants.dart';

/// Utility class to centralize role-based routing logic.
/// This ensures consistency across login and splash pages.
class RoleRouter {
  /// Determines the appropriate route based on user role.
  /// 
  /// - Formateur/Formatrice → Formateur Dashboard
  /// - Commercial/Commerciale → Commercial Dashboard  
  /// - Stagiaire or default → Stagiaire Dashboard
  static String getRouteForRole(String? role) {
    final lowerRole = role?.toLowerCase() ?? '';
    
    // Formateurs (masculin et féminin)
    if (lowerRole == 'formateur' || lowerRole == 'formatrice') {
      return RouteConstants.formateurDashboard;
    }
    
    // Commerciaux (masculin et féminin)
    if (lowerRole == 'commercial' || lowerRole == 'commerciale') {
      return RouteConstants.commercialDashboard;
    }
    
    // Admin - redirect to commercial dashboard for now
    if (lowerRole == 'admin') {
      return RouteConstants.commercialDashboard;
    }
    
    // Stagiaire ou par défaut
    return RouteConstants.dashboard;
  }
}
