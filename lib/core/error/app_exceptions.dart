
class AppException implements Exception {
  final String message;
  final String title;

  AppException(this.message, this.title);

  @override
  String toString() => "$title: $message";
}



class NetworkException extends AppException {
  NetworkException([String message = "No internet connection. Please check your network."])
      : super(message, "Connection Error");
}



class ServerException extends AppException {
  ServerException([String message = "Server error occurred. Please try again later."])
      : super(message, "Server Error");
}



class AuthCustomException extends AppException {
  AuthCustomException(String message) : super(message, "Authentication Failed");
}
