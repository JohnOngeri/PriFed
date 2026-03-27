// Stub file for mobile platforms when dart:html is not available

class _EventStream {
  void listen(void Function(dynamic) callback) {}
}

class _Style {
  String width = '';
  String height = '';
  String objectFit = '';
}

class VideoElement {
  dynamic src;
  bool autoplay = false;
  bool loop = false;
  bool muted = false;
  final style = _Style();
  final onLoadedData = _EventStream();
  void play() {}
  void pause() {}
}
