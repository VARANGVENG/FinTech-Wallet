/// The 4 toggleable preferences shown on the Settings screen. Unlike
/// `PaymentMethod`/`Recipient`, this model round-trips through
/// `LocalStorageService` (device-local JSON), not a network response —
/// but it's the same "plain data, no Flutter imports" shape either way.
class AppSettings {
  final bool pushNotifications;
  final bool transactionAlerts;
  final bool biometricLogin;
  final bool darkMode;

  const AppSettings({
    this.pushNotifications = true,
    this.transactionAlerts = true,
    this.biometricLogin = true,
    this.darkMode = true,
  });

  AppSettings copyWith({
    bool? pushNotifications,
    bool? transactionAlerts,
    bool? biometricLogin,
    bool? darkMode,
  }) {
    return AppSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      transactionAlerts: json['transactionAlerts'] as bool? ?? true,
      biometricLogin: json['biometricLogin'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'transactionAlerts': transactionAlerts,
      'biometricLogin': biometricLogin,
      'darkMode': darkMode,
    };
  }
}