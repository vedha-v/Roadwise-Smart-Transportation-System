import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/explore_recommendation_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const LatLng _delhiCenter = LatLng(28.6329, 77.2195);

  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final ExploreRecommendationService _placesService =
      ExploreRecommendationService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ExplorePlace> _places = const [];
  ExplorePlace? _selectedPlace;
  String _selectedCategory = 'For you';

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final places = await _placesService.getNearbyPlaces(_delhiCenter);
      if (!mounted) return;
      setState(() {
        _places = places;
        _selectedPlace = places.isEmpty ? null : places.first;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<ExplorePlace> get _visiblePlaces {
    final query = _searchController.text.trim().toLowerCase();
    return _places.where((place) {
      final matchesCategory = switch (_selectedCategory) {
        'Restaurants' => place.category == ExplorePlaceCategory.restaurant,
        'Activities' => place.category == ExplorePlaceCategory.activity,
        'Restrooms' => place.category == ExplorePlaceCategory.restroom,
        _ => true,
      };
      final matchesQuery =
          query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.kind.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visiblePlaces = _visiblePlaces;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlaces,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _buildIntro(theme),
              const SizedBox(height: 16),
              _buildSearchBar(theme),
              const SizedBox(height: 12),
              _buildCategoryFilters(),
              const SizedBox(height: 16),
              _buildRecommendationHeader(theme),
              const SizedBox(height: 12),
              _buildMap(theme, visiblePlaces),
              const SizedBox(height: 12),
              _buildDataNotice(theme),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _buildErrorCard()
              else
                _buildPlacesList(theme, visiblePlaces),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Around Connaught Place',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Restaurants, local activities and public restrooms in New Delhi',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search restaurants or places',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    const categories = ['For you', 'Restaurants', 'Activities', 'Restrooms'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Recommended for you',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'LOCAL PICKS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMap(ThemeData theme, List<ExplorePlace> places) {
    final markers = <Marker>[
      Marker(
        point: _delhiCenter,
        width: 44,
        height: 44,
        child: const Icon(
          Icons.my_location_rounded,
          color: Color(0xFFFFA352),
          size: 30,
        ),
      ),
      for (final place in places)
        Marker(
          point: place.point,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlace = place),
            child: Icon(
              _iconFor(place.category),
              color: _colorFor(theme, place.category),
              size: 26,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 250,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _delhiCenter,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.roadwise.smarttransportation',
            ),
            MarkerLayer(markers: markers),
            if (_selectedPlace != null && places.contains(_selectedPlace))
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        '${_selectedPlace!.name} · ${_selectedPlace!.distanceKm.toStringAsFixed(1)} km',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Local recommendations are ranked by distance and OpenStreetMap tags. '
              'Restroom listings are mapped locations; live opening and usability '
              'are not verified.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 32),
            const SizedBox(height: 10),
            Text(_errorMessage ?? 'Could not load nearby places.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loadPlaces,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList(ThemeData theme, List<ExplorePlace> places) {
    if (places.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              const Text('No mapped places match this selection.'),
            ],
          ),
        ),
      );
    }

    final grouped = <ExplorePlaceCategory, List<ExplorePlace>>{
      ExplorePlaceCategory.restaurant: [],
      ExplorePlaceCategory.activity: [],
      ExplorePlaceCategory.restroom: [],
    };
    for (final place in places) {
      grouped[place.category]!.add(place);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCategory == 'For you') ...[
          for (final entry in grouped.entries)
            if (entry.value.isNotEmpty) ...[
              _buildSectionTitle(
                theme,
                _sectionTitle(entry.key),
                entry.value.length,
              ),
              const SizedBox(height: 8),
              for (final place in entry.value.take(
                entry.key == ExplorePlaceCategory.activity ? 4 : 6,
              ))
                _buildPlaceCard(theme, place),
              const SizedBox(height: 12),
            ],
        ] else ...[
          _buildSectionTitle(theme, _selectedCategory, places.length),
          const SizedBox(height: 8),
          for (final place in places.take(12)) _buildPlaceCard(theme, place),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text('$count nearby', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(ThemeData theme, ExplorePlace place) {
    final selected = _selectedPlace?.id == place.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() => _selectedPlace = place);
            _mapController.move(place.point, 16);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _iconFor(place.category),
                      color: _colorFor(theme, place.category),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${place.kind} · ${place.distanceKm.toStringAsFixed(1)} km away',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open directions',
                      onPressed: () => _openDirections(place),
                      icon: const Icon(Icons.directions_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _infoChip(theme, place.recommendationReason),
                    if (place.category == ExplorePlaceCategory.restroom)
                      ..._restroomDetails(theme, place),
                    if (place.category != ExplorePlaceCategory.restroom &&
                        place.hasOpeningHours == true)
                      _infoChip(theme, 'Hours listed'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _restroomDetails(ThemeData theme, ExplorePlace place) {
    return [
      _infoChip(
        theme,
        place.wheelchairAccessible == true
            ? 'Wheelchair accessible'
            : place.wheelchairAccessible == false
            ? 'Not wheelchair accessible'
            : 'Accessibility not listed',
      ),
      _infoChip(
        theme,
        place.hasOpeningHours == true ? 'Hours listed' : 'Hours not listed',
      ),
      if (place.feeRequired != null)
        _infoChip(
          theme,
          place.feeRequired! ? 'Fee may apply' : 'No fee listed',
        ),
    ];
  }

  Widget _infoChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }

  String _sectionTitle(ExplorePlaceCategory category) {
    return switch (category) {
      ExplorePlaceCategory.restaurant => 'Restaurants',
      ExplorePlaceCategory.activity => 'Things to do',
      ExplorePlaceCategory.restroom => 'Public restrooms',
    };
  }

  IconData _iconFor(ExplorePlaceCategory category) {
    return switch (category) {
      ExplorePlaceCategory.restaurant => Icons.restaurant_rounded,
      ExplorePlaceCategory.activity => Icons.local_activity_rounded,
      ExplorePlaceCategory.restroom => Icons.wc_rounded,
    };
  }

  Color _colorFor(ThemeData theme, ExplorePlaceCategory category) {
    return switch (category) {
      ExplorePlaceCategory.restaurant => theme.colorScheme.primary,
      ExplorePlaceCategory.activity => const Color(0xFF52B788),
      ExplorePlaceCategory.restroom => const Color(0xFF63A6E8),
    };
  }

  Future<void> _openDirections(ExplorePlace place) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.point.latitude},${place.point.longitude}',
      'travelmode': 'walking',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }
}
