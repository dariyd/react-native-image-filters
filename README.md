# react-native-image-filters

High-performance GPU-accelerated image filters for React Native with New Architecture support.

## Features

- 🚀 GPU-accelerated filtering using Metal (iOS) and Vulkan (Android)
- 📸 Document scanning filters (scan, enhance, black & white, perspective correction)
- 🎨 Photo editing filters (Instagram-style presets: sepia, vintage, vivid, dramatic, etc.)
- 🎯 Real-time preview component for instant filter visualization
- 💾 Save filtered images to file system
- 🌐 Support for local and remote images
- ⚡ Optimized for iOS 18+ and Android 13+
- 🏗️ Built with React Native New Architecture (TurboModules)
- 🎛️ Custom filter support with adjustable parameters

## Installation

```sh
npm install react-native-image-filters
```

or

```sh
yarn add react-native-image-filters
```

### iOS

```sh
cd ios && pod install
```

Minimum deployment target: iOS 18.0

### Android

Minimum SDK version: 33 (Android 13)

## Usage

### Real-time Filter Preview Component

```tsx
import { FilteredImageView } from 'react-native-image-filters';

function App() {
  return (
    <FilteredImageView
      source={{ uri: 'https://example.com/image.jpg' }}
      filter="sepia"
      intensity={0.8}
      style={{ width: 300, height: 400 }}
      onFilterApplied={() => console.log('Filter applied!')}
    />
  );
}
```

### Apply Filter and Save

```tsx
import { applyFilter } from 'react-native-image-filters';

async function processImage() {
  const result = await applyFilter({
    sourceUri: 'file:///path/to/image.jpg',
    filter: 'scan',
    intensity: 1.0,
    returnFormat: 'uri', // 'uri' | 'base64' | 'both'
    quality: 90,
  });

  console.log('Filtered image:', result.uri);
  console.log('Dimensions:', result.width, result.height);
}
```

### Batch Processing

```tsx
import { applyFilters } from 'react-native-image-filters';

async function processMultiple() {
  const results = await applyFilters([
    { sourceUri: 'image1.jpg', filter: 'sepia' },
    { sourceUri: 'image2.jpg', filter: 'vivid' },
    { sourceUri: 'image3.jpg', filter: 'scan' },
  ]);

  results.forEach((result, index) => {
    console.log(`Image ${index}:`, result.uri);
  });
}
```

### Available Filters

```tsx
import { getAvailableFilters } from 'react-native-image-filters';

const documentFilters = await getAvailableFilters('document');
// ['scan', 'blackWhite', 'enhance', 'perspective', 'grayscale', 'colorPop']

const photoFilters = await getAvailableFilters('photo');
// ['sepia', 'noir', 'fade', 'chrome', 'vivid', 'dramatic', 'warm', 'cool', ...]
```

### Custom Filters

```tsx
const result = await applyFilter({
  sourceUri: 'image.jpg',
  filter: 'custom',
  customParams: {
    brightness: 1.2,
    contrast: 1.5,
    saturation: 0.8,
  },
});
```

## API Reference

### `applyFilter(options: ApplyFilterOptions): Promise<FilterResult>`

Apply a filter to an image and save the result.

**Options:**
- `sourceUri`: Image URI (local `file://` or remote `https://`)
- `filter`: Filter name
- `intensity?`: Filter intensity (0-1, default 1)
- `customParams?`: Filter-specific parameters
- `returnFormat?`: 'uri' | 'base64' | 'both' (default 'uri')
- `quality?`: Output quality (0-100, default 90)

**Returns:** `{ uri?, base64?, width, height }`

### `applyFilters(optionsArray: ApplyFilterOptions[]): Promise<FilterResult[]>`

Batch process multiple images.

### `getAvailableFilters(type?: 'document' | 'photo' | 'custom'): Promise<string[]>`

Get list of available filters.

### `preloadImage(uri: string): Promise<void>`

Pre-download remote images for faster processing.

### `<FilteredImageView>`

Real-time filter preview component.

**Props:**
- `source`: Image source ({ uri: string })
- `filter`: Filter name
- `intensity?`: Filter intensity (0-1)
- `customParams?`: Filter-specific parameters
- `style?`: View style
- `onFilterApplied?`: Callback when filter is applied
- `onError?`: Error callback

## Document Scanning Filters

- `scan`: Adaptive threshold + contrast + sharpness (default document scan)
- `blackWhite`: High-contrast B&W with noise reduction
- `enhance`: Smart brightness/contrast/saturation boost
- `perspective`: Auto perspective correction
- `grayscale`: Grayscale conversion
- `colorPop`: Increased saturation and clarity

## Photo Editing Filters

Instagram-style presets with adjustable intensity:
- `sepia`, `noir`, `fade`, `chrome`, `transfer`, `instant`
- `vivid`, `dramatic`, `warm`, `cool`, `vintage`
- `clarendon`, `gingham`, `juno`, `lark`, `luna`, `reyes`, `valencia`

## Performance

- Metal (iOS) and Vulkan (Android) for GPU acceleration
- In-memory texture caching for real-time previews
- Optimized for high-resolution images
- Async processing doesn't block UI thread

## Requirements

- React Native 0.74+
- iOS 18.0+
- Android 13+ (API 33)
- New Architecture enabled

## License

MIT

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository.

