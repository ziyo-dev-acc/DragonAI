class WakeWordConfig {
  final String source; // 'asset' or 'uri'
  final String path;

  const WakeWordConfig({required this.source, required this.path});

  Map<String, dynamic> toJson() => {
        'source': source,
        'path': path,
      };

  factory WakeWordConfig.fromJson(Map<String, dynamic> json) {
    return WakeWordConfig(
      source: json['source'] as String? ?? 'asset',
      path: json['path'] as String? ?? 'porcupine/ari.ppn',
    );
  }
}
