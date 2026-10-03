import 'dart:async';

import 'package:flutter/material.dart';

Future<double> getAspectRatio(ImageProvider provider) async {
  Completer<double> completer = Completer();
  
  ImageStream stream = provider.resolve(const ImageConfiguration());
  
  late ImageStreamListener listener;
  
  listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    double aspectRatio = info.image.width / info.image.height;
    
    stream.removeListener(listener);
    completer.complete(aspectRatio);
  }, onError: (dynamic exception, StackTrace? stackTrace) {
    stream.removeListener(listener);
    completer.completeError(exception);
  });

  stream.addListener(listener);
  return completer.future;
}