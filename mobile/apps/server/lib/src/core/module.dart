import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// One domain of the monolith (auth, stations, wallet, ...). A module owns
/// its data and routes; other modules reach it only through the interface
/// exported from its `api.dart`, never through its `internal/` files.
abstract interface class BunoModule {
  /// Adds this module's routes to the app's [router].
  void mount(Router router, ModuleContext context);
}

/// What the composition root hands every module.
class ModuleContext {
  const ModuleContext({required this.authed});

  /// Wraps a handler so it only runs for a signed-in user (401 otherwise);
  /// read the user inside with `userIdOf(request)` and path parameters with
  /// `request.params`.
  final Handler Function(Handler handler) authed;
}
