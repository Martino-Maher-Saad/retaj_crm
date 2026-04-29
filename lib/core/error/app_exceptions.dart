
class AppException implements Exception {
  final String message;
  final String title;

  AppException(this.message, this.title);

  @override
  String toString() => "$title: $message";
}



class NetworkException extends AppException {
  NetworkException([String message = "لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة."])
      : super(message, "خطأ في الاتصال");
}

class ServerException extends AppException {
  ServerException([String message = "حدث خطأ في الخادم. يرجى المحاولة لاحقاً."])
      : super(message, "خطأ في الخادم");
}

class AuthCustomException extends AppException {
  AuthCustomException(String message) : super(message, "فشل المصادقة");
}
