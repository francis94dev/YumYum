import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../feed/screens/feed_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng _userLocation = const LatLng(40.4168, -3.7038); // Default Madrid
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_userLocation, 14.0);
      }
    } catch (e) {
      // Ignore location error
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubre en tu zona'),
      ),
      body: productsAsync.when(
        data: (products) {
          final markers = products.map((p) => Marker(
            point: p.location,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(p.imageUrl),
                          ),
                          title: Text(p.title),
                          subtitle: Text(p.type == 'exchange' ? 'Intercambio' : '${p.price} €'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.pop();
                            context.push('/product/${p.id}');
                          },
                        )
                      ],
                    ),
                  )
                );
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
          )).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yumyum.app',
              ),
              MarkerLayer(markers: [
                ...markers,
                Marker(
                  point: _userLocation,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                )
              ]),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
