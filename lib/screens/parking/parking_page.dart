//parking page
import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/parking_booking.dart';


// ============================================================
// MODEL
// ============================================================

class ParkingLot {
  final String name;
  final String distance;
  final int totalSlots;
  final String price;
  final Set<int> occupiedSlots;

  ParkingLot({
    required this.name,
    required this.distance,
    required this.totalSlots,
    required this.price,
    required this.occupiedSlots,
  });

  int get availableSlots => totalSlots - occupiedSlots.length;
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
  // Single source of truth for all parking lots.
  final List<ParkingLot> lots = [
    ParkingLot(
      name: 'City Centre Parking',
      distance: '0.4 km',
      totalSlots: 18,
      price: '₹40/hr',
      occupiedSlots: {3, 7, 12, 15},
    ),
    ParkingLot(
      name: 'Metro Plaza Parking',
      distance: '0.8 km',
      totalSlots: 7,
      price: '₹30/hr',
      occupiedSlots: {2, 5},
    ),
    ParkingLot(
      name: 'Central Mall Parking',
      distance: '1.2 km',
      totalSlots: 32,
      price: '₹50/hr',
      occupiedSlots: {1, 9, 20, 25, 30},
    ),
  ];

  Future<void> _openLot(ParkingLot lot) async {
    final reservedSlot = await Navigator.push<int?>(
      context,
      MaterialPageRoute(builder: (context) => ParkingSlotsPage(lot: lot)),
    );

    if (reservedSlot != null) {
      setState(() {
        lot.occupiedSlots.add(reservedSlot);
      });
    }
  }

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
              child: ListView.separated(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PARKING CARD
// ============================================================

class ParkingCard extends StatelessWidget {
  final ParkingLot lot;
  final VoidCallback onTap;

  const ParkingCard({super.key, required this.lot, required this.onTap});

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

          child: Padding(
            padding: const EdgeInsets.all(18),

            child: Row(
              children: [
                // ------------------------------------------------
                // PARKING ICON
                // ------------------------------------------------

                Container(
                  width: 58,
                  height: 58,

                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ------------------------------------------------
                // PARKING DETAILS
                // ------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        '${lot.distance} away',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '${lot.availableSlots} slots available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'View available slots →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ------------------------------------------------
                // PRICE
                // ------------------------------------------------

                Text(
                  lot.price,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PARKING SLOTS PAGE
// ============================================================

class ParkingSlotsPage extends StatefulWidget {
  final ParkingLot lot;

  const ParkingSlotsPage({super.key, required this.lot});

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  int? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final lot = widget.lot;
    final availableCount = lot.availableSlots;

    // Adaptive colors for slot states.
    final availableBackground = Color.lerp(
      colors.surface,
      Colors.green,
      0.14,
    )!;

    final availableBorder = Colors.green.shade600;

    final occupiedBackground = colors.surfaceContainerHighest;
    final occupiedBorder = colors.outline;

    final selectedBackground = colors.primary;
    final selectedBorder = colors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lot.name,
          style: const TextStyle(
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
                color: colors.primary.withValues(alpha: 0.12),
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
                    style: theme.textTheme.titleMedium?.copyWith(
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
                      lot.occupiedSlots.contains(slotNumber);

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
                      duration: const Duration(milliseconds: 180),

                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),

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
                  color: colors.primary.withValues(alpha: 0.12),
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
              ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // RESERVE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: selectedSlot == null
                    ? null
                    : () => _showReservationDialog(lot),

                child: Text(
                  selectedSlot == null
                      ? 'Select a Slot'
                      : 'Reserve Slot $selectedSlot',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  

  // ==========================================================
  // RESERVATION DIALOG
  // ==========================================================

  void _showReservationDialog(ParkingLot lot) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Parking Reserved'),

          content: Text(
            'Slot $selectedSlot at ${lot.name} has been reserved.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, selectedSlot);
              },

              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _ticketRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 5),

        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}