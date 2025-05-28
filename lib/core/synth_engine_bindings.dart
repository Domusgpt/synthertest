// Export the appropriate implementation based on platform
export 'synth_engine_bindings_stub.dart' 
  if (dart.library.io) 'synth_engine_bindings_native.dart'
  if (dart.library.html) 'synth_engine_bindings_web.dart';