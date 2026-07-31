import '../../domain/entities/subscription.dart';

class KnownService {
  const KnownService({
    required this.name,
    required this.logoKey,
    required this.category,
    required this.brandColorValue,
  });

  final String name;
  final String logoKey;
  final SubscriptionCategory category;
  final int brandColorValue;

  String get monogram => name.substring(0, 1).toUpperCase();
}

abstract final class KnownServices {
  static const all = <KnownService>[
    // Entertainment & streaming
    KnownService(
      name: 'Netflix',
      logoKey: 'netflix',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFE50914,
    ),
    KnownService(
      name: 'YouTube Premium',
      logoKey: 'youtube',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFFF0033,
    ),
    KnownService(
      name: 'Кинопоиск',
      logoKey: 'kinopoisk',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFFF6600,
    ),
    KnownService(
      name: 'IVI',
      logoKey: 'ivi',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFEA003D,
    ),
    KnownService(
      name: 'Okko',
      logoKey: 'okko',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFF5B2BE0,
    ),
    KnownService(
      name: 'Wink',
      logoKey: 'wink',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFE31C79,
    ),
    KnownService(
      name: 'Premier',
      logoKey: 'premier',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFF1A1A1A,
    ),
    KnownService(
      name: 'Apple TV+',
      logoKey: 'apple_tv',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFF1A1A1A,
    ),
    KnownService(
      name: 'HBO Max',
      logoKey: 'hbo_max',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFF6E1AE4,
    ),
    KnownService(
      name: 'Crunchyroll',
      logoKey: 'crunchyroll',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFF47521,
    ),
    KnownService(
      name: 'Paramount+',
      logoKey: 'paramount',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFF0064FF,
    ),

    // Music
    KnownService(
      name: 'Spotify',
      logoKey: 'spotify',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF1DB954,
    ),
    KnownService(
      name: 'Apple Music',
      logoKey: 'apple_music',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFA243C,
    ),
    KnownService(
      name: 'YouTube Music',
      logoKey: 'youtube_music',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFF0033,
    ),
    KnownService(
      name: 'Яндекс Музыка',
      logoKey: 'yandex_music',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFFCC00,
    ),
    KnownService(
      name: 'VK Музыка',
      logoKey: 'vk_music',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF0077FF,
    ),
    KnownService(
      name: 'SoundCloud Go+',
      logoKey: 'soundcloud',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFF5500,
    ),
    KnownService(
      name: 'Deezer',
      logoKey: 'deezer',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFA238FF,
    ),
    KnownService(
      name: 'Tidal',
      logoKey: 'tidal',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF000000,
    ),
    KnownService(
      name: 'Epidemic Sound',
      logoKey: 'epidemic_sound',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF000000,
    ),
    KnownService(
      name: 'Artlist',
      logoKey: 'artlist',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF0B0B0B,
    ),
    KnownService(
      name: 'Musicbed',
      logoKey: 'musicbed',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF1C1C1C,
    ),
    KnownService(
      name: 'Audiio',
      logoKey: 'audiio',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFF4D00,
    ),

    // Russian ecosystems & banks
    KnownService(
      name: 'Яндекс Плюс',
      logoKey: 'yandex_plus',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFFFCC00,
    ),
    KnownService(
      name: 'Яндекс Диск',
      logoKey: 'yandex_disk',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF37A3E4,
    ),
    KnownService(
      name: 'VK Combo',
      logoKey: 'vk_combo',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF0077FF,
    ),
    KnownService(
      name: 'T-Pro',
      logoKey: 'tpro',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFFFDD2D,
    ),
    KnownService(
      name: 'СберПрайм',
      logoKey: 'sberprime',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF21A038,
    ),
    KnownService(
      name: 'Альфа-Смарт',
      logoKey: 'alfa_smart',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFEF3124,
    ),
    KnownService(
      name: 'МТС Premium',
      logoKey: 'mts_premium',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFE30611,
    ),

    // Messaging & gaming
    KnownService(
      name: 'Telegram Premium',
      logoKey: 'telegram',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF2AABEE,
    ),
    KnownService(
      name: 'Discord Nitro',
      logoKey: 'discord',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF5865F2,
    ),
    KnownService(
      name: 'Discord Boost',
      logoKey: 'discord_boost',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFFF47FFF,
    ),
    KnownService(
      name: 'PlayStation Plus',
      logoKey: 'playstation',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF0070D1,
    ),
    KnownService(
      name: 'Xbox Game Pass',
      logoKey: 'xbox',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF107C10,
    ),
    KnownService(
      name: 'Steam',
      logoKey: 'steam',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF1B2838,
    ),
    KnownService(
      name: 'Epic Games',
      logoKey: 'epic_games',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF2A2A2A,
    ),
    KnownService(
      name: 'Twitch Turbo',
      logoKey: 'twitch',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF9146FF,
    ),

    // Cloud & productivity
    KnownService(
      name: 'iCloud',
      logoKey: 'icloud',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF4A9EFF,
    ),
    KnownService(
      name: 'Google One',
      logoKey: 'google_one',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF4285F4,
    ),
    KnownService(
      name: 'Dropbox',
      logoKey: 'dropbox',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF0061FF,
    ),
    KnownService(
      name: 'Notion',
      logoKey: 'notion',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF222222,
    ),
    KnownService(
      name: 'Figma',
      logoKey: 'figma',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFF24E1E,
    ),
    KnownService(
      name: 'JetBrains',
      logoKey: 'jetbrains',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFFE315D,
    ),
    KnownService(
      name: 'Zoom Pro',
      logoKey: 'zoom',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF2D8CFF,
    ),
    KnownService(
      name: 'Duolingo Super',
      logoKey: 'duolingo',
      category: SubscriptionCategory.education,
      brandColorValue: 0xFF58CC02,
    ),

    // AI
    KnownService(
      name: 'ChatGPT Plus',
      logoKey: 'chatgpt',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF10A37F,
    ),
    KnownService(
      name: 'Claude Pro',
      logoKey: 'claude',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFD97757,
    ),
    KnownService(
      name: 'Cursor',
      logoKey: 'cursor',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF000000,
    ),
    KnownService(
      name: 'GitHub Copilot',
      logoKey: 'github',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF6E40C9,
    ),
    KnownService(
      name: 'Google Gemini',
      logoKey: 'gemini',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF4285F4,
    ),
    KnownService(
      name: 'Perplexity Pro',
      logoKey: 'perplexity',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF20808D,
    ),
    KnownService(
      name: 'Midjourney',
      logoKey: 'midjourney',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF1E1E1E,
    ),
    KnownService(
      name: 'Grok',
      logoKey: 'grok',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF1A1A1A,
    ),
    KnownService(
      name: 'DeepSeek',
      logoKey: 'deepseek',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF4D6BFE,
    ),
    KnownService(
      name: 'Mistral AI',
      logoKey: 'mistral',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFFF7000,
    ),
    KnownService(
      name: 'Kimi',
      logoKey: 'kimi',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF1783FF,
    ),
    KnownService(
      name: 'Hugging Face Pro',
      logoKey: 'huggingface',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFFFD21E,
    ),
    KnownService(
      name: 'Ollama',
      logoKey: 'ollama',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF1A1A1A,
    ),

    // VPS & servers
    KnownService(
      name: 'Мой сервер',
      logoKey: 'my_server',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF455A64,
    ),
    KnownService(
      name: 'VPS',
      logoKey: 'vps',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF37474F,
    ),
    KnownService(
      name: 'Hetzner',
      logoKey: 'hetzner',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFFD50C2D,
    ),
    KnownService(
      name: 'DigitalOcean',
      logoKey: 'digitalocean',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF0080FF,
    ),
    KnownService(
      name: 'Vultr',
      logoKey: 'vultr',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF007BFC,
    ),
    KnownService(
      name: 'Contabo',
      logoKey: 'contabo',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF00ADEF,
    ),
    KnownService(
      name: 'Hostinger',
      logoKey: 'hostinger',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF673DE6,
    ),
    KnownService(
      name: 'OVH',
      logoKey: 'ovh',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF123F6D,
    ),
    KnownService(
      name: 'Cloudflare',
      logoKey: 'cloudflare',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFFF38020,
    ),
    KnownService(
      name: 'Timeweb',
      logoKey: 'timeweb',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF00B956,
    ),
    KnownService(
      name: 'Selectel',
      logoKey: 'selectel',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF24B47E,
    ),
    KnownService(
      name: 'Proxmox',
      logoKey: 'proxmox',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFFE57000,
    ),
    KnownService(
      name: 'Docker Host',
      logoKey: 'docker',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF2496ED,
    ),

    // VPN
    KnownService(
      name: 'NordVPN',
      logoKey: 'nordvpn',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF4687FF,
    ),
    KnownService(
      name: 'Mullvad',
      logoKey: 'mullvad',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF294D73,
    ),
    KnownService(
      name: 'Surfshark',
      logoKey: 'surfshark',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF1EBFBF,
    ),
    KnownService(
      name: 'Proton VPN',
      logoKey: 'protonvpn',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF6D4AFF,
    ),
    KnownService(
      name: 'ExpressVPN',
      logoKey: 'expressvpn',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFDA3940,
    ),
    KnownService(
      name: 'Private Internet Access',
      logoKey: 'pia',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF1E9338,
    ),
    KnownService(
      name: 'Outline VPN',
      logoKey: 'outline',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF1B9AEF,
    ),
    KnownService(
      name: 'WireGuard',
      logoKey: 'wireguard',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF88171A,
    ),
    KnownService(
      name: 'Tailscale',
      logoKey: 'tailscale',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF242424,
    ),
    KnownService(
      name: 'AdGuard VPN',
      logoKey: 'adguard',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF68BC71,
    ),
    KnownService(
      name: 'Red Shield VPN',
      logoKey: 'red_shield',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFFE53935,
    ),
  ];

  static KnownService? exactMatch(String query) {
    final normalizedQuery = _normalize(query);
    for (final service in all) {
      if (_normalize(service.name) == normalizedQuery) return service;
    }
    return null;
  }

  static KnownService? byLogoKey(String? logoKey) {
    if (logoKey == null) return null;
    for (final service in all) {
      if (service.logoKey == logoKey) return service;
    }
    return null;
  }

  static List<KnownService> suggestionsFor(String query, {int limit = 4}) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const <KnownService>[];

    final matches = all.where((service) {
      return _normalize(service.name).contains(normalizedQuery);
    }).toList();
    matches.sort((left, right) {
      final leftStarts = _normalize(left.name).startsWith(normalizedQuery);
      final rightStarts = _normalize(right.name).startsWith(normalizedQuery);
      if (leftStarts != rightStarts) return leftStarts ? -1 : 1;
      return left.name.compareTo(right.name);
    });
    return matches.take(limit).toList(growable: false);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
