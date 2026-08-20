import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Disk-backed cache for map tiles.
///
/// flutter_map's default [NetworkTileProvider] keeps tiles only in Flutter's
/// in-memory [ImageCache], so every cold start re-downloads the whole visible
/// map. Home is the first screen a signed-in user sees, which made that the
/// single most visible "the app is slow to load" cost in the app.
///
/// Tiles get their OWN [CacheManager] rather than sharing
/// `DefaultCacheManager` with pet photos, because the two have opposite
/// shapes: a handful of large, frequently-changing pet images versus hundreds
/// of tiny, effectively-immutable tiles. Sharing one store would let a pan
/// across the map evict every pet photo (and vice versa) through the shared
/// object-count ceiling.
class MapTileCache {
  MapTileCache._();

  /// Distinct from the default store's key — this is what gives tiles their
  /// own eviction budget.
  static const String _key = 'petty_bounty_map_tiles';

  /// ~2000 tiles is roughly a city's worth of panning at the zoom levels this
  /// map allows (8–18), and tiles are small. 30 days matches how rarely base
  /// map imagery changes; a stale road is a far cheaper error than a blank map.
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );
}

/// [TileProvider] that serves tiles through [MapTileCache], so a tile fetched
/// in a previous session is read from disk instead of the network.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      CachedNetworkImageProvider(
        getTileUrl(coordinates, options),
        headers: headers,
        cacheManager: MapTileCache.instance,
      );
}
