import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/core/artwork_service.dart';

void main() {
  test('saved photos lose their EXIF (GPS, time taken) but stay upright', () {
    final photo = img.Image(width: 40, height: 20)..exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(25, 1);
    photo.exif.imageIfd.orientation = 6; // rotated 90 degrees
    final jpeg = img.encodeJpg(photo);
    expect(img.decodeJpgExif(jpeg)!.gpsIfd.isEmpty, isFalse);

    final clean = withoutMetadata(Uint8List.fromList(jpeg));
    final exif = img.decodeJpgExif(clean);
    expect(exif == null || (exif.gpsIfd.isEmpty && !exif.imageIfd.hasOrientation), isTrue);
    final upright = img.decodeJpg(clean)!;
    expect((upright.width, upright.height), (20, 40));
  });

  test('photos that cannot be decoded are kept', () {
    final junk = Uint8List.fromList([1, 2, 3]);
    expect(withoutMetadata(junk), junk);
  });
}
