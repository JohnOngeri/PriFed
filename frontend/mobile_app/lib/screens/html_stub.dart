// Stub file for mobile platforms when dart:html is not available
// This provides empty implementations to satisfy the type system

class VideoElement {
  dynamic src;
  bool autoplay = false;
  bool loop = false;
  bool muted = false;
  dynamic style = _Style();
  void play() {}
  void pause() {}
  dynamic onLoadedData;
}

class _Style {
  String width = '';
  String height = '';
  String objectFit = '';
}





