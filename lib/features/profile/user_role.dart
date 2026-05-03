enum UserRole {
  parent,
  provider,
  admin,
  unknown;

  static UserRole fromString(String? v) {
    return switch (v) {
      'parent' => UserRole.parent,
      'provider' => UserRole.provider,
      'admin' => UserRole.admin,
      _ => UserRole.unknown,
    };
  }
}

