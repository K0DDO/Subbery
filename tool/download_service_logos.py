from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from html import unescape
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ICONS8_BASE = "https://img.icons8.com/color/96"
FALLBACKS = {
    "entertainment": ("video", "movie-projector"),
    "music": ("musical-notes", "music"),
    "work": ("briefcase", "work"),
    "cloud": ("cloud-server", "server"),
    "gaming": ("controller", "game-controller"),
    "education": ("learning", "education"),
    "other": ("services", "subscription"),
}

# Candidates are tried from left to right. This lets the script keep exact
# brands where Icons8 has them and fall back to a recognizable themed mark.
ICON_CANDIDATES = {
    "netflix": ("netflix",),
    "youtube": ("youtube-play", "youtube"),
    "kinopoisk": ("kinopoisk", "movie-projector"),
    "ivi": ("ivi", "movie-projector"),
    "okko": ("okko", "video"),
    "wink": ("wink", "tv"),
    "premier": ("video-playlist", "video"),
    "apple_tv": ("apple-tv", "apple-logo"),
    "hbo_max": ("hbo-max", "hbo"),
    "crunchyroll": ("crunchyroll",),
    "paramount": ("paramount-plus", "paramount"),
    "spotify": ("spotify",),
    "apple_music": ("apple-music",),
    "youtube_music": ("youtube-music",),
    "yandex_music": ("yandex-music",),
    "vk_music": ("vk-circled", "vk-com"),
    "soundcloud": ("soundcloud",),
    "deezer": ("deezer",),
    "tidal": ("tidal", "musical-notes"),
    "epidemic_sound": ("musical-notes", "music-record"),
    "artlist": ("music-library", "musical-notes"),
    "musicbed": ("playlist", "musical-notes"),
    "audiio": ("audio-wave", "musical-notes"),
    "yandex_plus": ("yandex", "plus"),
    "yandex_disk": ("yandex-disk", "cloud"),
    "vk_combo": ("vk-circled", "vk-com"),
    "tpro": ("tinkoff", "bank-card-back-side"),
    "sberprime": ("sberbank", "bank"),
    "alfa_smart": ("alfa-bank", "bank-card-back-side"),
    "mts_premium": ("mts", "sim-card"),
    "telegram": ("telegram-app", "telegram"),
    "discord": ("discord-logo", "discord"),
    "discord_boost": ("discord-new", "discord-logo"),
    "playstation": ("play-station", "playstation"),
    "xbox": ("xbox",),
    "steam": ("steam",),
    "epic_games": ("epic-games", "controller"),
    "twitch": ("twitch",),
    "icloud": ("icloud",),
    "google_one": ("google-one", "google-cloud"),
    "dropbox": ("dropbox",),
    "notion": ("notion",),
    "figma": ("figma",),
    "jetbrains": ("jetbrains",),
    "zoom": ("zoom",),
    "duolingo": ("duolingo-logo", "duolingo"),
    "chatgpt": ("chatgpt", "artificial-intelligence"),
    "claude": ("claude", "anthropic"),
    "cursor": ("cursor-ai", "cursor"),
    "github": ("github",),
    "gemini": ("gemini-ai", "google-gemini"),
    "perplexity": ("perplexity-ai", "artificial-intelligence"),
    "midjourney": ("midjourney", "artificial-intelligence"),
    "grok": ("grok", "artificial-intelligence"),
    "deepseek": ("deepseek", "artificial-intelligence"),
    "mistral": ("mistral-ai", "artificial-intelligence"),
    "kimi": ("kimi-ai", "artificial-intelligence"),
    "huggingface": ("hugging-face", "artificial-intelligence"),
    "ollama": ("ollama", "llama"),
    "my_server": ("server",),
    "vps": ("cloud-server", "server"),
    "hetzner": ("hetzner", "cloud-server"),
    "digitalocean": ("digitalocean", "cloud-server"),
    "vultr": ("vultr", "cloud-server"),
    "contabo": ("contabo", "cloud-server"),
    "hostinger": ("hostinger", "cloud-server"),
    "ovh": ("ovh", "cloud-server"),
    "cloudflare": ("cloudflare",),
    "timeweb": ("timeweb", "server"),
    "selectel": ("selectel", "data-center"),
    "proxmox": ("proxmox", "server"),
    "docker": ("docker",),
    "nordvpn": ("nordvpn", "vpn"),
    "mullvad": ("mullvad", "vpn"),
    "surfshark": ("surfshark", "vpn"),
    "protonvpn": ("protonvpn", "vpn"),
    "expressvpn": ("express-vpn", "vpn"),
    "pia": ("private-internet-access", "vpn"),
    "outline": ("outline", "vpn"),
    "wireguard": ("wireguard", "vpn"),
    "tailscale": ("tailscale", "vpn"),
    "adguard": ("adguard", "vpn"),
    "red_shield": ("shield", "vpn"),
}

PLAY_PACKAGES = {
    "netflix": ("com.netflix.mediaclient",),
    "youtube": ("com.google.android.youtube",),
    "kinopoisk": ("ru.kinopoisk",),
    "ivi": ("ru.ivi.client",),
    "okko": ("ru.more.play",),
    "wink": ("ru.rt.video.app.mobile",),
    "premier": ("gpm.tnt_premier",),
    "apple_tv": ("com.apple.atve.androidtv.appletv",),
    "hbo_max": ("com.wbd.stream",),
    "crunchyroll": ("com.crunchyroll.crunchyroid",),
    "paramount": ("com.cbs.app",),
    "spotify": ("com.spotify.music",),
    "apple_music": ("com.apple.android.music",),
    "youtube_music": ("com.google.android.apps.youtube.music",),
    "yandex_music": ("ru.yandex.music",),
    "vk_music": ("com.uma.musicvk", "com.vkontakte.android"),
    "soundcloud": ("com.soundcloud.android",),
    "deezer": ("deezer.android.app",),
    "tidal": ("com.aspiro.tidal",),
    "epidemic_sound": ("com.epidemicsound.player",),
    "musicbed": ("com.themusicbed.musicbed",),
    "audiio": ("com.audiiopro",),
    "yandex_disk": ("ru.yandex.disk",),
    "mts_premium": ("ru.mts.mymts",),
    "telegram": ("org.telegram.messenger",),
    "discord": ("com.discord",),
    "playstation": ("com.scee.psxandroid",),
    "xbox": ("com.microsoft.xboxone.smartglass",),
    "steam": ("com.valvesoftware.android.steam.community",),
    "epic_games": ("com.epicgames.ega",),
    "twitch": ("tv.twitch.android.app",),
    "google_one": ("com.google.android.apps.subscriptions.red",),
    "dropbox": ("com.dropbox.android",),
    "notion": ("notion.id",),
    "figma": ("com.figma.mirror",),
    "zoom": ("us.zoom.videomeetings",),
    "duolingo": ("com.duolingo",),
    "chatgpt": ("com.openai.chatgpt",),
    "claude": ("com.anthropic.claude",),
    "gemini": ("com.google.android.apps.bard",),
    "perplexity": ("ai.perplexity.app.android",),
    "grok": ("ai.x.grok",),
    "deepseek": ("com.deepseek.chat",),
    "mistral": ("ai.mistral.chat",),
    "kimi": ("com.moonshot.kimichat", "com.moonshotai.kimi"),
    "github": ("com.github.android",),
    "hetzner": ("de.hetzner.robot_mobile",),
    "cloudflare": ("com.cloudflare.onedotonedotonedotone",),
    "timeweb": ("cloud.timeweb.app",),
    "proxmox": ("com.proxmox.app.pve_flutter_frontend",),
    "nordvpn": ("com.nordvpn.android",),
    "mullvad": ("net.mullvad.mullvadvpn",),
    "surfshark": ("com.surfshark.vpnclient.android",),
    "protonvpn": ("ch.protonvpn.android",),
    "expressvpn": ("com.expressvpn.vpn",),
    "pia": ("com.privateinternetaccess.android",),
    "outline": ("org.outline.android.client",),
    "wireguard": ("com.wireguard.android",),
    "tailscale": ("com.tailscale.ipn",),
    "adguard": ("com.adguard.vpn",),
    "red_shield": ("com.redshieldvpn.app",),
}

FAVICON_DOMAINS = {
    "yandex_plus": "plus.yandex.ru",
    "vk_combo": "vk.com",
    "tpro": "tbank.ru",
    "sberprime": "sberbank.ru",
    "alfa_smart": "alfabank.ru",
    "icloud": "icloud.com",
    "jetbrains": "jetbrains.com",
    "cursor": "cursor.com",
    "midjourney": "midjourney.com",
    "huggingface": "huggingface.co",
    "ollama": "ollama.com",
    "digitalocean": "digitalocean.com",
    "vultr": "vultr.com",
    "contabo": "contabo.com",
    "ovh": "ovhcloud.com",
    "selectel": "selectel.ru",
    "docker": "docker.com",
    "hostinger": "hostinger.com",
    "artlist": "artlist.io",
}

DIRECT_ICONS = {
    "discord_boost": (
        "Icons8",
        "https://img.icons8.com/?size=96&id=315Iv2pFhV1m"
        "&format=png&color=F47FFF",
    ),
    "yandex_plus": (
        "Logo-teka",
        "https://logo-teka.com/download/logo/56049/png/",
    ),
}


def _catalog(root: Path) -> list[tuple[str, str, str]]:
    source = (
        root
        / "lib"
        / "features"
        / "subscriptions"
        / "data"
        / "catalog"
        / "known_services.dart"
    ).read_text(encoding="utf-8")
    entries = re.findall(
        r"name: '([^']+)',\s+logoKey: '([^']+)',\s+"
        r"category: SubscriptionCategory\.([a-z]+),",
        source,
    )
    if not entries:
        raise RuntimeError("Known service catalog could not be parsed.")
    return [(name, key, category) for name, key, category in entries]


def _download(url: str, target: Path) -> bool:
    request = urllib.request.Request(url, headers={"User-Agent": "Subberry/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            content_type = response.headers.get_content_type()
            if response.status != 200 or (
                not content_type.startswith("image/")
                and content_type != "application/octet-stream"
            ):
                return False
            target.write_bytes(response.read())
        with Image.open(target) as image:
            image.verify()
        return True
    except (OSError, urllib.error.URLError):
        target.unlink(missing_ok=True)
        return False


def _download_play_icon(packages: tuple[str, ...], target: Path) -> tuple[str, str] | None:
    for package in packages:
        page_url = (
            "https://play.google.com/store/apps/details"
            f"?id={package}&hl=en&gl=US"
        )
        request = urllib.request.Request(
            page_url,
            headers={"User-Agent": "Mozilla/5.0"},
        )
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                html = response.read().decode("utf-8")
            match = re.search(
                r'<meta[^>]+property="og:image"[^>]+content="([^"]+)"',
                html,
            )
            if match is None:
                match = re.search(
                    r'<meta[^>]+content="([^"]+)"[^>]+property="og:image"',
                    html,
                )
            if match is None:
                continue
            image_url = unescape(match.group(1))
            if not _download(image_url, target):
                continue
            with Image.open(target) as image:
                artwork = image.convert("RGBA")
                artwork.thumbnail((96, 96), Image.Resampling.LANCZOS)
                canvas = Image.new("RGBA", (96, 96))
                canvas.paste(
                    artwork,
                    ((96 - artwork.width) // 2, (96 - artwork.height) // 2),
                    artwork,
                )
                canvas.save(target)
            return package, image_url
        except (OSError, urllib.error.URLError):
            continue
    return None


def _download_favicon(domain: str | None, target: Path) -> str | None:
    if not domain:
        return None
    url = f"https://www.google.com/s2/favicons?domain={domain}&sz=128"
    if not _download(url, target):
        return None
    with Image.open(target) as image:
        artwork = image.convert("RGBA")
        artwork = artwork.resize((96, 96), Image.Resampling.LANCZOS)
        artwork.save(target)
    return url


def _contact_sheet(root: Path, entries: list[tuple[str, str, str]]) -> None:
    columns = 5
    tile_width, tile_height = 210, 132
    header_height = 76
    rows = (len(entries) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (columns * tile_width, header_height + rows * tile_height),
        (16, 17, 20),
    )
    draw = ImageDraw.Draw(sheet)
    font_path = Path("C:/Windows/Fonts/arial.ttf")
    try:
        label_font = ImageFont.truetype(str(font_path), 19)
        title_font = ImageFont.truetype(str(font_path), 30)
    except OSError:
        label_font = ImageFont.load_default()
        title_font = ImageFont.load_default()

    title = (
        f"Subberry — {len(entries)} service icons · "
        "Google Play + official brand sources"
    )
    draw.text((24, 20), title, font=title_font, fill=(246, 246, 248))
    logo_dir = root / "assets" / "service_logos"
    for index, (name, key, _) in enumerate(entries):
        column = index % columns
        row = index // columns
        left = column * tile_width + 8
        top = header_height + row * tile_height + 6
        draw.rounded_rectangle(
            (left, top, left + tile_width - 16, top + tile_height - 12),
            radius=16,
            fill=(29, 30, 35),
        )
        with Image.open(logo_dir / f"{key}.png") as icon:
            artwork = icon.convert("RGBA")
            artwork.thumbnail((66, 66), Image.Resampling.LANCZOS)
            icon_x = left + (tile_width - 16 - artwork.width) // 2
            sheet.paste(artwork, (icon_x, top + 12), artwork)
        display_name = name if len(name) <= 22 else f"{name[:20]}…"
        bounds = draw.textbbox((0, 0), display_name, font=label_font)
        text_width = bounds[2] - bounds[0]
        draw.text(
            (left + (tile_width - 16 - text_width) / 2, top + 86),
            display_name,
            font=label_font,
            fill=(224, 225, 230),
        )

    docs = root / "docs"
    docs.mkdir(parents=True, exist_ok=True)
    sheet.save(docs / "service-logo-catalog.png", optimize=True)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    destination = root / "assets" / "service_logos"
    destination.mkdir(parents=True, exist_ok=True)
    sources: dict[str, dict[str, str]] = {}

    for name, key, category in _catalog(root):
        target = destination / f"{key}.png"
        direct = DIRECT_ICONS.get(key)
        if direct is not None:
            source_name, url = direct
            if not _download(url, target):
                raise RuntimeError(f"Direct icon download failed for {name}.")
            sources[key] = {
                "name": name,
                "source": source_name,
                "url": url,
            }
            print(f"{key:24} {source_name} · direct")
            continue

        play_result = _download_play_icon(PLAY_PACKAGES.get(key, ()), target)
        if play_result is not None:
            package, url = play_result
            sources[key] = {
                "name": name,
                "source": "Google Play",
                "package": package,
                "url": url,
            }
            print(f"{key:24} Google Play · {package}")
            continue

        favicon_url = _download_favicon(FAVICON_DOMAINS.get(key), target)
        if favicon_url is not None:
            sources[key] = {
                "name": name,
                "source": "Google Favicon",
                "domain": FAVICON_DOMAINS[key],
                "url": favicon_url,
            }
            print(f"{key:24} Favicon · {FAVICON_DOMAINS[key]}")
            continue

        candidates = (*ICON_CANDIDATES.get(key, ()), *FALLBACKS[category])
        for slug in dict.fromkeys(candidates):
            url = f"{ICONS8_BASE}/{slug}.png"
            if _download(url, target):
                sources[key] = {
                    "name": name,
                    "source": "Icons8",
                    "slug": slug,
                    "url": url,
                }
                print(f"{key:24} {slug}")
                break
        else:
            raise RuntimeError(f"No downloadable Icons8 icon for {name} ({key}).")

    expected = {key for _, key, _ in _catalog(root)}
    missing = expected - sources.keys()
    if missing:
        raise RuntimeError(f"Missing downloaded assets: {sorted(missing)}")

    metadata = root / "tool" / "service_logo_sources.json"
    metadata.write_text(
        json.dumps(sources, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    _contact_sheet(root, _catalog(root))
    print(f"Downloaded {len(sources)} icons.")


if __name__ == "__main__":
    main()
