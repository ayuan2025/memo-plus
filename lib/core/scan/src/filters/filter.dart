// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import 'dart:typed_data';

/// A colour mode that can be applied to a scanned page.
///
/// [name] is the filter's stable id: it is the value written to storage and the
/// key previews are cached under, so it must not change with the app's locale.
/// The label the user sees is resolved separately, in the UI layer.
abstract class Filter {
  const Filter({required this.name});

  final String name;

  /// Rewrites [pixels] — an RGBA buffer of stride 4 — in place.
  void apply(Uint8List pixels, int width, int height);
}
