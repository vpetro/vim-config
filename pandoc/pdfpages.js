ObjC.import('Quartz');
ObjC.import('AppKit');
function run(argv) {
  var pdf = argv[0], outPrefix = argv[1], scale = parseFloat(argv[2] || "1.5");
  var doc = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(pdf));
  var n = doc.pageCount;
  for (var i = 0; i < n; i++) {
    var page = doc.pageAtIndex(i);
    var box = page.boundsForBox($.kPDFDisplayBoxMediaBox);
    var w = Math.round(box.size.width * scale), h = Math.round(box.size.height * scale);
    var rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(null, w, h, 8, 4, true, false, $.NSCalibratedRGBColorSpace, 0, 0);
    var ctx = $.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep);
    $.NSGraphicsContext.saveGraphicsState;
    $.NSGraphicsContext.setCurrentContext(ctx);
    $.NSColor.whiteColor.setFill;
    $.NSBezierPath.fillRect($.NSMakeRect(0, 0, w, h));
    var cg = ctx.CGContext;
    $.CGContextScaleCTM(cg, scale, scale);
    page.drawWithBoxToContext($.kPDFDisplayBoxMediaBox, cg);
    $.NSGraphicsContext.restoreGraphicsState;
    var png = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $());
    png.writeToFileAtomically(outPrefix + "-" + (i + 1) + ".png", true);
  }
  return "pages: " + n + " size: " + Math.round(doc.pageAtIndex(0).boundsForBox($.kPDFDisplayBoxMediaBox).size.width) + "x" + Math.round(doc.pageAtIndex(0).boundsForBox($.kPDFDisplayBoxMediaBox).size.height) + "pt";
}
