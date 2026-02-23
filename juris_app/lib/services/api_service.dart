import 'package:cloud_functions/cloud_functions.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Future<Map<String, dynamic>> generateLOD({
    required String auditId,
    required String tenantName,
    String? tenantIc,
    String? tenantAddress,
    required String landlordName,
    required String propertyAddress,
  }) async {
    final callable = _functions.httpsCallable(
      'generateLOD',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'audit_id': auditId,
      'tenant_name': tenantName,
      'tenant_ic': tenantIc,
      'tenant_address': tenantAddress,
      'landlord_name': landlordName,
      'property_address': propertyAddress,
    });

    return result.data;
  }

  Future<Map<String, dynamic>> simplifyClause({
    required String clauseText,
    String targetLanguage = 'en',
    String? violationType,
    String? statuteViolated,
  }) async {
    final callable = _functions.httpsCallable(
      'simplifyClause',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final params = <String, dynamic>{
      'clause_text': clauseText,
      'target_language': targetLanguage,
    };
    if (violationType != null) params['violation_type'] = violationType;
    if (statuteViolated != null) params['statute_violated'] = statuteViolated;

    final result = await callable.call<Map<String, dynamic>>(params);

    return result.data;
  }
}
