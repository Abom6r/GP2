import 'package:supabase_flutter/supabase_flutter.dart';

class AIPlannerService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> generatePlan(String prompt) async {
    final res = await _supabase.functions.invoke(
      'ai-planner',
      body: {'prompt': prompt},
    );

    if (res.status != 200) {
      throw Exception(res.data.toString());
    }

    return Map<String, dynamic>.from(res.data as Map);
  }
}