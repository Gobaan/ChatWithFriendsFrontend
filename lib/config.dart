class AppConfig {
  static const String apiUrl =
      'https://chatwithfriendsmvp.azurewebsites.net/api/';
  static const String websiteUrl = 'http://localhost:63332/';
  static const String indexUrl = '${websiteUrl}#/';
  static const String negotiateUrl = '${apiUrl}negotiate';
  static const String apiKey = 'your_api_key_here';
  static const int maxItemsPerPage = 20;
  static const languageCode = {
    'French': 'fr',
    'Spanish': 'es',
    'English:': 'en',
    'Russian': 'rus'
  };
  // Add other constants as needed
}
