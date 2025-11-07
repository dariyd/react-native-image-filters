# Contributing to React Native Image Filters

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Development Setup

### Prerequisites

- Node.js 18+
- React Native development environment (Xcode for iOS, Android Studio for Android)
- iOS 18.0+ SDK
- Android 13+ (API 33) SDK
- CocoaPods (for iOS)
- Yarn or npm

### Setup

1. Clone the repository:

```bash
git clone https://github.com/yourusername/react-native-image-filters.git
cd react-native-image-filters
```

2. Install dependencies:

```bash
yarn install
# or
npm install
```

3. Install iOS dependencies:

```bash
cd ios && pod install && cd ..
```

4. Run the example app:

```bash
# iOS
yarn example ios

# Android
yarn example android
```

## Project Structure

```
react-native-image-filters/
├── src/                    # JavaScript/TypeScript source
│   ├── index.tsx          # Main exports
│   ├── types.ts           # Type definitions
│   ├── NativeImageFilters.ts  # Codegen specs
│   ├── FilteredImageView.tsx  # Component
│   └── filters/           # Filter presets
├── ios/                   # iOS native code
│   └── ImageFilters/
│       ├── *.swift        # Swift implementation
│       ├── *.mm           # Objective-C++ bridge
│       └── Filters/       # Metal shaders
├── android/               # Android native code
│   └── src/main/java/com/imagefilters/
│       └── *.kt          # Kotlin implementation
├── example/              # Example app
└── __tests__/           # Tests
```

## Adding a New Filter

### 1. Add Filter to Registry

**iOS** (`FilterRegistry.swift`):

```swift
private var photoFilters: Set<String> = [
    // ... existing filters
    "myNewFilter"
]
```

**Android** (`FilterRegistry.kt`):

```kotlin
private val photoFilters = setOf(
    // ... existing filters
    "myNewFilter"
)
```

### 2. Implement Filter Logic

**iOS** - Add to `MetalFilterEngine.swift`:

```swift
private func applyMyNewFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
    // Implementation using Metal or Core Image
}
```

**Android** - Add to `FilterEngine.kt`:

```kotlin
private fun applyMyNewFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
    // Implementation using ColorMatrix or custom processing
}
```

### 3. Add Metal Shader (iOS)

Create shader in `PhotoFilters.metal` or `DocumentFilters.metal`:

```metal
kernel void myNewFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Shader implementation
}
```

### 4. Add to TypeScript Types

Update `src/types.ts`:

```typescript
export type PhotoFilter =
  | // ... existing filters
  | 'myNewFilter';
```

### 5. Add Metadata

Update `src/filters/photoFilters.ts`:

```typescript
export const PHOTO_FILTERS: FilterMetadata[] = [
  // ... existing filters
  {
    name: 'myNewFilter',
    displayName: 'My New Filter',
    description: 'Description of what this filter does',
    category: 'photo',
    supportsIntensity: true,
    customParams: ['param1', 'param2'],
  },
];
```

### 6. Test Your Filter

Add tests in `__tests__/` and test in the example app.

## Code Style

### TypeScript/JavaScript

- Use TypeScript for all new code
- Follow ESLint configuration
- Use Prettier for formatting
- Document public APIs with JSDoc comments

### Swift (iOS)

- Follow Swift naming conventions
- Use `@available(iOS 18.0, *)` for version-specific code
- Document public methods
- Use `// MARK: -` for organization

### Kotlin (Android)

- Follow Kotlin style guide
- Use coroutines for async operations
- Document public APIs with KDoc
- Organize with `// MARK: -` comments

## Testing

### Running Tests

```bash
yarn test
```

### Writing Tests

Add tests for:

- Filter application
- Image loading
- Error handling
- Component rendering

Example:

```typescript
describe('applyFilter', () => {
  it('should apply sepia filter', async () => {
    const result = await applyFilter({
      sourceUri: 'test-image.jpg',
      filter: 'sepia',
      intensity: 1.0,
    });

    expect(result.uri).toBeDefined();
    expect(result.width).toBeGreaterThan(0);
    expect(result.height).toBeGreaterThan(0);
  });
});
```

## Performance Considerations

1. **Memory Management**

   - Dispose of unused bitmaps/images
   - Use texture reuse where possible
   - Implement proper cleanup in components

2. **Async Operations**

   - Keep heavy processing off UI thread
   - Use appropriate queue/dispatcher

3. **Caching**
   - Implement smart caching strategies
   - Provide cache management APIs

## Pull Request Process

1. **Create a feature branch**

```bash
git checkout -b feature/my-new-filter
```

2. **Make your changes**

   - Write clean, documented code
   - Add tests
   - Update documentation

3. **Run checks**

```bash
yarn lint
yarn typecheck
yarn test
```

4. **Commit your changes**

```bash
git commit -m "feat: add my new filter"
```

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `test:` Test additions/changes

5. **Push and create PR**

```bash
git push origin feature/my-new-filter
```

Then create a pull request on GitHub.

## Documentation

Update documentation when:

- Adding new features
- Changing APIs
- Adding new filters
- Fixing bugs that affect usage

Files to update:

- `README.md` - User-facing documentation
- `API.md` - API reference
- `CHANGELOG.md` - Version history
- JSDoc comments in code

## Community Guidelines

- Be respectful and inclusive
- Help others learn
- Share knowledge
- Report issues constructively
- Suggest improvements thoughtfully

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Open an issue for bugs
- Start a discussion for feature requests
- Ask questions in discussions

Thank you for contributing! 🎨

