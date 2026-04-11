import 'dart:io';

/// Entfernt EXIF-Metadaten aus JPEG-Dateien.
/// Dies ist wichtig für die EA-Erkennung, da EXIF-Daten verraten
/// ob ein Bild mit KI oder einer echten Kamera aufgenommen wurde.
Future<File> stripExif(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();

  if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    // Kein gültiges JPEG
    return file;
  }

  final stripped = <int>[];

  // JPEG Start
  stripped.add(0xFF);
  stripped.add(0xD8);

  var i = 2;
  while (i < bytes.length - 1) {
    if (bytes[i] != 0xFF) {
      // Kein Marker — wahrscheinlich Bilddaten, ab hier alles kopieren
      while (i < bytes.length) {
        stripped.add(bytes[i]);
        i++;
      }
      break;
    }

    final marker = bytes[i + 1];

    // SOI (Start of Image) — schon kopiert
    if (marker == 0xD8 || marker == 0xD9) {
      stripped.add(bytes[i]);
      stripped.add(bytes[i + 1]);
      i += 2;
      continue;
    }

    // EOI (End of Image) — Rest ignorieren
    if (marker == 0xD9) {
      stripped.add(0xFF);
      stripped.add(0xD9);
      break;
    }

    // APP1 (EXIF) — ÜBERSPRINGEN
    if (marker == 0xE1) {
      if (i + 3 < bytes.length) {
        var len = (bytes[i + 2] << 8) | bytes[i + 3];
        // Prüfen ob es wirklich EXIF ist (ASCII "Exif")
        if (i + 4 < bytes.length &&
            bytes[i + 4] == 0x45 && // E
            bytes[i + 5] == 0x78 && // x
            bytes[i + 6] == 0x69 && // i
            bytes[i + 7] == 0x66) {
          // EXIF gefunden — überspringen
          i += 2 + len;
          continue;
        }
      }
    }

    // APP0 (JFIF) — Kopieren (wichtig für Kompatibilität)
    if (marker == 0xE0) {
      if (i + 3 < bytes.length) {
        var len = (bytes[i + 2] << 8) | bytes[i + 3];
        for (var j = 0; j < 2 + len && i + j < bytes.length; j++) {
          stripped.add(bytes[i + j]);
        }
        i += 2 + len;
        continue;
      }
    }

    // Alle anderen Marker — mit Länge kopieren
    if (i + 3 < bytes.length) {
      var len = (bytes[i + 2] << 8) | bytes[i + 3];
      for (var j = 0; j < 2 + len && i + j < bytes.length; j++) {
        stripped.add(bytes[i + j]);
      }
      i += 2 + len;
    } else {
      break;
    }
  }

  final outFile = File('${filePath}_clean.jpg');
  await outFile.writeAsBytes(stripped);
  return outFile;
}
