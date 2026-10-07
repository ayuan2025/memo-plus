// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
//
// Pure-Dart document boundary detection, perspective correction and scanner
// colour filters, extracted from the OpenScan Android document scanner and
// adapted for memo+. See `third_party/openscan_cv/` for the full license text
// and the list of local adaptations.
//
// Nothing in here depends on Flutter: it is `dart:math`, `dart:typed_data` and
// `package:image` only, so every entry point is safe to run inside a `compute()`
// isolate and unit-testable without a widget tree.

export 'src/document_detector.dart'
    show kDetectionMaxDimension, detectDocumentInBytes, detectQuadFromGrayscale;
export 'src/contours.dart'
    show
        findDocumentQuad,
        findDocumentQuadCandidates,
        isPlausibleQuad,
        pickBestQuad,
        sortCorners,
        kMinQuadAngleDegrees,
        kMinQuadAreaRatio;
export 'src/deskew.dart'
    show
        deskewPage,
        estimatePageSkewAngle,
        kDeskewMaxAngleDegrees,
        kDeskewMinAngleDegrees;
export 'src/edge_detection.dart'
    show
        dilate,
        gaussianBlur3,
        otsuThreshold,
        rgbaToGrayscale,
        sobelMagnitude,
        threshold;
export 'src/full_frame_page.dart'
    show
        PageBoundaryEvidence,
        FullPageDecision,
        FullPageReason,
        documentEdgeThreshold,
        fullFrameQuad,
        insetFrameQuad,
        isFullFrameQuad,
        measurePageBoundary,
        quadArea,
        resolveDocumentBoundary;
export 'src/models/detection_result.dart'
    show DetectionFailure, DetectionNotFound, DetectionResult, DetectionSuccess;
export 'src/models/point.dart' show Pt;
export 'src/models/quad.dart' show Quad;
export 'src/page_renderer.dart'
    show
        ScannedPage,
        fitToMaxEdge,
        kStoredPageMaxEdge,
        kStoredPageQuality,
        renderScannedPage;
export 'src/perspective_crop.dart'
    show
        CropFailure,
        CropResult,
        CropSuccess,
        cropToQuadBytes,
        outputSize,
        quadInPixels,
        quadInPixelsOf,
        warpToPage;
export 'src/filters/apply_filter.dart'
    show filterDocumentBytes, filterEncodedImage, filterRgba;
export 'src/filters/document_filters.dart'
    show
        AutoFilter,
        BlackAndWhiteFilter,
        GrayscaleFilter,
        LightenFilter,
        OriginalFilter,
        WhiteboardFilter,
        defaultDocumentFilter,
        documentFilterByName,
        documentFiltersList;
export 'src/filters/filter.dart' show Filter;
export 'src/filters/filter_field_utils.dart'
    show
        applyLutToChannel,
        applyLutToRgb,
        boxBlur,
        boxSum,
        channelHistogram,
        downscaleGray,
        grayHistogram,
        integralImage,
        percentileBounds,
        stretchLut;
export 'src/filters/filter_pixels.dart'
    show clampPixel, contrast, grayscale, saturation;
