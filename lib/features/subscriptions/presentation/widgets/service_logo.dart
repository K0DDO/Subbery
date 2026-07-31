import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../data/catalog/known_services.dart';
import '../../domain/entities/subscription.dart';
import '../subscription_ui_extensions.dart';

class ServiceLogo extends StatelessWidget {
  const ServiceLogo({
    required this.name,
    required this.category,
    this.logoKey,
    this.size = 56,
    super.key,
  });

  final String name;
  final String? logoKey;
  final SubscriptionCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    KnownService? knownService;
    for (final service in KnownServices.all) {
      if (service.logoKey == logoKey) {
        knownService = service;
        break;
      }
    }

    final color = knownService == null
        ? category.color
        : Color(knownService.brandColorValue);
    final monogram =
        knownService?.monogram ??
        (name.trim().isEmpty ? 'S' : name.trim().substring(0, 1).toUpperCase());
    final brandIcon = _brandIconFor(knownService?.logoKey ?? logoKey);

    return Semantics(
      image: true,
      label: 'Логотип $name',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              color.withValues(alpha: 0.96),
              Color.lerp(color, Colors.black, 0.22)!,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: size * 0.4,
              offset: Offset(0, size * 0.14),
            ),
          ],
        ),
        child: brandIcon == null
            ? Text(
                monogram,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              )
            : Icon(brandIcon, color: Colors.white, size: size * 0.48),
      ),
    );
  }

  static IconData? _brandIconFor(String? logoKey) => switch (logoKey) {
    // Streaming & entertainment
    'netflix' => SimpleIcons.netflix,
    'youtube' => SimpleIcons.youtube,
    'kinopoisk' => SimpleIcons.kinopoisk,
    'ivi' => Icons.movie_rounded,
    'okko' => Icons.theaters_rounded,
    'wink' => Icons.live_tv_rounded,
    'premier' => Icons.play_circle_filled_rounded,
    'apple_tv' => SimpleIcons.appletv,
    'hbo_max' => SimpleIcons.hbomax,
    'crunchyroll' => SimpleIcons.crunchyroll,
    'paramount' => SimpleIcons.paramountplus,

    // Music
    'spotify' => SimpleIcons.spotify,
    'apple_music' => SimpleIcons.applemusic,
    'youtube_music' => SimpleIcons.youtubemusic,
    'yandex_music' => SimpleIcons.yandexcloud,
    'vk_music' => SimpleIcons.vk,
    'soundcloud' => SimpleIcons.soundcloud,
    'deezer' => SimpleIcons.deezer,
    'tidal' => SimpleIcons.tidal,

    // Russian ecosystems & banks
    'yandex_plus' => SimpleIcons.yandexcloud,
    'yandex_disk' => SimpleIcons.yandexcloud,
    'vk_combo' => SimpleIcons.vk,
    'tpro' => Icons.account_balance_wallet_rounded,
    'sberprime' => Icons.account_balance_rounded,
    'alfa_smart' => Icons.credit_card_rounded,
    'mts_premium' => Icons.smartphone_rounded,

    // Messaging & gaming
    'telegram' => SimpleIcons.telegram,
    'discord' => SimpleIcons.discord,
    'discord_boost' => SimpleIcons.discord,
    'playstation' => SimpleIcons.playstation,
    'xbox' => Icons.sports_esports_rounded,
    'steam' => SimpleIcons.steam,
    'epic_games' => SimpleIcons.epicgames,
    'twitch' => SimpleIcons.twitch,

    // Cloud & productivity
    'icloud' => SimpleIcons.icloud,
    'google_one' => SimpleIcons.googlecloud,
    'dropbox' => SimpleIcons.dropbox,
    'notion' => SimpleIcons.notion,
    'figma' => SimpleIcons.figma,
    'jetbrains' => SimpleIcons.jetbrains,
    'zoom' => SimpleIcons.zoom,
    'duolingo' => SimpleIcons.duolingo,

    // AI
    'chatgpt' => Icons.auto_awesome_rounded,
    'claude' => SimpleIcons.claude,
    'cursor' => SimpleIcons.cursor,
    'github' => SimpleIcons.githubcopilot,
    'gemini' => SimpleIcons.googlegemini,
    'perplexity' => SimpleIcons.perplexity,
    'midjourney' => Icons.brush_rounded,
    'grok' => Icons.psychology_rounded,
    'deepseek' => SimpleIcons.deepseek,
    'mistral' => SimpleIcons.mistralai,
    'kimi' => SimpleIcons.moonshotai,
    'huggingface' => SimpleIcons.huggingface,
    'ollama' => SimpleIcons.ollama,

    // VPS & servers
    'my_server' => Icons.dns_rounded,
    'vps' => Icons.cloud_rounded,
    'hetzner' => SimpleIcons.hetzner,
    'digitalocean' => SimpleIcons.digitalocean,
    'vultr' => SimpleIcons.vultr,
    'contabo' => SimpleIcons.contabo,
    'hostinger' => SimpleIcons.hostinger,
    'ovh' => SimpleIcons.ovh,
    'cloudflare' => SimpleIcons.cloudflare,
    'timeweb' => Icons.storage_rounded,
    'selectel' => Icons.hub_rounded,
    'proxmox' => SimpleIcons.proxmox,
    'docker' => SimpleIcons.docker,

    // VPN
    'nordvpn' => SimpleIcons.nordvpn,
    'mullvad' => SimpleIcons.mullvad,
    'surfshark' => SimpleIcons.surfshark,
    'protonvpn' => SimpleIcons.protonvpn,
    'expressvpn' => SimpleIcons.expressvpn,
    'pia' => SimpleIcons.privateinternetaccess,
    'outline' => SimpleIcons.outline,
    'wireguard' => SimpleIcons.wireguard,
    'tailscale' => SimpleIcons.tailscale,
    'adguard' => SimpleIcons.adguard,
    'red_shield' => Icons.shield_rounded,
    _ => null,
  };
}
