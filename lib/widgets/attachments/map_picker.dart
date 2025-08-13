import 'dart:async';
import 'dart:html' as html show window; // only for web guard
import 'package:js/js_util.dart' as js_util;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPicker extends StatefulWidget {
  final void Function(LatLng position)? onSend;
  const MapPicker({super.key, this.onSend});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _current;
  bool _loading = true;
  String _address = 'Неизвестный адрес';
  bool _webGoogleAvailable = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Check if google maps JS loaded
      final hasGoogle = js_util.hasProperty(html.window, 'google');
      _webGoogleAvailable = hasGoogle == true;
    }
    _init();
  }

  Future<void> _init() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        setState(() => _loading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _current = latLng;
        _loading = false;
        _address = 'Широта ${latLng.latitude.toStringAsFixed(5)}, Долгота ${latLng.longitude.toStringAsFixed(5)}';
      });
      if (!kIsWeb || _webGoogleAvailable) {
        final map = await _controller.future;
        await map.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = _loading
        ? const Center(child: CircularProgressIndicator())
        : (kIsWeb && !_webGoogleAvailable)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Для отображения карты на web нужен Google Maps JS ключ.\nДобавьте его в web/index.html (YOUR_GOOGLE_MAPS_API_KEY).',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(55.751244, 37.618423), zoom: 12),
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                onMapCreated: (c) => _controller.complete(c),
                markers: {
                  if (_current != null) Marker(markerId: const MarkerId('me'), position: _current!),
                },
              );

    return Stack(
      children: [
        Positioned.fill(child: mapWidget),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => widget.onSend?.call(_current ?? const LatLng(55.751244, 37.618423)),
                    child: const Text('Отправить место', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(_address, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 