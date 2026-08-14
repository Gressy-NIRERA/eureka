
abstract class AfripayCredentialsProvider {
  Future<String> getClientToken();
  Future<String> getAppId();
  Future<String> getAppSecret();
}
class AppConfigAfripayCredentialsProvider implements AfripayCredentialsProvider {
  
  @override
  Future<String> getClientToken() async {
    throw UnimplementedError(
      'Branchez getClientToken() sur la configuration Afripay existante '
      'de l\'application (client_token).',
    );
  }

  @override
  Future<String> getAppId() async {
    throw UnimplementedError(
      'Branchez getAppId() sur la configuration Afripay existante '
      'de l\'application (app_id).',
    );
  }

  @override
  Future<String> getAppSecret() async {
    throw UnimplementedError(
      'Branchez getAppSecret() sur la configuration Afripay existante '
      'de l\'application (app_secret). Voir la note de sécurité en tête '
      'de ce fichier avant la mise en production.',
    );
  }
}