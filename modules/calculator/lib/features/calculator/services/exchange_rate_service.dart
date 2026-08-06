import '../models/exchange_rate_cache.dart';
import 'exchange_rate_client.dart';

/// 汇率服务结果状态。
enum ExchangeRateStatus {
  idle,
  loading,
  success,
  offline,
  error,
}

/// 汇率服务。
///
/// 封装 HTTP 请求、缓存读取、离线回退与货币换算。
class ExchangeRateService {
  final ExchangeRateClient _client;

  ExchangeRateService({ExchangeRateClient? client})
      : _client = client ?? ExchangeRateClient();

  /// 默认支持的货币代码。
  static const List<String> defaultCurrencies = [
    'CNY',
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'HKD',
    'KRW',
    'AUD',
    'CAD',
    'CHF',
    'SGD',
    'RUB',
  ];

  /// 默认基准货币。
  static const String defaultBaseCurrency = 'USD';

  /// 货币代码到中文名称的映射（覆盖全球主要流通货币）。
  static const Map<String, String> currencyNames = {
    'CNY': '人民币',
    'USD': '美元',
    'EUR': '欧元',
    'JPY': '日元',
    'GBP': '英镑',
    'HKD': '港币',
    'KRW': '韩元',
    'AUD': '澳元',
    'CAD': '加元',
    'CHF': '瑞士法郎',
    'SGD': '新加坡元',
    'RUB': '俄罗斯卢布',
    'NZD': '新西兰元',
    'INR': '印度卢比',
    'BRL': '巴西雷亚尔',
    'ZAR': '南非兰特',
    'MXN': '墨西哥比索',
    'TRY': '土耳其里拉',
    'IDR': '印尼盾',
    'MYR': '马来西亚林吉特',
    'PHP': '菲律宾比索',
    'THB': '泰铢',
    'VND': '越南盾',
    'PLN': '波兰兹罗提',
    'CZK': '捷克克朗',
    'HUF': '匈牙利福林',
    'RON': '罗马尼亚列伊',
    'SEK': '瑞典克朗',
    'NOK': '挪威克朗',
    'DKK': '丹麦克朗',
    'ISK': '冰岛克朗',
    'ARS': '阿根廷比索',
    'CLP': '智利比索',
    'COP': '哥伦比亚比索',
    'PEN': '秘鲁索尔',
    'AED': '阿联酋迪拉姆',
    'SAR': '沙特里亚尔',
    'QAR': '卡塔尔里亚尔',
    'KWD': '科威特第纳尔',
    'BHD': '巴林第纳尔',
    'OMR': '阿曼里亚尔',
    'JOD': '约旦第纳尔',
    'EGP': '埃及镑',
    'NGN': '尼日利亚奈拉',
    'KES': '肯尼亚先令',
    'UGX': '乌干达先令',
    'TZS': '坦桑尼亚先令',
    'MAD': '摩洛哥迪拉姆',
    'TND': '突尼斯第纳尔',
    'UAH': '乌克兰格里夫纳',
    'BYN': '白俄罗斯卢布',
    'KZT': '哈萨克坚戈',
    'UZS': '乌兹别克斯坦苏姆',
    'AZN': '阿塞拜疆马纳特',
    'GEL': '格鲁吉亚拉里',
    'AMD': '亚美尼亚德拉姆',
    'BDT': '孟加拉国塔卡',
    'LKR': '斯里兰卡卢比',
    'PKR': '巴基斯坦卢比',
    'NPR': '尼泊尔卢比',
    'MMK': '缅甸缅元',
    'LAK': '老挝基普',
    'KHR': '柬埔寨瑞尔',
    'MOP': '澳门元',
    'TWD': '新台币',
    'MNT': '蒙古图格里克',
    'BTN': '不丹努扎姆',
    'FJD': '斐济元',
    'PGK': '巴布亚新几内亚基那',
    'WST': '萨摩亚塔拉',
    'TOP': '汤加潘加',
    'XPF': '太平洋法郎',
    'XOF': '西非法郎',
    'XAF': '中非法郎',
    'XCD': '东加勒比元',
    'ANG': '荷属安的列斯盾',
    'AWG': '阿鲁巴弗罗林',
    'BBD': '巴巴多斯元',
    'BMD': '百慕大元',
    'BSD': '巴哈马元',
    'BZD': '伯利兹元',
    'DOP': '多米尼加比索',
    'GTQ': '危地马拉格查尔',
    'HNL': '洪都拉斯伦皮拉',
    'HTG': '海地古德',
    'JMD': '牙买加元',
    'NIO': '尼加拉瓜科多巴',
    'PYG': '巴拉圭瓜拉尼',
    'SRD': '苏里南元',
    'TTD': '特立尼达和多巴哥元',
    'UYU': '乌拉圭比索',
    'VES': '委内瑞拉玻利瓦尔',
    'CUC': '古巴可兑换比索',
    'CUP': '古巴比索',
    'DZD': '阿尔及利亚第纳尔',
    'GHS': '加纳塞地',
    'XAG': '白银',
    'XAU': '黄金',
    'XPT': '铂金',
    'XPD': '钯金',
    'BTC': '比特币',
    'ETH': '以太坊',
  };

  /// 获取 [code] 对应的中文显示名；不存在时返回 [code] 本身。
  static String getCurrencyDisplayName(String code) {
    return currencyNames[code] ?? code;
  }

  /// 获取可用货币列表；优先使用缓存中的货币代码，否则返回默认列表。
  List<String> getCurrencies(ExchangeRateCache? cache) {
    if (cache == null || cache.rates.isEmpty) return List.unmodifiable(defaultCurrencies);
    final currencies = <String>[cache.baseCurrency, ...cache.rates.keys];
    currencies.sort();
    return currencies.toSet().toList();
  }

  /// 刷新汇率。
  ///
  /// - 网络成功时返回新的 [ExchangeRateCache]。
  /// - 网络失败但存在 [cache] 时返回现有缓存，并标记 [ExchangeRateStatus.offline]。
  /// - 无缓存且网络失败时返回错误。
  Future<ExchangeRateResult> refresh(
    String baseCurrency,
    String apiUrlTemplate,
    ExchangeRateCache? cache,
  ) async {
    try {
      final response = await _client.fetchRates(baseCurrency, apiUrlTemplate);
      final newCache = ExchangeRateCache(
        baseCurrency: response.baseCurrency,
        rates: response.rates,
        lastUpdated: response.lastUpdated ?? DateTime.now().toUtc(),
        sourceUrl: response.sourceUrl,
      );
      return ExchangeRateResult(
        status: ExchangeRateStatus.success,
        cache: newCache,
      );
    } on Exception catch (e) {
      if (cache != null) {
        return ExchangeRateResult(
          status: ExchangeRateStatus.offline,
          cache: cache,
          message: '离线缓存（更新时间：${_formatTime(cache.lastUpdated)}）',
        );
      }
      return ExchangeRateResult(
        status: ExchangeRateStatus.error,
        message: '暂无汇率数据，请检查网络：$e',
      );
    }
  }

  /// 将 [amount] 从 [fromCurrency] 换算为 [toCurrency]。
  ///
  /// 使用以 [baseCurrency] 为基准的 [cache] 汇率表。
  double? convert(
    double amount,
    String fromCurrency,
    String toCurrency,
    ExchangeRateCache cache,
  ) {
    if (fromCurrency == toCurrency) return amount;

    final rates = Map<String, double>.from(cache.rates);
    rates[cache.baseCurrency] = 1.0;

    final fromRate = rates[fromCurrency];
    final toRate = rates[toCurrency];
    if (fromRate == null || toRate == null) return null;

    return amount * (toRate / fromRate);
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 汇率刷新结果。
class ExchangeRateResult {
  final ExchangeRateStatus status;
  final ExchangeRateCache? cache;
  final String? message;

  const ExchangeRateResult({
    required this.status,
    this.cache,
    this.message,
  });

  bool get isSuccess => status == ExchangeRateStatus.success;
  bool get isOffline => status == ExchangeRateStatus.offline;
  bool get isError => status == ExchangeRateStatus.error;
}
