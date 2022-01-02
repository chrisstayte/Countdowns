class Settings {
  bool darkMode;

  Settings({required this.darkMode});

  factory Settings.fromJson(Map<String, dynamic> json) {
    bool darkMode = json['darkMode'] as bool;

    return Settings(darkMode: darkMode);
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
      };
}
