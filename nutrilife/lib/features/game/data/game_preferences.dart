import 'package:shared_preferences/shared_preferences.dart';

import '../domain/habitat_scene.dart';
import '../domain/otter_skin.dart';

/// Guarda qué nutria y qué lugar eligió el usuario.
// shortcut: se guarda en el teléfono, no en la cuenta; pasar al backend cuando
// las nutrias o lugares se desbloqueen o compren y deban seguir al usuario.
class GamePreferences {
  static const _skinKey = 'game_otter_skin';
  static const _sceneKey = 'game_habitat';

  Future<({OtterSkin skin, HabitatScene scene})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      skin: OtterSkin.byId(prefs.getString(_skinKey)),
      scene: HabitatScene.byId(prefs.getString(_sceneKey)),
    );
  }

  Future<void> saveSkin(OtterSkin skin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skinKey, skin.id);
  }

  Future<void> saveScene(HabitatScene scene) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sceneKey, scene.id);
  }
}
