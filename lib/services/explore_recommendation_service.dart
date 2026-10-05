import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum ExplorePlaceCategory { restaurant, activity, restroom }

class ExplorePlace {
  final String id;
  final String name;
  final String kind;
  final ExplorePlaceCategory category;
  final LatLng point;
  final double distanceKm;
  final double recommendationScore;
  final String recommendationReason;
  final bool? wheelchairAccessible;
  final bool? hasOpeningHours;
  final String? access;
  final bool? feeRequired;

  const ExplorePlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.category,
    required this.point,
    required this.distanceKm,
    required this.recommendationScore,
    required this.recommendationReason,
    required this.wheelchairAccessible,
    required this.hasOpeningHours,
    required this.access,
    required this.feeRequired,
  });
}

class ExploreRecommendationService {
  static const _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];
  // Keep the response small enough for Overpass to serve reliably in dense areas.
  static const _radiusMeters = 1500;

  Future<List<ExplorePlace>> getNearbyPlaces(LatLng center) async {
    final query = _buildQuery(center);
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'RoadWise/1.0 (nearby recommendations)',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode != 200) {
          debugPrint(
            'Explore Overpass request failed ($endpoint): '
            'HTTP ${response.statusCode} ${response.body.length > 250 ? response.body.substring(0, 250) : response.body}',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic> ||
            decoded['elements'] is! List<dynamic>) {
          throw const FormatException(
            'OpenStreetMap returned an invalid nearby places response.',
          );
        }

        final places = <ExplorePlace>[];
        for (final element in decoded['elements'] as List<dynamic>) {
          if (element is! Map<String, dynamic>) continue;
          final place = _parsePlace(element, center);
          if (place != null) places.add(place);
        }
        places.sort(
          (first, second) =>
              second.recommendationScore.compareTo(first.recommendationScore),
        );
        return places;
      } catch (error) {
        debugPrint('Explore Overpass request failed ($endpoint): $error');
      }
    }

    throw Exception(
      'Nearby places are taking too long to load. Check your connection and try again.',
    );
  }

  static List<ExplorePlace> rankPlaces(Iterable<ExplorePlace> places) {
    final ranked = places.toList()
      ..sort(
        (first, second) =>
            second.recommendationScore.compareTo(first.recommendationScore),
      );
    return ranked;
  }

  static ExplorePlace? _parsePlace(
    Map<String, dynamic> element,
    LatLng center,
  ) {
    final tags = element['tags'];
    if (tags is! Map<String, dynamic>) return null;
    final coordinates = element['center'] is Map<String, dynamic>
        ? element['center'] as Map<String, dynamic>
        : element;
    final latitude = (coordinates['lat'] as num?)?.toDouble();
    final longitude = (coordinates['lon'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final amenity = tags['amenity']?.toString();
    final leisure = tags['leisure']?.toString();
    final tourism = tags['tourism']?.toString();
    final historic = tags['historic']?.toString();
    final category = _categoryFor(amenity, leisure, tourism, historic);
    if (category == null) return null;

    final access = tags['access']?.toString().toLowerCase();
    if (category == ExplorePlaceCategory.restroom &&
        const {'private', 'customers', 'no'}.contains(access)) {
      return null;
    }

    final point = LatLng(latitude, longitude);
    final distanceKm =
        Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          latitude,
          longitude,
        ) /
        1000;
    final kind = _kindFor(amenity, leisure, tourism, historic);
    final name = (tags['name'] ?? tags['name:en'])?.toString().trim();
    final displayName = name == null || name.isEmpty ? _titleCase(kind) : name;
    final wheelchair = _yesNo(tags['wheelchair'] ?? tags['toilets:wheelchair']);
    final openingHours = tags['opening_hours']?.toString().trim().isNotEmpty;
    final fee = _yesNo(tags['fee']) ?? _feeFromCharge(tags['charge']);
    final score = _score(
      category: category,
      distanceKm: distanceKm,
      isNamed: name != null && name.isNotEmpty,
      hasOpeningHours: openingHours == true,
      wheelchairAccessible: wheelchair,
      access: access,
    );

    return ExplorePlace(
      id: '${element['type']}/${element['id']}',
      name: displayName,
      kind: kind,
      category: category,
      point: point,
      distanceKm: distanceKm,
      recommendationScore: score,
      recommendationReason: _recommendationReason(
        category: category,
        distanceKm: distanceKm,
        hasOpeningHours: openingHours == true,
        wheelchairAccessible: wheelchair,
        access: access,
      ),
      wheelchairAccessible: wheelchair,
      hasOpeningHours: openingHours,
      access: access,
      feeRequired: fee,
    );
  }

  static ExplorePlaceCategory? _categoryFor(
    String? amenity,
    String? leisure,
    String? tourism,
    String? historic,
  ) {
    if (amenity == 'restaurant' ||
        amenity == 'cafe' ||
        amenity == 'fast_food') {
      return ExplorePlaceCategory.restaurant;
    }
    if (amenity == 'toilets') return ExplorePlaceCategory.restroom;
    if (const {'park', 'garden', 'playground'}.contains(leisure) ||
        const {
          'museum',
          'gallery',
          'attraction',
          'zoo',
          'viewpoint',
        }.contains(tourism) ||
        const {
          'cinema',
          'theatre',
          'arts_centre',
          'community_centre',
        }.contains(amenity) ||
        const {'memorial', 'monument', 'castle', 'ruins'}.contains(historic)) {
      return ExplorePlaceCategory.activity;
    }
    return null;
  }

  static String _kindFor(
    String? amenity,
    String? leisure,
    String? tourism,
    String? historic,
  ) {
    if (amenity == 'restaurant') return 'Restaurant';
    if (amenity == 'cafe') return 'Cafe';
    if (amenity == 'fast_food') return 'Quick bite';
    if (amenity == 'toilets') return 'Public restroom';
    return leisure ?? tourism ?? amenity ?? historic ?? 'Nearby place';
  }

  static double _score({
    required ExplorePlaceCategory category,
    required double distanceKm,
    required bool isNamed,
    required bool hasOpeningHours,
    required bool? wheelchairAccessible,
    required String? access,
  }) {
    var score = 100 - distanceKm * 9;
    if (isNamed) score += 8;
    if (hasOpeningHours) score += 5;
    if (wheelchairAccessible == true) score += 5;
    if (category == ExplorePlaceCategory.restroom &&
        (access == 'yes' || access == 'public')) {
      score += 8;
    }
    return score;
  }

  static String _recommendationReason({
    required ExplorePlaceCategory category,
    required double distanceKm,
    required bool hasOpeningHours,
    required bool? wheelchairAccessible,
    required String? access,
  }) {
    if (category == ExplorePlaceCategory.restroom &&
        (access == 'yes' || access == 'public')) {
      return 'Mapped as public access';
    }
    if (wheelchairAccessible == true) return 'Wheelchair access is mapped';
    if (hasOpeningHours) return 'Opening hours are listed';
    if (distanceKm < 1) return 'One of the closest options';
    return 'Nearby on OpenStreetMap';
  }

  static bool? _yesNo(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'yes' || 'designated' || 'permissive' => true,
      'no' => false,
      _ => null,
    };
  }

  static bool? _feeFromCharge(Object? value) {
    final charge = value?.toString().trim();
    if (charge == null || charge.isEmpty) return null;
    return charge.toLowerCase() != 'no';
  }

  static String _titleCase(String value) {
    return value
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static String _buildQuery(LatLng center) {
    final latitude = center.latitude;
    final longitude = center.longitude;
    return '''
      [out:json][timeout:20];
      (
        nwr(around:$_radiusMeters,$latitude,$longitude)["amenity"~"^(restaurant|cafe|fast_food|toilets|cinema|theatre|arts_centre|community_centre)\$"];
        nwr(around:$_radiusMeters,$latitude,$longitude)["leisure"~"^(park|garden|playground)\$"];
        nwr(around:$_radiusMeters,$latitude,$longitude)["tourism"~"^(museum|gallery|attraction|zoo|viewpoint)\$"];
      );
      out center tags;
    ''';
  }
}
