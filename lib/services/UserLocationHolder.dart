class UserLocationHolder {
  static double? latitude;
  static double? longitude;

  static void setLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }
}
