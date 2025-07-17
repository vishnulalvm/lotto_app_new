class ApiConstants {
// This class contains the API endpoints used in the application.
// back up  base URL in case the server error occurs

  static const String backUpUrl = 'https://sea-lion-app-begbw.ondigitalocean.app/api';
  static const String baseUrl =
      'https://api.lottokeralalotteries.com/api';

// This is the main endpoint for all API requests.
  static const String login = '/users/login/';
  static const String register = '/users/register/';
  static const String homeResults = '/results/results/';
  static const String resultDetails = '/results/get-by-unique-id/';
  static const String news = '/results/news/';
  static const String predict = '/results/predict/';
  static const String liveVideos = '/results/live-videos/';
  static const String lotteryPercentage = '/results/lottery-percentage/';
  static const String fcmRegister = '/users/fcm/register/';
}
