class UserModel {
  final String username;
  final String role; // ค่า 'admin' หรือ 'user' จาก SQL ENUM

  UserModel({
    required this.username,
    required this.role,
  });

  // ฟังก์ชันแปลงข้อมูลจาก JSON (ที่ได้จาก API) มาเป็น Object ในแอป
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  // Getter เช็คสิทธิ์แบบง่ายๆ
  bool get isAdmin => role == 'admin';
}
