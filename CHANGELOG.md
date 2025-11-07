# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-06

### Added

- Initial release of react-native-image-filters
- GPU-accelerated image filtering using Metal (iOS) and GPU rendering (Android)
- Support for iOS 18.0+ and Android 13+ (API 33)
- React Native New Architecture (TurboModules) support
- Real-time filter preview component (`FilteredImageView`)
- Imperative API for applying and saving filtered images
- 6 document scanning filters:
  - `scan`: Adaptive threshold + contrast + sharpness
  - `blackWhite`: High-contrast B&W with noise reduction
  - `enhance`: Smart brightness/contrast/saturation boost
  - `perspective`: Perspective correction
  - `grayscale`: Grayscale conversion
  - `colorPop`: Increased saturation and clarity
- 29 photo editing filters (Instagram-style):
  - Classic effects: sepia, noir, fade, chrome, transfer, instant
  - Color adjustments: vivid, dramatic, warm, cool, vintage
  - Instagram presets: clarendon, gingham, juno, lark, luna, reyes, valencia, brooklyn, earlybird, hudson, inkwell, lofi, mayfair, nashville, perpetua, toaster, walden, xpro2
- Custom filter with adjustable parameters:
  - brightness, contrast, saturation, exposure
  - highlights, shadows, temperature, tint
  - sharpness, vibrance, hue, gamma
- Image loading support:
  - Local files (`file://`)
  - Remote images (`https://`)
  - Content URIs (`content://`)
  - Data URIs (`data:`)
- Output format options:
  - File URI
  - Base64 encoded data
  - Both formats
- Batch processing support for multiple images
- Image caching with configurable size limits
- Metal shaders for high-performance iOS filtering
- Comprehensive TypeScript type definitions
- Full API documentation
- Example app demonstrating all features

### Performance Optimizations

- In-memory texture caching (up to 50MB)
- Efficient GPU memory management
- Async processing off UI thread
- Texture reuse in Metal rendering
- Smart image loading with Glide (Android)
- URLSession caching for remote images (iOS)

### Documentation

- Detailed README with usage examples
- Complete API reference (API.md)
- Contributing guidelines (CONTRIBUTING.md)
- Comprehensive example application
- Inline code documentation

## [Unreleased]

### Planned

- Additional Instagram-style filters
- Video filtering support
- Filter composition (applying multiple filters)
- Custom Metal/GLSL shader injection
- Advanced corner detection for perspective correction
- LUT (Lookup Table) import/export
- Performance benchmarking tools
- Unit and integration tests
- CI/CD pipeline

---

[1.0.0]: https://github.com/yourusername/react-native-image-filters/releases/tag/v1.0.0

