import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/news_service.dart';

class LocationPromptDialog extends StatefulWidget {
  const LocationPromptDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LocationPromptDialog(),
    );
    return result ?? false;
  }

  @override
  State<LocationPromptDialog> createState() => _LocationPromptDialogState();
}

class _LocationPromptDialogState extends State<LocationPromptDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _onAllow() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await LocationService.getCurrent();
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Tidak bisa mendapatkan lokasi. Periksa permission GPS.';
      });
      return;
    }
    final ok = await NewsService.updateLocation(
      latitude: data.latitude,
      longitude: data.longitude,
      countryCode: data.countryCode,
      city: data.city,
      enabled: true,
    );
    if (ok) {
      await LocationService.setEnabled(true);
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = 'Gagal menyimpan lokasi.';
      });
    }
  }

  void _onSkip() {
    LocationService.setEnabled(false);
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.location_on, size: 48, color: Colors.blue),
      title: const Text('Aktifkan Lokasi?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GotNews akan menampilkan berita lokal yang relevan dengan daerahmu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _onSkip,
          child: const Text('Nanti saja'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _onAllow,
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Izinkan'),
        ),
      ],
    );
  }
}