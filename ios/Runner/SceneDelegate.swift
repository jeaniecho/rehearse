import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  /// Paints the window and the Flutter view the app's own canvas colour.
  ///
  /// Between the launch storyboard being torn down and the engine drawing its
  /// first frame there is a gap, and whatever the window is filled with is
  /// what shows in it. Unset, that is black — so a splash the same cream as
  /// the app blinked to black on its way to a screen the same cream again.
  ///
  /// `AppColors.ground`, #F5F2EA. It appears here because this runs before
  /// any Dart does; `launch_background` in the Android colours is the same
  /// value for the same reason.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    let ground = UIColor(
      red: 0xF5 / 255.0,
      green: 0xF2 / 255.0,
      blue: 0xEA / 255.0,
      alpha: 1
    )
    window?.backgroundColor = ground
    window?.rootViewController?.view.backgroundColor = ground
  }
}
