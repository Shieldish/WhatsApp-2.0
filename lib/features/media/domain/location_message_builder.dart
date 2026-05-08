/// Builds the payload for a location message.
///
/// Embeds GPS coordinates and a static map preview URL (OpenStreetMap) into
/// the message payload so recipients can see a map thumbnail inline.
///
/// Requirements: 6.5
class LocationMessageBuilder {
  LocationMessageBuilder._();

  /// Builds a location message payload map from [latitude] and [longitude].
  ///
  /// The [mapPreviewUrl] uses the OpenStreetMap static map service.
  static Map<String, dynamic> buildLocationPayload(
    double latitude,
    double longitude,
  ) {
    final mapPreviewUrl = _buildStaticMapUrl(latitude, longitude);

    return {
      'latitude': latitude,
      'longitude': longitude,
      'mapPreviewUrl': mapPreviewUrl,
    };
  }

  /// Returns a human-readable string representation of the coordinates.
  static String formatCoordinates(double latitude, double longitude) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}°$latDir, '
        '${longitude.abs().toStringAsFixed(4)}°$lngDir';
  }

  /// Builds an OpenStreetMap static map URL for the given coordinates.
  ///
  /// Uses the staticmap.openstreetmap.de service which provides a 300×200
  /// PNG image centred on the given coordinates with a marker.
  static String _buildStaticMapUrl(double lat, double lng) {
    final latStr = lat.toStringAsFixed(6);
    final lngStr = lng.toStringAsFixed(6);
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latStr,$lngStr'
        '&zoom=15'
        '&size=300x200'
        '&markers=$latStr,$lngStr,red-pushpin';
  }
}
