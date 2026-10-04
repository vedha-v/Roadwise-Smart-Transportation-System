import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RestaurantFilter {
  final String? cuisine;
  final bool vegetarianOnly;
  final bool familyFriendlyOnly;
  final int? maxPriceLevel;
  final double minRating;
  final double maxDistanceKm;

  const RestaurantFilter({
    this.cuisine,
    this.vegetarianOnly = false,
    this.familyFriendlyOnly = false,
    this.maxPriceLevel,
    this.minRating = 0,
    this.maxDistanceKm = 20,
  });
}

class RecommendationProfile {
  final int groupSize;
  final String preferredCuisine;
  final int budgetLevel;
  final String dietaryPreference;
  final double ratingPreference;
  final double maxDistanceKm;
  final bool familyFriendly;
  final List<String> previousChoices;

  const RecommendationProfile({
    this.groupSize = 2,
    this.preferredCuisine = 'Any',
    this.budgetLevel = 2,
    this.dietaryPreference = 'Any',
    this.ratingPreference = 4.0,
    this.maxDistanceKm = 5.0,
    this.familyFriendly = true,
    this.previousChoices = const [],
  });
}

class Restaurant {
  final String id;
  final String name;
  final LatLng point;
  final String cuisine;
  final int priceLevel;
  final double rating;
  final double distanceKm;
  final int travelMinutes;
  final bool vegetarianFriendly;
  final bool familyFriendly;
  final List<String> details;
  final String summary;

  const Restaurant({
    required this.id,
    required this.name,
    required this.point,
    required this.cuisine,
    required this.priceLevel,
    required this.rating,
    required this.distanceKm,
    required this.travelMinutes,
    required this.vegetarianFriendly,
    required this.familyFriendly,
    required this.details,
    required this.summary,
  });
}

class RestaurantRecommendationEngine {
  static List<Restaurant> recommend(
    List<Restaurant> restaurants, {
    required RecommendationProfile profile,
  }) {
    final scored = <_ScoredRestaurant>[];

    for (final restaurant in restaurants) {
      double score = 0;

      final cuisineMatches = profile.preferredCuisine == 'Any' ||
          restaurant.cuisine.toLowerCase() == profile.preferredCuisine.toLowerCase() ||
          restaurant.cuisine.toLowerCase().contains(profile.preferredCuisine.toLowerCase());
      if (cuisineMatches) {
        score += 35;
      }

      if (restaurant.rating >= profile.ratingPreference) {
        score += (restaurant.rating - 3.0) * 20;
      } else {
        score -= (profile.ratingPreference - restaurant.rating) * 18;
      }

      if (restaurant.distanceKm <= profile.maxDistanceKm) {
        score += (profile.maxDistanceKm - restaurant.distanceKm) * 10;
      } else {
        score -= (restaurant.distanceKm - profile.maxDistanceKm) * 12;
      }

      if (restaurant.familyFriendly && profile.familyFriendly) {
        score += 18;
      }

      if (restaurant.vegetarianFriendly &&
          (profile.dietaryPreference == 'Vegetarian' ||
              profile.dietaryPreference == 'Vegan')) {
        score += 22;
      }

      if (restaurant.priceLevel <= profile.budgetLevel) {
        score += 12;
      } else {
        score -= (restaurant.priceLevel - profile.budgetLevel) * 10;
      }

      if (profile.groupSize > 3 && restaurant.familyFriendly) {
        score += 10;
      }

      if (profile.previousChoices.contains(restaurant.name)) {
        score += 15;
      }

      scored.add(_ScoredRestaurant(restaurant: restaurant, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.restaurant).toList();
  }
}

class _ScoredRestaurant {
  final Restaurant restaurant;
  final double score;

  const _ScoredRestaurant({
    required this.restaurant,
    required this.score,
  });
}

class RestaurantService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<Restaurant>> searchNearbyRestaurants({
    required LatLng location,
    String query = '',
    RestaurantFilter filter = const RestaurantFilter(),
  }) async {
    try {
      final uri = Uri.parse(_overpassUrl).replace(
        queryParameters: {'data': _buildQuery(location)},
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'RoadWise/1.0',
            },
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        return _applyFilters(_fallbackRestaurants(location), query: query, filter: filter);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _applyFilters(_fallbackRestaurants(location), query: query, filter: filter);
      }

      final elements = decoded['elements'] as List<dynamic>? ?? const [];

      final restaurants = <Restaurant>[];

      for (final element in elements) {
        if (element is! Map<String, dynamic>) {
          continue;
        }

        final tags = (element['tags'] as Map<String, dynamic>?) ?? const {};
        final amenity = tags['amenity']?.toString();
        if (amenity == null ||
            !['restaurant', 'cafe', 'fast_food'].contains(amenity)) {
          continue;
        }

        final name = (tags['name'] ?? 'Local spot').toString();
        final lat = (element['lat'] ?? element['center']?['lat']) as num?;
        final lon = (element['lon'] ?? element['center']?['lon']) as num?;
        if (lat == null || lon == null) {
          continue;
        }

        final point = LatLng(lat.toDouble(), lon.toDouble());
        final cuisine = _parseCuisine(tags);
        final priceLevel = _parsePriceLevel(tags);
        final rating = _estimateRating(tags);
        final distanceKm = _distanceInKm(location, point);
        final travelMinutes = (distanceKm / 18 * 60).round();
        final dietFriendly = _isVegetarianFriendly(tags);
        final familyFriendly = _isFamilyFriendly(tags);
        final details = _extractDetails(tags);
        final summary = _buildSummary(tags, cuisine);

        final restaurant = Restaurant(
          id: [amenity, name, lat.toString(), lon.toString()].join('_'),
          name: name,
          point: point,
          cuisine: cuisine,
          priceLevel: priceLevel,
          rating: rating,
          distanceKm: distanceKm,
          travelMinutes: travelMinutes,
          vegetarianFriendly: dietFriendly,
          familyFriendly: familyFriendly,
          details: details,
          summary: summary,
        );

        restaurants.add(restaurant);
      }

      final filtered = _applyFilters(restaurants, query: query, filter: filter);
      if (filtered.isNotEmpty) {
        return filtered;
      }

      return _applyFilters(_fallbackRestaurants(location), query: query, filter: filter);
    } catch (_) {
      return _applyFilters(_fallbackRestaurants(location), query: query, filter: filter);
    }
  }

  static List<Restaurant> _applyFilters(
    List<Restaurant> restaurants, {
    required String query,
    required RestaurantFilter filter,
  }) {
    final filtered = restaurants.where((restaurant) {
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          restaurant.name.toLowerCase().contains(q) ||
          restaurant.cuisine.toLowerCase().contains(q) ||
          restaurant.summary.toLowerCase().contains(q);

      final matchesCuisine = filter.cuisine == null ||
          filter.cuisine!.isEmpty ||
          restaurant.cuisine.toLowerCase().contains(filter.cuisine!.toLowerCase());

      final matchesVegetarian = !filter.vegetarianOnly || restaurant.vegetarianFriendly;
      final matchesFamily = !filter.familyFriendlyOnly || restaurant.familyFriendly;
      final matchesPrice = filter.maxPriceLevel == null || restaurant.priceLevel <= filter.maxPriceLevel!;
      final matchesRating = restaurant.rating >= filter.minRating;
      final matchesDistance = restaurant.distanceKm <= filter.maxDistanceKm;

      return matchesQuery &&
          matchesCuisine &&
          matchesVegetarian &&
          matchesFamily &&
          matchesPrice &&
          matchesRating &&
          matchesDistance;
    }).toList();

    filtered.sort((a, b) {
      final byDistance = a.distanceKm.compareTo(b.distanceKm);
      if (byDistance != 0) return byDistance;
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  static List<Restaurant> _fallbackRestaurants(LatLng location) {
    final fallback = <Restaurant>[
      _buildFallbackRestaurant(
        baseLocation: location,
        id: 'restaurant_tandoori_terrace',
        name: 'Tandoori Terrace',
        cuisine: 'Indian',
        lat: location.latitude + 0.0036,
        lon: location.longitude + 0.0042,
        priceLevel: 2,
        rating: 4.6,
        vegetarianFriendly: true,
        familyFriendly: true,
      ),
      _buildFallbackRestaurant(
        baseLocation: location,
        id: 'restaurant_saffron_bowl',
        name: 'Saffron Bowl',
        cuisine: 'North Indian',
        lat: location.latitude - 0.0027,
        lon: location.longitude + 0.0031,
        priceLevel: 2,
        rating: 4.5,
        vegetarianFriendly: true,
        familyFriendly: true,
      ),
      _buildFallbackRestaurant(
        baseLocation: location,
        id: 'cafe_green_leaf',
        name: 'Green Leaf Cafe',
        cuisine: 'Cafe',
        lat: location.latitude + 0.0018,
        lon: location.longitude - 0.0038,
        priceLevel: 2,
        rating: 4.3,
        vegetarianFriendly: true,
        familyFriendly: true,
      ),
      _buildFallbackRestaurant(
        baseLocation: location,
        id: 'restaurant_lotus_wok',
        name: 'Lotus Wok',
        cuisine: 'Chinese',
        lat: location.latitude - 0.0045,
        lon: location.longitude - 0.0026,
        priceLevel: 2,
        rating: 4.4,
        vegetarianFriendly: true,
        familyFriendly: true,
      ),
      _buildFallbackRestaurant(
        baseLocation: location,
        id: 'restaurant_pasta_point',
        name: 'Pasta Point',
        cuisine: 'Italian',
        lat: location.latitude + 0.0050,
        lon: location.longitude + 0.0015,
        priceLevel: 3,
        rating: 4.2,
        vegetarianFriendly: true,
        familyFriendly: true,
      ),
    ];

    return fallback;
  }

  static Restaurant _buildFallbackRestaurant({
    required LatLng baseLocation,
    required String id,
    required String name,
    required String cuisine,
    required double lat,
    required double lon,
    required int priceLevel,
    required double rating,
    required bool vegetarianFriendly,
    required bool familyFriendly,
  }) {
    final point = LatLng(lat, lon);
    final distanceKm = _distanceInKm(baseLocation, point);

    return Restaurant(
      id: id,
      name: name,
      point: point,
      cuisine: cuisine,
      priceLevel: priceLevel,
      rating: rating,
      distanceKm: distanceKm,
      travelMinutes: (distanceKm / 18 * 60).round(),
      vegetarianFriendly: vegetarianFriendly,
      familyFriendly: familyFriendly,
      details: [
        if (vegetarianFriendly) 'Vegetarian options',
        if (familyFriendly) 'Family friendly',
        'Popular in your area',
      ],
      summary: '$cuisine dining nearby',
    );
  }

  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition();
  }

  static LatLng fallbackLocation() => const LatLng(28.6139, 77.2090);

  static String _buildQuery(LatLng location) {
    return '''
      [out:json][timeout:25];
      (
        node["amenity"="restaurant"](around:2000,${location.latitude},${location.longitude});
        node["amenity"="fast_food"](around:2000,${location.latitude},${location.longitude});
        node["amenity"="cafe"](around:2000,${location.latitude},${location.longitude});
      );
      out center tags;
    ''';
  }

  static String _parseCuisine(Map<String, dynamic> tags) {
    final raw = (tags['cuisine'] ?? tags['cuisine:en'] ?? 'restaurant').toString();
    if (raw.isEmpty) return 'Multi-cuisine';
    final split = raw.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (split.isNotEmpty) {
      final first = split.first;
      return _titleCase(first.replaceAll('_', ' '));
    }
    return 'Multi-cuisine';
  }

  static int _parsePriceLevel(Map<String, dynamic> tags) {
    final tag = (tags['price'] ?? '').toString();
    if (tag.isEmpty) {
      final budget = (tags['budget'] ?? '').toString();
      if (budget.toLowerCase().contains('cheap')) return 1;
      if (budget.toLowerCase().contains('moderate')) return 2;
      if (budget.toLowerCase().contains('expensive')) return 3;
      return 2;
    }

    final lower = tag.toLowerCase();
    if (lower.contains('€€€') || lower.contains('premium')) return 3;
    if (lower.contains('€€') || lower.contains('mid') || lower.contains('standard')) return 2;
    return 1;
  }

  static double _estimateRating(Map<String, dynamic> tags) {
    final raw = (tags['rating'] ?? tags['stars'] ?? '').toString();
    final parsed = double.tryParse(raw);
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1.0, 5.0);
    }

    double score = 3.8;
    if (_isVegetarianFriendly(tags)) score += 0.3;
    if (_isFamilyFriendly(tags)) score += 0.2;
    if ((tags['amenity'] ?? '').toString() == 'cafe') score += 0.1;
    return score.clamp(3.0, 4.9);
  }

  static bool _isVegetarianFriendly(Map<String, dynamic> tags) {
    final cuisine = (tags['cuisine'] ?? '').toString().toLowerCase();
    final dietary = (tags['diet:vegetarian'] ?? tags['vegetarian'] ?? '').toString().toLowerCase();
    return cuisine.contains('vegetarian') ||
        cuisine.contains('vegan') ||
        dietary == 'only' ||
        dietary == 'yes';
  }

  static bool _isFamilyFriendly(Map<String, dynamic> tags) {
    final childFriendly = (tags['child_friendly'] ?? '').toString().toLowerCase();
    final familyFriendly = (tags['family'] ?? '').toString().toLowerCase();
    return childFriendly == 'yes' || familyFriendly == 'yes' || childFriendly == 'only';
  }

  static List<String> _extractDetails(Map<String, dynamic> tags) {
    final details = <String>[];

    if (_isVegetarianFriendly(tags)) {
      details.add('Vegetarian options');
    }
    if (_isFamilyFriendly(tags)) {
      details.add('Family friendly');
    }

    final takeaway = (tags['takeaway'] ?? '').toString();
    if (takeaway == 'yes') {
      details.add('Takeaway available');
    }

    final outdoor = (tags['outdoor_seating'] ?? '').toString();
    if (outdoor == 'yes') {
      details.add('Outdoor seating');
    }

    if (details.isEmpty) {
      details.add('Popular local pick');
    }

    return details;
  }

  static String _buildSummary(Map<String, dynamic> tags, String cuisine) {
    final people = (tags['capacity'] ?? '').toString();
    if (people.isNotEmpty) {
      return "$cuisine spot with room for groups";
    }
    return "$cuisine dining nearby";
  }

  static double _distanceInKm(LatLng start, LatLng end) {
    final distanceMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return (distanceMeters / 1000.0).clamp(0.1, 9999.0);
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return 'Multi-cuisine';
    return value.split(RegExp(r'[_\-\s]+')).map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}
