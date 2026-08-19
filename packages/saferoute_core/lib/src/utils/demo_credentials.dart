import '../constants/enums.dart';

/// Pre-configured Demo Persona Credentials for local development & QA sandbox
class DemoPersona {
  final String email;
  final String password;
  final String roleName;
  final UserRole role;
  final String description;

  const DemoPersona({
    required this.email,
    required this.password,
    required this.roleName,
    required this.role,
    required this.description,
  });
}

class DemoCredentials {
  DemoCredentials._();

  static const parent = DemoPersona(
    email: 'parent@dps.edu',
    password: 'Password123!',
    roleName: 'Parent',
    role: UserRole.parent,
    description: 'Tracks Alice Alpha on Route 42 with 500m geofence alerts',
  );

  static const driver = DemoPersona(
    email: 'driver@dps.edu',
    password: 'Password123!',
    roleName: 'Driver',
    role: UserRole.driver,
    description: 'Operates Bus #12 (KA-01-EA-1234) with live GPS HUD & roll call',
  );

  static const admin = DemoPersona(
    email: 'admin@dps.edu',
    password: 'Password123!',
    roleName: 'Fleet Admin',
    role: UserRole.admin,
    description: 'Manages school fleet operations, students, and safety settings',
  );

  static const List<DemoPersona> allPersonas = [parent, driver, admin];
}
