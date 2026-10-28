import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Coloring pages on real paper (0.18): the phone's own print dialog, to a
/// printer it knows or into a PDF. Only parent mode prints.
abstract interface class PagePrinter {
  /// Prints [pages] (PNG line art), one a sheet, as [name].
  Future<void> printPages(List<Uint8List> pages, {required String name});
}

class SystemPrinter implements PagePrinter {
  @override
  Future<void> printPages(List<Uint8List> pages, {required String name}) =>
      Printing.layoutPdf(name: name, onLayout: (format) => coloringPdf(pages, format));
}

/// [pages] one a sheet of [format] (A4 unless the printer says otherwise),
/// each as big as fits inside a 15 mm margin, turned to fit the sheet best.
Future<Uint8List> coloringPdf(List<Uint8List> pages, [PdfPageFormat format = PdfPageFormat.a4]) {
  final doc = pw.Document(title: '畫畫小鎮', creator: '畫畫小鎮');
  for (final png in pages) {
    final image = pw.MemoryImage(png);
    final wide = (image.width ?? 1) > (image.height ?? 1);
    final sheet = wide ? format.landscape : format.portrait;
    doc.addPage(pw.Page(
      pageFormat: sheet,
      margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
      build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
    ));
  }
  return doc.save();
}
