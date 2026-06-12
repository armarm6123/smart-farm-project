class AppConfig {
  // ตอนพัฒนา (Local)
  //static const String baseUrl = "http://10.0.2.2/project/api";
  //static const String baseUrl = "http://localhost/project/api";
  //static const String baseUrl = "http://192.168.1.51/project/api";
  static const String baseUrl = "http://172.20.10.4/project/api";

  // ตอนใช้งานจริง (Public) - แค่คอมเมนต์บรรทัดบนแล้วเปิดบรรทัดนี้
  // static const String baseUrl = "https://www.yourdomain.com/api";

  // สร้างฟังก์ชันช่วยสร้าง Path สำหรับ Admin
  static String adminUrl(String fileName) => "$baseUrl/admin/$fileName";

  // สร้างฟังก์ชันช่วยสร้าง Path สำหรับ API ทั่วไป
  static String apiUrl(String fileName) => "$baseUrl/$fileName";
}
