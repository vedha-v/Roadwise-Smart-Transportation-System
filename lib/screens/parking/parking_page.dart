import 'package:flutter/material.dart';

class ParkingPage extends StatelessWidget {
  const ParkingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Find a parking spot',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Find available parking near your destination.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  ParkingCard(
                    name: 'City Centre Parking',
                    distance: '0.4 km',
                    availableSlots: 18,
                    price: '₹40/hr',
                    onTap: () {
                      debugPrint('Tapped City Centre Parking');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ParkingSlotsPage(
                            parkingName: 'City Centre Parking',
                            totalSlots: 18,
                            price: '₹40/hr',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  ParkingCard(
                    name: 'Metro Plaza Parking',
                    distance: '0.8 km',
                    availableSlots: 7,
                    price: '₹30/hr',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ParkingSlotsPage(
                            parkingName: 'Metro Plaza Parking',
                            totalSlots: 7,
                            price: '₹30/hr',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  ParkingCard(
                    name: 'Central Mall Parking',
                    distance: '1.2 km',
                    availableSlots: 32,
                    price: '₹50/hr',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ParkingSlotsPage(
                            parkingName: 'Central Mall Parking',
                            totalSlots: 32,
                            price: '₹50/hr',
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
  final String name;
  final String distance;
  final int availableSlots;
  final String price;
  final VoidCallback onTap;

  const ParkingCard({
    super.key,
    required this.name,
    required this.distance,
    required this.availableSlots,
    required this.price,
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
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Parking icon
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

                // Parking information
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        '$distance away',
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '$availableSlots slots available',
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

                // Price
                Text(
                  price,
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
  final String parkingName;
  final int totalSlots;
  final String price;

  const ParkingSlotsPage({
    super.key,
    required this.parkingName,
    required this.totalSlots,
    required this.price,
  });

  @override
  State<ParkingSlotsPage> createState() =>
      _ParkingSlotsPageState();
}

class _ParkingSlotsPageState
    extends State<ParkingSlotsPage> {

  int? selectedSlot;

  // These slots are occupied.
  // The remaining slots will be available.
  final Set<int> occupiedSlots = {
    3,
    7,
    12,
    15,
  };

  @override
  Widget build(BuildContext context) {
    final availableCount =
        widget.totalSlots - occupiedSlots.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.parkingName,
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

            // Header
            Text(
              'Choose your parking slot',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$availableCount slots currently available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            // Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    color: Colors.blue,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '${widget.price} per hour',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Legend
            Row(
              children: [
                _LegendItem(
                  color: Colors.green,
                  text: 'Available',
                ),

                const SizedBox(width: 18),

                _LegendItem(
                  color: Colors.grey,
                  text: 'Occupied',
                ),

                const SizedBox(width: 18),

                _LegendItem(
                  color: Colors.blue,
                  text: 'Selected',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Parking slots
            Expanded(
              child: GridView.builder(
                itemCount: widget.totalSlots,
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
                      occupiedSlots.contains(slotNumber);

                  final isSelected =
                      selectedSlot == slotNumber;

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

                        borderRadius:
                            BorderRadius.circular(16),

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
                        mainAxisAlignment:
                            MainAxisAlignment.center,

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
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
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
                                  ? Colors.white
                                  : Colors.black54,
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

            // Selected slot
            if (selectedSlot != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
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

            // Reserve button
            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: selectedSlot == null
                    ? null
                    : () {
                        _showReservationDialog();
                      },

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

  void _showReservationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Parking Reserved',
          ),

          content: Text(
            'Slot $selectedSlot at '
            '${widget.parkingName} has been reserved.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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

        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}import 'package:flutter/material.dart';

class ParkingPage extends StatelessWidget {
  const ParkingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Find a parking spot',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Find available parking near your destination.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const _ParkingCard(
              name: 'City Centre Parking',
              distance: '0.4 km',
              availableSlots: 18,
              price: '₹40/hr',
            ),

            const SizedBox(height: 12),

            const _ParkingCard(
              name: 'Metro Plaza Parking',
              distance: '0.8 km',
              availableSlots: 7,
              price: '₹30/hr',
            ),

            const SizedBox(height: 12),

            const _ParkingCard(
              name: 'Central Mall Parking',
              distance: '1.2 km',
              availableSlots: 32,
              price: '₹50/hr',
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingCard extends StatelessWidget {
  final String name;
  final String distance;
  final int availableSlots;
  final String price;

  const _ParkingCard({
    required this.name,
    required this.distance,
    required this.availableSlots,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.local_parking,
              size: 40,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text('$distance away'),

                  const SizedBox(height: 4),

                  Text(
                    '$availableSlots slots available',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
