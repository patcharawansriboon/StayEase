import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<String>? onSelectAddress;

  const MapScreen({super.key, this.onBack, this.onSelectAddress});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(13.7563, 100.5018);
  String _mainAddress = 'กำลังโหลดตำแหน่ง...';
  String _detailAddress = '';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _mainAddress = 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _mainAddress = 'กรุณาเปิดสิทธิ์ตำแหน่งในการตั้งค่า';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latlng = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = latlng;
        _isLoadingLocation = false;
      });

      _mapController.move(latlng, 16);
      await _reverseGeocode(latlng);
    } catch (e) {
      setState(() {
        _mainAddress = 'ไม่สามารถดึงตำแหน่งได้';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${point.latitude}'
        '&lon=${point.longitude}'
        '&accept-language=th',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'StayMateApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final displayName = data['display_name'] as String? ?? '';

        // บรรทัดหลัก: ชื่อถนน หรือ plus code
        final road = address['road'] ?? address['pedestrian'] ?? '';
        final houseNumber = address['house_number'] ?? '';
        final main = houseNumber.isNotEmpty && road.isNotEmpty
            ? '$road $houseNumber'
            : road.isNotEmpty
                ? road
                : displayName.split(',').first.trim();

        // บรรทัดละเอียด: ย่าน, เขต, จังหวัด
        final parts = <String>[];
        if (address['suburb'] != null) parts.add(address['suburb']);
        if (address['district'] != null) parts.add(address['district']);
        if (address['city'] != null) {
          parts.add(address['city']);
        } else if (address['town'] != null) {
          parts.add(address['town']);
        } else if (address['county'] != null) {
          parts.add(address['county']);
        }
        if (address['postcode'] != null) parts.add(address['postcode']);

        setState(() {
          _mainAddress = main.isNotEmpty ? main : 'ตำแหน่งที่เลือก';
          _detailAddress = parts.join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _mainAddress =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _detailAddress = '';
      });
    }
  }

  String get _currentAddressText =>
      _searchController.text.isNotEmpty
          ? _searchController.text
          : _mainAddress;

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _mainAddress = 'กำลังค้นหา...';
      _detailAddress = '';
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&limit=1'
        '&accept-language=th',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'StayMateApp/1.0',
      });
      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat'] as String);
          final lon = double.parse(results[0]['lon'] as String);
          final latlng = LatLng(lat, lon);
          setState(() {
            _center = latlng;
            _isLoadingLocation = false;
          });
          _mapController.move(latlng, 14);
          await _reverseGeocode(latlng);
          _searchController.clear();
          setState(() {});
        } else {
          setState(() {
            _mainAddress = 'ไม่พบตำแหน่ง';
            _detailAddress = '';
          });
        }
      }
    } catch (_) {
      setState(() {
        _mainAddress = 'ค้นหาไม่สำเร็จ';
        _detailAddress = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map (full screen)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 14,
                onTap: (tapPosition, point) async {
                  setState(() {
                    _center = point;
                    _mainAddress = 'กำลังโหลดที่อยู่...';
                    _detailAddress = '';
                  });
                  await _reverseGeocode(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.stay_mate',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF78A2D2),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(Icons.chevron_left,
                        size: 24, color: Color(0xFF000000)),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'ที่อยู่',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.18,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        children: [
                          // Search bar
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: () => _searchAddress(_searchController.text),
                                  child: const Icon(Icons.search,
                                      size: 20, color: Color(0xFFAAAAAA)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: _searchAddress,
                                    textInputAction: TextInputAction.search,
                                    style: const TextStyle(
                                        fontFamily: 'Prompt', fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'ค้นหาที่อยู่',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Prompt',
                                        fontSize: 13,
                                        color: Color(0xFFAAAAAA),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Result card
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE8E8E8)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _isLoadingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF78A2D2),
                                        ),
                                      )
                                    : const Icon(Icons.location_on_outlined,
                                        size: 22,
                                        color: Color(0xFF78A2D2)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentAddressText,
                                        style: const TextStyle(
                                          fontFamily: 'Prompt',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                      if (_detailAddress.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _detailAddress,
                                          style: const TextStyle(
                                            fontFamily: 'Prompt',
                                            fontSize: 12,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.near_me_outlined,
                                    size: 18, color: Color(0xFFAAAAAA)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ปุ่มเลือก
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onSelectAddress?.call(_currentAddressText);
                            widget.onBack?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF78A2D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'เลือก',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
