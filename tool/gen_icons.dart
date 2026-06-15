// Generates the source images consumed by flutter_launcher_icons from the
// brand logo:
//   * assets/icon/icon.png            — 1024×1024 full-bleed icon
//   * assets/icon/icon_foreground.png — 1024×1024 adaptive foreground: the logo
//                                       padded to ~72% on the dark-wood green so
//                                       it stays fully visible inside the
//                                       Android adaptive-icon safe zone.
//
// Run with:  dart run tool/gen_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final srcBytes = File('assets/images/logo.png').readAsBytesSync();
  final src = img.decodePng(srcBytes);
  if (src == null) {
    stderr.writeln('Could not decode assets/images/logo.png');
    exit(1);
  }

  const int size = 1024;

  // 1) Full-bleed icon (used for iOS / web / legacy Android).
  final full = img.copyResize(
    src,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(full));

  // 2) Adaptive foreground: dark-wood green canvas + centered logo at 72%.
  final fg = img.Image(width: size, height: size, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0x14, 0x26, 0x1C, 0xFF)); // #14261C
  final int target = (size * 0.72).round();
  final logo = img.copyResize(
    src,
    width: target,
    height: target,
    interpolation: img.Interpolation.cubic,
  );
  final int offset = ((size - target) / 2).round();
  img.compositeImage(fg, logo, dstX: offset, dstY: offset);
  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('Generated assets/icon/icon.png and icon_foreground.png');
}
