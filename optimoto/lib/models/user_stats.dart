import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD: Import for Timestamp

class UserStats {
  final int wishlistCount;
  final int viewedVehiclesCount;
  final int comparedVehiclesCount;
  final int searchesCount;
  final DateTime? lastUpdated;

  const UserStats({
    required this.wishlistCount,
    required this.viewedVehiclesCount,
    required this.comparedVehiclesCount,
    required this.searchesCount,
    this.lastUpdated,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      wishlistCount: json['wishlistCount'] as int? ?? 0,
      viewedVehiclesCount: json['viewedVehiclesCount'] as int? ?? 0,
      comparedVehiclesCount: json['comparedVehiclesCount'] as int? ?? 0,
      searchesCount: json['searchesCount'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserStats.empty() {
    return const UserStats(
      wishlistCount: 0,
      viewedVehiclesCount: 0,
      comparedVehiclesCount: 0,
      searchesCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wishlistCount': wishlistCount,
      'viewedVehiclesCount': viewedVehiclesCount,
      'comparedVehiclesCount': comparedVehiclesCount,
      'searchesCount': searchesCount,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  UserStats copyWith({
    int? wishlistCount,
    int? viewedVehiclesCount,
    int? comparedVehiclesCount,
    int? searchesCount,
    DateTime? lastUpdated,
  }) {
    return UserStats(
      wishlistCount: wishlistCount ?? this.wishlistCount,
      viewedVehiclesCount: viewedVehiclesCount ?? this.viewedVehiclesCount,
      comparedVehiclesCount:
          comparedVehiclesCount ?? this.comparedVehiclesCount,
      searchesCount: searchesCount ?? this.searchesCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'UserStats(wishlist: $wishlistCount, viewed: $viewedVehiclesCount, compared: $comparedVehiclesCount, searches: $searchesCount)';
  }
}
