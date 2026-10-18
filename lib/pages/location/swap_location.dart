// Shared meeting-place data for Send Request and Reschedule.
// This is NOT the SwapLocation screen in locations.dart.
class SwapPlace {
  final String name;
  final String area;
  final String mapUrl;

  const SwapPlace({
    required this.name,
    required this.area,
    required this.mapUrl,
  });
}

const List<SwapPlace> swapLocations = [
  SwapPlace(
    name: 'Tivoli Dome',
    area: 'Sidi Gaber, Alexandria',
    mapUrl: 'https://www.google.com/maps/search/?api=1&query=Tivoli+Dome+Alexandria',
  ),
  SwapPlace(
    name: 'San Stefano Mall',
    area: 'San Stefano, Alexandria',
    mapUrl: 'https://www.google.com/maps/search/?api=1&query=San+Stefano+Grand+Plaza+Mall+Alexandria',
  ),
  SwapPlace(
    name: 'Green Plaza Mall',
    area: 'Smouha, Alexandria',
    mapUrl: 'https://www.google.com/maps/search/?api=1&query=Green+Plaza+Mall+Alexandria',
  ),
  SwapPlace(
    name: 'City Centre Alexandria',
    area: 'Alexandria-Cairo Desert Road',
    mapUrl: 'https://www.google.com/maps/search/?api=1&query=City+Centre+Alexandria+Egypt',
  ),
  SwapPlace(
    name: 'Delices Patisserie',
    area: 'Raml Station, Alexandria',
    mapUrl: 'https://www.google.com/maps/search/?api=1&query=Delices+Patisserie+Alexandria',
  ),
];

SwapPlace findSwapLocation(String name) {
  return swapLocations.firstWhere(
    (place) => place.name == name,
    orElse: () => throw ArgumentError('Unknown swap location: $name'),
  );
}
