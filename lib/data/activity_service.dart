import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';

/// 每日打卡结果
class CheckinResult {
  final bool success;
  final bool already;
  final String date;
  final int streak;
  final int gold;
  final int bonus;
  final int? goldTotal;

  CheckinResult.fromJson(Map<String, dynamic> json)
      : success = json['success'] == true,
        already = json['already'] == true,
        date = json['date'] as String? ?? '',
        streak = (json['streak'] as num?)?.toInt() ?? 0,
        gold = (json['gold'] as num?)?.toInt() ?? 0,
        bonus = (json['bonus'] as num?)?.toInt() ?? 0,
        goldTotal = (json['goldTotal'] as num?)?.toInt();
}

/// 系统公告
class Announcement {
  final String id;
  final String title;
  final String content;

  Announcement({required this.id, required this.title, required this.content});

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

/// 活动功能服务：每日打卡 + 系统公告
class ActivityService {
  ActivityService._();
  static final ActivityService I = ActivityService._();

  static const String _baseUrl = ApiConfig.baseUrl;

  /// 每日打卡（需登录）
  Future<CheckinResult?> checkin(String token) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/checkin'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return null;
      return CheckinResult.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 拉取系统公告（公开）
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/announcements'));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}