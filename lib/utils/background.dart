String getImageForVehicle(String vehicle) {
  if (vehicle.contains('舞')) {
    return 'assets/images/maichan.jpg';
  }
  if (vehicle.contains('幸')) {
    return 'assets/images/sachichan.jpg';
  }
  return 'assets/images/maichan.jpg'; // デフォルト
}
