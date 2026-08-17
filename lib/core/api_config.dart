/// 后端 API 基地址配置
///
/// 默认使用生产环境 Railway 地址；本地/测试可通过构建时注入覆盖：
///   flutter build web --dart-define=API_BASE_URL=http://localhost:3000
class ApiConfig {
  ApiConfig._();

  /// 生产环境 API 地址
  static const String production = 'https://app-server-production-39d1.up.railway.app';

  /// 当前使用的 API 基地址（构建时通过 --dart-define=API_BASE_URL 覆盖）
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: production,
  );
}
