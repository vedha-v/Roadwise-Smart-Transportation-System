import 'package:flutter/material.dart';

import '../../services/parking_api_service.dart';

class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final ParkingApiService _api = ParkingApiService();
  List<ParkingFacility> _facilities = [];
  bool _loading = true;
  String? _error;
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endsAt = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

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

  Future<void> _chooseTime(bool chooseStart) async {
    final current = chooseStart ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(DateTime.now()) ? DateTime.now() : current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final chosen = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (chooseStart) {
      if (!chosen.isAfter(DateTime.now()) || !chosen.isBefore(_endsAt)) {
        _showMessage(
          'Start time must be in the future and before the end time.',
        );
        return;
      }
      setState(() => _startsAt = chosen);
    } else {
      if (!chosen.isAfter(_startsAt) ||
          chosen.difference(_startsAt) > const Duration(hours: 24)) {
        _showMessage('End time must be after start time and within 24 hours.');
        return;
      }
      setState(() => _endsAt = chosen);
    }
  }

  Future<void> _openFacility(ParkingFacility facility) async {
    final reserved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingSlotsPage(
          facility: facility,
          startsAt: _startsAt,
          endsAt: _endsAt,
        ),
      ),
    );
    if (reserved == true) await _loadFacilities();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking near Delhi'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadFacilities,
            tooltip: 'Refresh parking',
            icon: const Icon(Icons.refresh),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _chooseTime(true),
                        icon: const Icon(Icons.login),
                        label: Text(
                          'From\n${_formatDateTime(_startsAt)}',
                          textAlign: TextAlign.left,
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
                  'Facility locations from OpenStreetMap. Bookable slots are listed only when verified by a facility or authorized provider.',
                  style: theme.textTheme.bodySmall,
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
  final ParkingFacility facility;
  final DateTime startsAt;
  final DateTime endsAt;

  const ParkingSlotsPage({
    super.key,
    required this.facility,
    required this.startsAt,
    required this.endsAt,
  });

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  final ParkingApiService _api = ParkingApiService();
  List<ParkingSlot> _slots = [];
  int? _selectedSlotId;
  bool _loading = true;
  bool _booking = false;
  String? _error;

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

  Future<void> _reserve() async {
    final slotId = _selectedSlotId;
    if (slotId == null) return;
    setState(() => _booking = true);
    try {
      await _api.createReservation(slotId, widget.startsAt, widget.endsAt);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _booking = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reservation failed: $error')));
      await _loadSlots();
    }
  }

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a verified slot',
                  style: theme.textTheme.titleLarge,
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

  Widget _buildSlots(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(
        message: 'Could not load slots.\n$_error',
        onRetry: _loadSlots,
      );
    }
    if (_slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No verified slots are available for this time range.'),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final selected = _selectedSlotId == slot.id;
        return OutlinedButton(
          onPressed: () => setState(() => _selectedSlotId = slot.id),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? theme.colorScheme.primary : null,
            foregroundColor: selected ? theme.colorScheme.onPrimary : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car),
              const SizedBox(height: 6),
              Text(slot.slotCode),
            ],
          ),
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MessageState({required this.message, required this.onRetry});

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
