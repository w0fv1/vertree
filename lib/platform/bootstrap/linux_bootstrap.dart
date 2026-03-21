import 'package:vertree/platform/bootstrap/platform_bootstrap.dart';
import 'package:vertree/platform/linux_gnome_integration.dart';

class LinuxBootstrap extends PlatformBootstrap {
  const LinuxBootstrap._(this.name);

  factory LinuxBootstrap.currentSession() {
    if (LinuxGnomeIntegration.isGnomeSession) {
      return const LinuxBootstrap._('linux-gnome');
    }
    return const LinuxBootstrap._('linux');
  }

  @override
  final String name;
}
