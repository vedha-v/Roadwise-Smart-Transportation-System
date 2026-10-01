import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/restaurant_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _currentLocation;
  List<Restaurant> _allRestaurants = const [];
  List<Restaurant> _recommended = const [];
  Restaurant? _selectedRestaurant;
  String _selectedCuisine = 'All';
  bool _vegetarianOnly = false;
  bool _familyFriendlyOnly = false;
  bool _showFilters = false;
  final int _groupSize = 2;
  double _maxDistanceKm = 5;
  double _minRating = 3.5;
  int _budgetLevel = 2;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Position? position = await RestaurantService.getCurrentPosition();
      final LatLng location = position != null
          ? LatLng(position.latitude, position.longitude)
          : RestaurantService.fallbackLocation();

      setState(() {
        _currentLocation = location;
      });

      final restaurants = await RestaurantService.searchNearbyRestaurants(
        location: location,
        query: _searchController.text.trim(),
        filter: RestaurantFilter(
          cuisine: _selectedCuisine == 'All' ? null : _selectedCuisine,
          vegetarianOnly: _vegetarianOnly,
          familyFriendlyOnly: _familyFriendlyOnly,
          minRating: _minRating,
          maxDistanceKm: _maxDistanceKm,
          maxPriceLevel: _budgetLevel,
        ),
      );

      final recommendations = RestaurantRecommendationEngine.recommend(
        restaurants,
        profile: RecommendationProfile(
          groupSize: _groupSize,
          preferredCuisine: _selectedCuisine == 'All' ? 'Any' : _selectedCuisine,
          budgetLevel: _budgetLevel,
          dietaryPreference: _vegetarianOnly ? 'Vegetarian' : 'Any',
          ratingPreference: _minRating,
          maxDistanceKm: _maxDistanceKm,
          familyFriendly: _familyFriendlyOnly || _groupSize > 2,
        ),
      );

      setState(() {
        _allRestaurants = restaurants;
        _recommended = recommendations.take(3).toList();
        _selectedRestaurant = _recommended.isNotEmpty ? _recommended.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load nearby restaurants right now.\n$e';
        _isLoading = false;
      });
    }
  }

  List<Restaurant> get _filteredRestaurants {
    final query = _searchController.text.trim().toLowerCase();
    final restaurants = _allRestaurants.where((restaurant) {
      final matchesQuery = query.isEmpty ||
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.cuisine.toLowerCase().contains(query) ||
          restaurant.summary.toLowerCase().contains(query);

      final matchesCuisine = _selectedCuisine == 'All' ||
          restaurant.cuisine.toLowerCase() == _selectedCuisine.toLowerCase();
      final matchesVegetarian = !_vegetarianOnly || restaurant.vegetarianFriendly;
      final matchesFamily = !_familyFriendlyOnly || restaurant.familyFriendly;
      final matchesRating = restaurant.rating >= _minRating;
      final matchesDistance = restaurant.distanceKm <= _maxDistanceKm;
      final matchesPrice = restaurant.priceLevel <= _budgetLevel;

      return matchesQuery &&
          matchesCuisine &&
          matchesVegetarian &&
          matchesFamily &&
          matchesRating &&
          matchesDistance &&
          matchesPrice;
    }).toList();

    restaurants.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return restaurants;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayRestaurants = _filteredRestaurants;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRestaurants,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
            children: [
              _buildSearchBar(theme),
              const SizedBox(height: 12),
              if (_showFilters) _buildFilterPanel(theme) else _buildQuickFilters(theme),
              const SizedBox(height: 12),
              _buildRecommendationHeader(theme),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _buildErrorCard()
              else ...[
                _buildMapCard(theme),
                const SizedBox(height: 20),
                _buildRestaurantList(displayRestaurants, theme),
              ],
            ],
          ),
        ),
      ),
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
        decoration: InputDecoration(
          hintText: 'Search restaurants or places',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme) {
    final cuisines = <String>['All', 'Indian', 'Chinese', 'Italian', 'North Indian', 'Vegetarian', 'Cafe'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cuisine in cuisines)
          ChoiceChip(
            label: Text(cuisine),
            selected: _selectedCuisine == cuisine,
            onSelected: (_) {
              setState(() {
                _selectedCuisine = cuisine;
              });
              _loadRestaurants();
            },
          ),
      ],
    );
  }

  Widget _buildFilterPanel(ThemeData theme) {
    final cuisines = <String>['All', 'Indian', 'Chinese', 'Italian', 'North Indian', 'Vegetarian', 'Cafe'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cuisine in cuisines)
                ChoiceChip(
                  label: Text(cuisine),
                  selected: _selectedCuisine == cuisine,
                  onSelected: (_) {
                    setState(() {
                      _selectedCuisine = cuisine;
                    });
                    _loadRestaurants();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('Veg only'),
                selected: _vegetarianOnly,
                onSelected: (_) {
                  setState(() {
                    _vegetarianOnly = !_vegetarianOnly;
                  });
                  _loadRestaurants();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Family friendly'),
                selected: _familyFriendlyOnly,
                onSelected: (_) {
                  setState(() {
                    _familyFriendlyOnly = !_familyFriendlyOnly;
                  });
                  _loadRestaurants();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRangeRow('Distance', _maxDistanceKm, 2, 20, (value) {
            setState(() => _maxDistanceKm = value);
            _loadRestaurants();
          }),
          const SizedBox(height: 8),
          _buildRangeRow('Rating', _minRating, 3.0, 5.0, (value) {
            setState(() => _minRating = value);
            _loadRestaurants();
          }),
          const SizedBox(height: 8),
          _buildBudgetRow(),
        ],
      ),
    );
  }

  Widget _buildRangeRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${value.toStringAsFixed(value >= 10 ? 0 : 1)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetRow() {
    return Row(
      children: [
        const Text('Budget', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Low')),
              ButtonSegment(value: 2, label: Text('Mid')),
              ButtonSegment(value: 3, label: Text('High')),
            ],
            selected: {_budgetLevel},
            onSelectionChanged: (selection) {
              setState(() => _budgetLevel = selection.first);
              _loadRestaurants();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationHeader(ThemeData theme) {
    return Row(
      children: [
        Text(
          'Recommended for you',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text('Group size $_groupSize', style: theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_off_rounded, size: 32),
            const SizedBox(height: 10),
            Text(_errorMessage ?? 'Could not load restaurants'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    final restaurants = _recommended.isNotEmpty ? _recommended : _filteredRestaurants;
    final center = _currentLocation ?? RestaurantService.fallbackLocation();
    final markers = <Marker>[];

    markers.add(
      Marker(
        point: center,
        width: 48,
        height: 48,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
      ),
    );

    for (final restaurant in restaurants) {
      markers.add(
        Marker(
          point: restaurant.point,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => setState(() => _selectedRestaurant = restaurant),
            child: const Icon(Icons.restaurant_rounded, color: Colors.deepOrange, size: 24),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.roadwise.smarttransportation',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantList(List<Restaurant> restaurants, ThemeData theme) {
    if (restaurants.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              const Text('No restaurants match your current filters.'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final restaurant in restaurants.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RestaurantCard(
              restaurant: restaurant,
              isSelected: _selectedRestaurant?.id == restaurant.id,
              onTap: () => setState(() => _selectedRestaurant = restaurant),
            ),
          ),
      ],
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isSelected;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final priceText = switch (restaurant.priceLevel) {
      1 => '₹',
      2 => '₹₹',
      3 => '₹₹₹',
      _ => '₹₹',
    };

    return Card(
      margin: EdgeInsets.zero,
      color: isSelected ? colors.primary.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${restaurant.cuisine} · $priceText · ${restaurant.distanceKm.toStringAsFixed(1)} km away',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(restaurant.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final detail in restaurant.details.take(3))
                    Chip(
                      label: Text(detail),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('${restaurant.travelMinutes} min away'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final destination = Uri.encodeComponent('${restaurant.point.latitude},${restaurant.point.longitude}');
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Get Directions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
