// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.
//
// Local adaptation: OpenScan's isolate entry points took `File` paths and did
// their own reads and writes. Here the filters are byte-in/byte-out, so no
// caller has to invent a temporary file just to colour a page.

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../page_renderer.dart' show kStoredPageQuality;
import 'document_filters.dart';
import 'filter.dart';

/// Runs [filter] over the RGBA buffer in place and hands it back.
///
/// Kept separate from the encoding below so the picker can filter an
/// already-decoded thumbnail without decoding it again.
Uint8List filterRgba(Filter filter, Uint8List rgba, int width, int height) {
  filter.apply(rgba, width, height);
  return rgba;
}

/// Decodes [encoded], applies [filter] and re-encodes as JPEG.
///
/// The `image` package hands out a *copy* of the pixel buffer from `getBytes()`,
/// so the filtered bytes have to be wrapped back into a new [img.Image] before
/// encoding — mutating the buffer alone would silently encode the untouched
/// original.
///
/// [maxEdge] works on a downscaled copy, which is how a filter strip builds its
/// previews without decoding a full-resolution capture once per chip.
Uint8List filterEncodedImage(Filter filter, Uint8List encoded, {int? maxEdge}) {
  img.Image? decoded = img.decodeImage(encoded);
  if (decoded == null) {
    throw StateError('Could not decode image for filtering');
  }
  if (maxEdge != null &&
      (decoded.width > maxEdge || decoded.height > maxEdge)) {
    decoded = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxEdge)
        : img.copyResize(decoded, height: maxEdge);
  }

  final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
  filterRgba(filter, rgba, decoded.width, decoded.height);

  final filtered = img.Image.fromBytes(
    width: decoded.width,
    height: decoded.height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  // The same quality a page is stored at (see kStoredPageQuality): a filtered
  // page is still just a page, and encoding it richer than the capture it came
  // from buys nothing but bytes.
  return img.encodeJpg(filtered, quality: kStoredPageQuality);
}

/// Applies the filter named [filterName] to the image in [encoded], resolving
/// the name through [documentFilterByName] and falling back to the default
/// filter for an unknown id.
Uint8List filterDocumentBytes(
  Uint8List encoded, {
  required String? filterName,
  int? maxEdge,
}) => filterEncodedImage(
  documentFilterByName(filterName),
  encoded,
  maxEdge: maxEdge,
);
