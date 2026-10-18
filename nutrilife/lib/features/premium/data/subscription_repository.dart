import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

/// Plan del usuario según el backend, después de leer RevenueCat.
class SubscriptionState {
  const SubscriptionState({required this.plan, this.proUntil, this.proSource});

  factory SubscriptionState.fromJson(Map<String, dynamic> json) => SubscriptionState(
        plan: json['plan']?.toString() ?? 'FREE',
        proUntil: DateTime.tryParse(json['proUntil']?.toString() ?? '')?.toLocal(),
        proSource: json['proSource']?.toString(),
      );

  final String plan;
  final DateTime? proUntil;
  final String? proSource;
}

/// El backend no pudo confirmar la compra todavía. El webhook la arregla.
class SubscriptionSyncException implements Exception {
  const SubscriptionSyncException();
}

class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<SubscriptionState> sync() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiRoutes.subscriptionSync);
      final body = response.data;
      final data = body?['data'];
      if (body?['success'] == true && data is Map) {
        return SubscriptionState.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (error) {
      // Cualquier fallo es lo mismo para quien compra: el PRO llega después.
      debugPrint('[subscription] sync falló: $error');
    }
    throw const SubscriptionSyncException();
  }
}
