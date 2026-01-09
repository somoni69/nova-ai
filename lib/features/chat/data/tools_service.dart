import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolsService {
  // 🔦 Фонарик
  Future<void> toggleFlashlight(bool on) async {
    try {
      if (on) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (e) {
      print("Ошибка фонарика: $e");
    }
  }

  // 🌐 Браузер
  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Не могу открыть ссылку: $url");
    }
  }
}
