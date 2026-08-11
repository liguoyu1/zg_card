import 'package:url_launcher/url_launcher.dart';

/// 非 Web 端：交给系统浏览器/应用内打开
Future<bool> launchXsolla(String url) async =>
    launchUrl(Uri.parse(url));
