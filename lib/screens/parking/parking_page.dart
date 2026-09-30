import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/booking_service.dart';

// ============================================================
// BACKEND CONFIGURATION
// ============================================================

// Android emulator -> host Mac
const String _backendBaseUrl = 'http://10.0.2.2:3000/api';

// ============================================================
// MODEL
// ============================================================

class ParkingLot {
  final int id;
  final String name;
  final String location;
  final String distance;
  final int totalSlots;
  final int backendAvailableSlots;
  final String price;
  final Set<int> occupiedSlots;

  ParkingLot({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.totalSlots,
    required this.backendAvailableSlots,
    required this.price,
    required this.occupiedSlots,
  });

  int get availableSlots => totalSlots - occupiedSlots.length;

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final totalSlots = (json['totalSlots'] as num).toInt();
    final availableSlots = (json['availableSlots'] as num).toInt();

    final occupiedCount =
        (totalSlots - availableSlots).clamp(0, totalSlots);

    // The current backend gives us the number of unavailable slots,
    // but not their individual IDs.
    //
    // Until the backend exposes individual slot IDs, we represent
    // those unavailable slots using the first N slot numbers.
    final occupiedSlots = <int>{
      for (int i = 1; i <= occupiedCount; i++) i,
    };

    return ParkingLot(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      location: json['location'] as String,
      distance: json['distance'] as String,
      totalSlots: totalSlots,
      backendAvailableSlots: availableSlots,
      price: '₹${json['pricePerHour']}/hr',
      occupiedSlots: occupiedSlots,
    );
  }
}

// ============================================================
// PARKING PAGE
// ============================================================

class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  List<ParkingLot> lots = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParkingLots();
  }

  // ============================================================
  // LOAD PARKING DATA FROM BACKEND
  // ============================================================

  Future<void> _loadParkingLots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = HttpClient();

      final request = await client.getUrl(
        Uri.parse('$_backendBaseUrl/parking'),
      );

      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Backend returned status ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      final parkingData =
          decoded['parkingSlots'] as List<dynamic>;

      final loadedLots = parkingData
          .map(
            (item) => ParkingLot.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        lots = loadedLots;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not connect to the RoadWise backend.';
      });
    }
  }

  // ============================================================
  // OPEN PARKING LOT
  // ============================================================

  Future<void> _openLot(ParkingLot lot) async {
    final reservedSlot = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingSlotsPage(lot: lot),
      ),
    );

  Future<void> _loadFacilities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final facilities = await _api.getNearbyParking();
      if (!mounted) return;
      setState(() {
        _facilities = facilities;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Parking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Text(
              'Find a parking spot',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Find available parking near your destination.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // SEARCH
            // --------------------------------------------------

            TextField(
              decoration: InputDecoration(
                hintText: 'Search location',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // NEARBY PARKING
            // --------------------------------------------------

            Text(
              'Nearby parking',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _buildParkingContent(),
            ),
          ],
        ),
      ),
    );
    if (reserved == true) await _loadFacilities();
  }

  // ============================================================
  // PARKING CONTENT
  // ============================================================

  Widget _buildParkingContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 52,
              ),

              const SizedBox(height: 16),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _loadParkingLots,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (lots.isEmpty) {
      return const Center(
        child: Text('No parking locations available.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadParkingLots,

      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

        itemCount: lots.length,

        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final lot = lots[index];

          return ParkingCard(
            lot: lot,
            onTap: () => _openLot(lot),
          );
        },
      ),
    );
  }
}

// ============================================================
// PARKING CARD
// ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  const ParkingCard({
    super.key,
    required this.lot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: colors.outlineVariant,
            ),

            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connaught Place, New Delhi',
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(width: 16),

                // ------------------------------------------------
                // PARKING DETAILS
                // ------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        lot.name,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        lot.location,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '${lot.distance} away',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '${lot.availableSlots} slots available',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _chooseTime(false),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          'Until\n${_formatDateTime(_endsAt)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lot.price,
                  style:
                      theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildFacilityList(theme)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Map data © OpenStreetMap contributors',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityList(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(
        message: 'Could not load nearby parking.\n$_error',
        onRetry: _loadFacilities,
      );
    }
    if (_facilities.isEmpty) {
      return _MessageState(
        message: 'No parking facilities were found in the OpenStreetMap search area.',
        onRetry: _loadFacilities,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFacilities,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _facilities.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final facility = _facilities[index];
          final hasSlots = facility.verifiedSlotCount > 0;
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_parking)),
              title: Text(
                facility.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${facility.distanceKm.toStringAsFixed(1)} km away\n'
                '${facility.isDemo ? 'DEMO ONLY - not a real parking facility\n' : ''}'
                '${hasSlots ? '${facility.verifiedSlotCount} ${facility.isDemo ? 'sample' : 'verified'} slots' : 'No verified slot inventory'}',
              ),
              isThreeLine: true,
              trailing: Icon(
                hasSlots ? Icons.chevron_right : Icons.lock_outline,
              ),
              enabled: hasSlots,
              onTap: hasSlots ? () => _openFacility(facility) : null,
            ),
          );
        },
      ),
    );
  }
}

class ParkingSlotsPage extends StatefulWidget {
  final ParkingLot lot;

  const ParkingSlotsPage({
    super.key,
    required this.lot,
  });

  @override
  State<ParkingSlotsPage> createState() =>
      _ParkingSlotsPageState();
}

class _ParkingSlotsPageState
    extends State<ParkingSlotsPage> {
  int? selectedSlot;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slots = await _api.getAvailableSlots(
        widget.facility,
        widget.startsAt,
        widget.endsAt,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _selectedSlotId = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

    final occupiedBackground =
        colors.surfaceContainerHighest;

    final occupiedBorder = colors.outline;

  String _time(DateTime value) => value.toLocal().toString().substring(0, 16);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.facility.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Text(
              'Choose your parking slot',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$availableCount slots currently available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // PRICE
            // --------------------------------------------------

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: colors.primary.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    color: colors.primary,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '${lot.price} per hour',
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // LEGEND
            // --------------------------------------------------

            Row(
              children: [
                _LegendItem(
                  color: Colors.green.shade600,
                  text: 'Available',
                ),

                const SizedBox(width: 18),

                _LegendItem(
                  color: colors.outline,
                  text: 'Occupied',
                ),

                const SizedBox(width: 18),

                _LegendItem(
                  color: colors.primary,
                  text: 'Selected',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SLOTS
            // --------------------------------------------------

            Expanded(
              child: GridView.builder(
                itemCount: lot.totalSlots,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),

                itemBuilder: (context, index) {
                  final slotNumber = index + 1;

                  final isOccupied =
                      lot.occupiedSlots.contains(
                    slotNumber,
                  );

                  final isSelected =
                      selectedSlot == slotNumber;

                  Color backgroundColor;
                  Color borderColor;
                  Color iconColor;
                  Color textColor;

                  if (isOccupied) {
                    backgroundColor = occupiedBackground;
                    borderColor = occupiedBorder;
                    iconColor = colors.onSurfaceVariant;
                    textColor = colors.onSurfaceVariant;
                  } else if (isSelected) {
                    backgroundColor = selectedBackground;
                    borderColor = selectedBorder;
                    iconColor = colors.onPrimary;
                    textColor = colors.onPrimary;
                  } else {
                    backgroundColor = availableBackground;
                    borderColor = availableBorder;
                    iconColor = Colors.green.shade700;
                    textColor = colors.onSurface;
                  }

                  return GestureDetector(
                    onTap: isOccupied
                        ? null
                        : () {
                            setState(() {
                              selectedSlot = slotNumber;
                            });
                          },

                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),

                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius:
                            BorderRadius.circular(16),

                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                      ),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 30,
                            color: iconColor,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Slot $slotNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            isOccupied
                                ? 'Occupied'
                                : isSelected
                                    ? 'Selected'
                                    : 'Available',

                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? colors.onPrimary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // SELECTED SLOT MESSAGE
            // --------------------------------------------------

            if (selectedSlot != null)
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colors.primary,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Slot $selectedSlot selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${_time(widget.startsAt)} to ${_time(widget.endsAt)}'),
                if (widget.facility.isDemo) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'DEMO ONLY: this facility and its sample slots are fictional.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Availability is checked again when you reserve.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(child: _buildSlots(theme)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selectedSlotId == null || _booking ? null : _reserve,
          icon: _booking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.event_available),
          label: Text(_booking ? 'Reserving...' : 'Reserve selected slot'),
        ),
      ),
    );
  }

  // ==========================================================
  // RESERVATION DIALOG
  // ==========================================================

    Future<void> _showReservationDialog(ParkingLot lot) async {
    if (selectedSlot == null) return;

    final slot = selectedSlot!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Reservation'),
          content: Text(
            'Reserve Slot $slot at ${lot.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                final booking = await BookingService.createBooking(
                  userId: 1,
                  parkingName: lot.name,
                  slot: 'Slot $slot',
                  duration: 1,
                  price: lot.price,
                  distance: lot.distance,
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (booking != null) {
                  Navigator.pop(context, slot);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Booking ${booking.bookingId} confirmed!',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not create booking. Please try again.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// LEGEND ITEM
// ============================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
