import { NativeModules, Platform } from 'react-native';
import NativeImageFilters from './NativeImageFilters';
import type {
  ApplyFilterOptions,
  FilterResult,
  FilterType,
  FilterName,
  FilterMetadata,
  BatchFilterOperation,
  BatchFilterResult,
  CropImageOptions,
  ResizeImageOptions,
  RotateImageOptions,
  CropRect,
  ResizeMode,
} from './types';
import { DOCUMENT_FILTERS, getDocumentFilterNames } from './filters/documentFilters';
import { PHOTO_FILTERS, getPhotoFilterNames } from './filters/photoFilters';
import { CUSTOM_FILTER } from './filters/customFilters';

// Export types
export type {
  ApplyFilterOptions,
  FilterResult,
  FilterType,
  FilterName,
  FilterMetadata,
  CustomFilterParams,
  ImageSource,
  FilteredImageViewProps,
  FilterPreset,
  BatchFilterOperation,
  BatchFilterResult,
  DocumentFilter,
  PhotoFilter,
  ReturnFormat,
  CropImageOptions,
  ResizeImageOptions,
  RotateImageOptions,
  CropRect,
  ResizeMode,
  CropperViewProps,
} from './types';

// Export filter constants
export { DOCUMENT_FILTERS, PHOTO_FILTERS, CUSTOM_FILTER };
export { DOCUMENT_PRESETS } from './filters/documentFilters';
export { PHOTO_PRESETS } from './filters/photoFilters';
export {
  DEFAULT_CUSTOM_PARAMS,
  PARAM_RANGES,
  validateCustomParams,
  mergeWithDefaults,
  getParamDescription,
} from './filters/customFilters';

// Export components
export { FilteredImageView } from './FilteredImageView';
export { CropperView, getCropRect, resetCropRect, setCropRect } from './CropperView';

const LINKING_ERROR =
  `The package 'react-native-image-filters' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const ImageFilters = NativeImageFilters
  ? NativeImageFilters
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

/**
 * Apply a single filter to an image
 * @param options Filter options
 * @returns Promise resolving to filter result
 * @example
 * const result = await applyFilter({
 *   sourceUri: 'file:///path/to/image.jpg',
 *   filter: 'sepia',
 *   intensity: 0.8,
 *   returnFormat: 'uri',
 *   quality: 90,
 * });
 */
export async function applyFilter(options: ApplyFilterOptions): Promise<FilterResult> {
  try {
    const result = await ImageFilters.applyFilter({
      sourceUri: options.sourceUri,
      filter: options.filter,
      intensity: options.intensity ?? 1.0,
      customParams: options.customParams ?? {},
      returnFormat: options.returnFormat ?? 'uri',
      quality: options.quality ?? 90,
    });
    return result as FilterResult;
  } catch (error) {
    throw new Error(`Failed to apply filter: ${error}`);
  }
}

/**
 * Apply filters to multiple images (batch operation)
 * @param operations Array of filter operations
 * @returns Promise resolving to array of filter results
 * @example
 * const results = await applyFilters([
 *   { sourceUri: 'image1.jpg', filter: 'sepia' },
 *   { sourceUri: 'image2.jpg', filter: 'vivid' },
 * ]);
 */
export async function applyFilters(
  operations: ApplyFilterOptions[]
): Promise<FilterResult[]> {
  try {
    const optionsArray = operations.map(op => ({
      sourceUri: op.sourceUri,
      filter: op.filter,
      intensity: op.intensity ?? 1.0,
      customParams: op.customParams ?? {},
      returnFormat: op.returnFormat ?? 'uri',
      quality: op.quality ?? 90,
    }));
    const results = await ImageFilters.applyFilters(optionsArray);
    return results as FilterResult[];
  } catch (error) {
    throw new Error(`Failed to apply filters: ${error}`);
  }
}

/**
 * Crop an image to specified rectangle
 * @param options Crop options
 * @returns Promise resolving to cropped image result
 * @example
 * const result = await cropImage({
 *   sourceUri: 'file:///path/to/image.jpg',
 *   cropRect: { x: 100, y: 100, width: 500, height: 500 },
 *   returnFormat: 'uri',
 *   quality: 90,
 * });
 */
export async function cropImage(options: CropImageOptions): Promise<FilterResult> {
  try {
    const result = await ImageFilters.cropImage({
      sourceUri: options.sourceUri,
      cropRect: options.cropRect,
      returnFormat: options.returnFormat ?? 'uri',
      quality: options.quality ?? 90,
    });
    return result as FilterResult;
  } catch (error) {
    throw new Error(`Failed to crop image: ${error}`);
  }
}

/**
 * Resize an image to target dimensions
 * @param options Resize options
 * @returns Promise resolving to resized image result
 * @example
 * const result = await resizeImage({
 *   sourceUri: 'file:///path/to/image.jpg',
 *   width: 1024,
 *   height: 768,
 *   mode: 'contain',
 *   returnFormat: 'uri',
 *   quality: 90,
 * });
 */
export async function resizeImage(options: ResizeImageOptions): Promise<FilterResult> {
  try {
    const result = await ImageFilters.resizeImage({
      sourceUri: options.sourceUri,
      width: options.width,
      height: options.height,
      mode: options.mode ?? 'contain',
      returnFormat: options.returnFormat ?? 'uri',
      quality: options.quality ?? 90,
    });
    return result as FilterResult;
  } catch (error) {
    throw new Error(`Failed to resize image: ${error}`);
  }
}

/**
 * Rotate an image by specified degrees
 * @param options Rotation options
 * @returns Promise resolving to rotated image result
 * @example
 * const result = await rotateImage({
 *   sourceUri: 'file:///path/to/image.jpg',
 *   degrees: 90,
 *   expand: true,
 *   returnFormat: 'uri',
 *   quality: 90,
 * });
 */
export async function rotateImage(options: RotateImageOptions): Promise<FilterResult> {
  try {
    const result = await ImageFilters.rotateImage({
      sourceUri: options.sourceUri,
      degrees: options.degrees,
      expand: options.expand ?? true,
      returnFormat: options.returnFormat ?? 'uri',
      quality: options.quality ?? 90,
    });
    return result as FilterResult;
  } catch (error) {
    throw new Error(`Failed to rotate image: ${error}`);
  }
}

/**
 * Get list of available filters
 * @param type Optional filter type ('document', 'photo', or 'custom')
 * @returns Promise resolving to array of filter names
 * @example
 * const documentFilters = await getAvailableFilters('document');
 * const allFilters = await getAvailableFilters();
 */
export async function getAvailableFilters(type?: FilterType): Promise<string[]> {
  try {
    // Return cached filter names for better performance
    if (type === 'document') {
      return getDocumentFilterNames();
    } else if (type === 'photo') {
      return getPhotoFilterNames();
    } else if (type === 'custom') {
      return ['custom'];
    }
    
    // Get all filters from native module
    return await ImageFilters.getAvailableFilters(type);
  } catch (error) {
    // Fallback to static list if native call fails
    if (type === 'document') {
      return getDocumentFilterNames();
    } else if (type === 'photo') {
      return getPhotoFilterNames();
    } else if (type === 'custom') {
      return ['custom'];
    }
    return [...getDocumentFilterNames(), ...getPhotoFilterNames(), 'custom'];
  }
}

/**
 * Get metadata for a specific filter
 * @param name Filter name
 * @returns Filter metadata or undefined if not found
 * @example
 * const metadata = getFilterMetadata('sepia');
 */
export function getFilterMetadata(name: FilterName): FilterMetadata | undefined {
  const allFilters = [...DOCUMENT_FILTERS, ...PHOTO_FILTERS, CUSTOM_FILTER];
  return allFilters.find(f => f.name === name);
}

/**
 * Get all filter metadata
 * @param type Optional filter type to filter by
 * @returns Array of filter metadata
 * @example
 * const photoFilters = getAllFilterMetadata('photo');
 */
export function getAllFilterMetadata(type?: FilterType): FilterMetadata[] {
  const allFilters = [...DOCUMENT_FILTERS, ...PHOTO_FILTERS, CUSTOM_FILTER];
  if (type) {
    return allFilters.filter(f => f.category === type);
  }
  return allFilters;
}

/**
 * Preload an image into cache for faster processing
 * @param uri Image URI to preload
 * @returns Promise that resolves when image is cached
 * @example
 * await preloadImage('https://example.com/image.jpg');
 */
export async function preloadImage(uri: string): Promise<void> {
  try {
    await ImageFilters.preloadImage(uri);
  } catch (error) {
    throw new Error(`Failed to preload image: ${error}`);
  }
}

/**
 * Clear the image cache
 * @returns Promise that resolves when cache is cleared
 * @example
 * await clearCache();
 */
export async function clearCache(): Promise<void> {
  try {
    await ImageFilters.clearCache();
  } catch (error) {
    throw new Error(`Failed to clear cache: ${error}`);
  }
}

/**
 * Check if a filter name is valid
 * @param name Filter name to check
 * @returns True if filter exists
 * @example
 * if (isValidFilter('sepia')) {
 *   // apply filter
 * }
 */
export function isValidFilter(name: string): boolean {
  const allFilterNames = [
    ...getDocumentFilterNames(),
    ...getPhotoFilterNames(),
    'custom',
  ];
  return allFilterNames.includes(name);
}

export default {
  applyFilter,
  applyFilters,
  cropImage,
  resizeImage,
  rotateImage,
  getAvailableFilters,
  getFilterMetadata,
  getAllFilterMetadata,
  preloadImage,
  clearCache,
  isValidFilter,
};

