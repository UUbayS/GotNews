import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? countryCode;
  final String? city;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.countryCode,
    this.city,
  });
}

class LocationService {
  static const _kLat = 'loc_lat';
  static const _kLng = 'loc_lng';
  static const _kCountry = 'loc_country';
  static const _kCity = 'loc_city';
  static const _kEnabled = 'loc_enabled';

  static Future<LocationData?> getCurrent() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] location service disabled');
        return null;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          return null;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String? countryCode;
      String? city;
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          countryCode = p.isoCountryCode;
          city = p.locality ?? p.subAdministrativeArea;
        }
      } catch (e) {
        debugPrint('[LocationService] reverse geocode failed: $e');
      }

      final data = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        countryCode: countryCode,
        city: city,
      );
      await _saveToCache(data);
      return data;
    } catch (e) {
      debugPrint('[LocationService] getCurrent failed: $e');
      return null;
    }
  }

  static Future<LocationData?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    if (lat == null || lng == null) return null;
    return LocationData(
      latitude: lat,
      longitude: lng,
      countryCode: prefs.getString(_kCountry),
      city: prefs.getString(_kCity),
    );
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  static Future<void> _saveToCache(LocationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, data.latitude);
    await prefs.setDouble(_kLng, data.longitude);
    if (data.countryCode != null) await prefs.setString(_kCountry, data.countryCode!);
    if (data.city != null) await prefs.setString(_kCity, data.city!);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLat);
    await prefs.remove(_kLng);
    await prefs.remove(_kCountry);
    await prefs.remove(_kCity);
    await prefs.remove(_kEnabled);
  }
}