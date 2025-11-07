# API Documentation

## Core API

### `applyFilter(options: ApplyFilterOptions): Promise<FilterResult>`

Apply a single filter to an image and save the result.

**Parameters:**

- `options` (ApplyFilterOptions):
  - `sourceUri` (string): Image URI (local `file://` or remote `https://`)
  - `filter` (FilterName): Filter name to apply
  - `intensity?` (number): Filter intensity (0-1, default 1)
  - `customParams?` (CustomFilterParams): Filter-specific parameters
  - `returnFormat?` ('uri' | 'base64' | 'both'): Output format (default 'uri')
  - `quality?` (number): Output quality (0-100, default 90)

**Returns:** `Promise<FilterResult>`

- `uri?` (string): File URI to filtered image
- `base64?` (string): Base64 encoded image data
- `width` (number): Image width in pixels
- `height` (number): Image height in pixels

**Example:**

```typescript
const result = await applyFilter({
  sourceUri: 'file:///path/to/image.jpg',
  filter: 'sepia',
  intensity: 0.8,
  returnFormat: 'uri',
  quality: 90,
});

console.log('Filtered image:', result.uri);
```

---

### `applyFilters(operations: ApplyFilterOptions[]): Promise<FilterResult[]>`

Apply filters to multiple images in batch.

**Parameters:**

- `operations` (ApplyFilterOptions[]): Array of filter operations

**Returns:** `Promise<FilterResult[]>` - Array of filter results

**Example:**

```typescript
const results = await applyFilters([
  { sourceUri: 'image1.jpg', filter: 'sepia' },
  { sourceUri: 'image2.jpg', filter: 'vivid', intensity: 0.5 },
  { sourceUri: 'image3.jpg', filter: 'scan' },
]);

results.forEach((result, index) => {
  console.log(`Image ${index}:`, result.uri);
});
```

---

### `getAvailableFilters(type?: FilterType): Promise<string[]>`

Get list of available filters.

**Parameters:**

- `type?` ('document' | 'photo' | 'custom'): Optional filter type

**Returns:** `Promise<string[]>` - Array of filter names

**Example:**

```typescript
const documentFilters = await getAvailableFilters('document');
// ['scan', 'blackWhite', 'enhance', 'perspective', 'grayscale', 'colorPop']

const photoFilters = await getAvailableFilters('photo');
// ['sepia', 'noir', 'fade', 'chrome', ...]

const allFilters = await getAvailableFilters();
// All available filters
```

---

### `getFilterMetadata(name: FilterName): FilterMetadata | undefined`

Get metadata for a specific filter.

**Parameters:**

- `name` (FilterName): Filter name

**Returns:** `FilterMetadata | undefined`

- `name` (string): Filter name
- `displayName` (string): Human-readable name
- `description` (string): Filter description
- `category` (FilterType): Filter category
- `supportsIntensity` (boolean): Whether filter supports intensity
- `customParams?` (string[]): Available custom parameters

**Example:**

```typescript
const metadata = getFilterMetadata('sepia');
console.log(metadata.displayName); // "Sepia"
console.log(metadata.description); // "Classic sepia tone effect"
```

---

### `preloadImage(uri: string): Promise<void>`

Pre-download remote images for faster processing.

**Parameters:**

- `uri` (string): Image URI to preload

**Returns:** `Promise<void>`

**Example:**

```typescript
await preloadImage('https://example.com/image.jpg');
// Image is now cached for faster filtering
```

---

### `clearCache(): Promise<void>`

Clear the image cache.

**Returns:** `Promise<void>`

**Example:**

```typescript
await clearCache();
```

---

## Component API

### `<FilteredImageView>`

Real-time filter preview component with GPU acceleration.

**Props:**

- `source` (ImageSource): Image source ({ uri: string } or string)
- `filter` (FilterName): Filter to apply
- `intensity?` (number): Filter intensity (0-1, default 1)
- `customParams?` (CustomFilterParams): Filter-specific parameters
- `style?` (ViewStyle): View style
- `resizeMode?` ('cover' | 'contain' | 'stretch' | 'center'): Image resize mode
- `onFilterApplied?` (() => void): Callback when filter is applied
- `onError?` ((error: Error) => void): Error callback

**Example:**

```typescript
<FilteredImageView
  source={{ uri: 'https://example.com/image.jpg' }}
  filter="sepia"
  intensity={0.8}
  style={{ width: 300, height: 400 }}
  resizeMode="cover"
  onFilterApplied={() => console.log('Filter applied!')}
  onError={(error) => console.error('Error:', error)}
/>
```

---

## Filter Types

### Document Scanning Filters

- **scan**: Adaptive threshold + contrast + sharpness (default document scan)
  - Custom params: `threshold`, `contrast`, `sharpness`
- **blackWhite**: High-contrast B&W with noise reduction
  - Custom params: `threshold`, `noiseReduction`
- **enhance**: Smart brightness/contrast/saturation boost
  - Custom params: `brightness`, `contrast`, `saturation`, `sharpness`
- **perspective**: Auto perspective correction
  - Custom params: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`
- **grayscale**: Grayscale conversion
- **colorPop**: Increased saturation and clarity
  - Custom params: `saturation`, `vibrance`, `clarity`

### Photo Editing Filters

Classic effects:

- **sepia**: Classic sepia tone
- **noir**: High-contrast black and white
- **fade**: Washed-out, faded look
- **chrome**: Metallic, high-contrast
- **transfer**: Soft, warm vintage
- **instant**: Polaroid-style
- **vivid**: Enhanced saturation and contrast
- **dramatic**: Bold, high-contrast
- **warm**: Warm temperature and glow
- **cool**: Cool blue tones
- **vintage**: Retro film-inspired

Instagram-style:

- **clarendon**: Brightens and adds contrast
- **gingham**: Soft, pastel tones
- **juno**: Enhanced warm tones
- **lark**: Bright, desaturated
- **luna**: Cool, moody tones
- **reyes**: Vintage with subtle gold
- **valencia**: Warm, faded
- **brooklyn**: Subtle warm filter
- **earlybird**: Sunrise warm tones
- **hudson**: Cool, icy blue
- **inkwell**: Classic B&W
- **lofi**: Enhanced colors and shadows
- **mayfair**: Warm center, cool edges
- **nashville**: Warm, pink-tinted
- **perpetua**: Soft pastel greens/blues
- **toaster**: Vintage with vignette
- **walden**: Increased exposure, warm
- **xpro2**: Cross-processed film

### Custom Filter

- **custom**: Fully customizable filter
  - Params: `brightness`, `contrast`, `saturation`, `exposure`, `highlights`, `shadows`, `temperature`, `tint`, `sharpness`, `vibrance`, `hue`, `gamma`

---

## Custom Filter Parameters

All parameters are optional. Default values preserve the original image.

### Basic Adjustments

- **brightness** (0-2, default 1.0): Overall brightness
- **contrast** (0-2, default 1.0): Contrast level
- **saturation** (0-2, default 1.0): Color saturation
- **exposure** (0-2, default 1.0): Exposure level

### Advanced Adjustments

- **highlights** (0-2, default 1.0): Bright areas adjustment
- **shadows** (0-2, default 1.0): Dark areas adjustment
- **temperature** (-100 to 100, default 0): Color temperature
- **tint** (-100 to 100, default 0): Green/magenta tint
- **sharpness** (0-2, default 1.0): Sharpness level
- **vibrance** (0-2, default 1.0): Vibrance (selective saturation)
- **hue** (-180 to 180, default 0): Hue rotation in degrees
- **gamma** (0.1-3, default 1.0): Gamma correction

**Example:**

```typescript
const result = await applyFilter({
  sourceUri: 'image.jpg',
  filter: 'custom',
  customParams: {
    brightness: 1.2,
    contrast: 1.3,
    saturation: 0.9,
    temperature: 15,
    sharpness: 1.2,
  },
});
```

---

## Performance Tips

1. **Use `FilteredImageView` for real-time preview** - No disk I/O, GPU-accelerated
2. **Preload remote images** - Call `preloadImage()` before filtering
3. **Batch processing** - Use `applyFilters()` for multiple images
4. **Optimize quality** - Use appropriate quality setting (70-90 for most cases)
5. **Cache management** - Clear cache periodically with `clearCache()`

---

## Platform-Specific Details

### iOS

- Uses Metal for GPU acceleration
- Core Image integration for additional filters
- Supports iOS 18.0+
- Real-time preview via MTKView

### Android

- Uses GPU-accelerated ColorMatrix rendering
- Glide for image loading and caching
- Supports Android 13+ (API 33)
- Efficient Bitmap operations

---

## Error Handling

All async functions may throw errors. Always use try-catch:

```typescript
try {
  const result = await applyFilter({
    sourceUri: 'invalid-uri',
    filter: 'sepia',
  });
} catch (error) {
  console.error('Filter error:', error.message);
}
```

Common error types:

- Image loading errors (invalid URI, network failure)
- Invalid filter names
- Unsupported image formats
- Memory/resource errors

---

## TypeScript Support

Full TypeScript support with detailed type definitions:

```typescript
import type {
  FilterName,
  FilterType,
  ApplyFilterOptions,
  FilterResult,
  CustomFilterParams,
  FilterMetadata,
} from 'react-native-image-filters';
```

