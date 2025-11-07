import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  /**
   * Apply a single filter to an image
   * @param options Filter options as a dictionary
   * @returns Promise resolving to filter result
   */
  applyFilter(options: Object): Promise<Object>;

  /**
   * Apply multiple filters to multiple images (batch operation)
   * @param optionsArray Array of filter options
   * @returns Promise resolving to array of filter results
   */
  applyFilters(optionsArray: Array<Object>): Promise<Array<Object>>;

  /**
   * Get list of available filters
   * @param type Optional filter type ('document', 'photo', or 'custom')
   * @returns Promise resolving to array of filter names
   */
  getAvailableFilters(type?: string): Promise<Array<string>>;

  /**
   * Preload an image into cache for faster processing
   * @param uri Image URI to preload
   * @returns Promise that resolves when image is cached
   */
  preloadImage(uri: string): Promise<void>;

  /**
   * Clear the image cache
   * @returns Promise that resolves when cache is cleared
   */
  clearCache(): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ImageFilters');

