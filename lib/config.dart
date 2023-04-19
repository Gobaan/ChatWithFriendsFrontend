class AppConfig {
  static const String apiUrl =
      'https://chatwithfriendsmvp.azurewebsites.net/api/';
  //static const String apiUrl = 'http://localhost:7071/api/';
  static const String negotiateUrl = '${apiUrl}negotiate';
  static const int maxItemsPerPage = 20;
  static const languageCode = {
    'French': 'fr',
    'Spanish': 'es',
    'English:': 'en',
    'Russian': 'rus'
  };
  // Add other constants as needed
}
