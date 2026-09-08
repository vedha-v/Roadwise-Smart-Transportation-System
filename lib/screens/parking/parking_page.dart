import 'package:flutter/material.dart';

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
// PARKING PAGE (now stateful — holds the source of truth)
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
    // Wait for the slots page to return the slot number that was reserved
    // (or null if the user backed out without reserving).
    final reservedSlot = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingSlotsPage(lot: lot),
      ),
    );

    if (reservedSlot != null) {
      setState(() {
        lot.occupiedSlots.add(reservedSlot);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Parking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find a parking spot',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Find available parking near your destination.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search location',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nearby parking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: lots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
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

  const ParkingCard({
    super.key,
    required this.lot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(

                color: Colors.black.withValues(alpha: 0.08),
                 blurRadius: 4,
                offset: const Offset(0, 2),
               
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${lot.distance} away',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${lot.availableSlots} slots available',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'View available slots →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  lot.price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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

  const ParkingSlotsPage({
    super.key,
    required this.lot,
  });

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  int? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final availableCount = lot.availableSlots;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lot.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your parking slot',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$availableCount slots currently available',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${lot.price} per hour',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                _LegendItem(color: Colors.green, text: 'Available'),
                SizedBox(width: 18),
                _LegendItem(color: Colors.grey, text: 'Occupied'),
                SizedBox(width: 18),
                _LegendItem(color: Colors.blue, text: 'Selected'),
              ],
            ),
            const SizedBox(height: 20),
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
                  final isOccupied = lot.occupiedSlots.contains(slotNumber);
                  final isSelected = selectedSlot == slotNumber;

                  return GestureDetector(
                    onTap: isOccupied
                        ? null
                        : () {
                      setState(() {
                        selectedSlot = slotNumber;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOccupied
                            ? Colors.grey.shade300
                            : isSelected
                            ? Colors.blue
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOccupied
                              ? Colors.grey.shade400
                              : isSelected
                              ? Colors.blue
                              : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 30,
                            color: isOccupied
                                ? Colors.grey.shade600
                                : isSelected
                                ? Colors.white
                                : Colors.green.shade700,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Slot $slotNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? Colors.white : Colors.black87,
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
                              color: isSelected ? Colors.white : Colors.black54,
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
            if (selectedSlot != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Slot $selectedSlot selected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                Navigator.pop(context); // close dialog
                Navigator.pop(context, selectedSlot); // go back to list, send reserved slot
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// LEGEND
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
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
