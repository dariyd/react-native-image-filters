import type { ViewProps } from 'react-native';

/**
 * Filter category types
 */
export type FilterType = 'document' | 'photo' | 'custom';

/**
 * Document scanning filter names
 */
export type DocumentFilter =
  | 'scan'
  | 'blackWhite'
  | 'enhance'
  | 'perspective'
  | 'grayscale'
  | 'colorPop';

/**
 * Photo editing filter names (Instagram-style)
 */
export type PhotoFilter =
  | 'sepia'
  | 'noir'
  | 'fade'
  | 'chrome'
  | 'transfer'
  | 'instant'
  | 'vivid'
  | 'dramatic'
  | 'warm'
  | 'cool'
  | 'vintage'
  | 'clarendon'
  | 'gingham'
  | 'juno'
  | 'lark'
  | 'luna'
  | 'reyes'
  | 'valencia'
  | 'brooklyn'
  | 'earlybird'
  | 'hudson'
  | 'inkwell'
  | 'lofi'
  | 'mayfair'
  | 'nashville'
  | 'perpetua'
  | 'toaster'
  | 'walden'
  | 'xpro2';

/**
 * All filter names
 */
export type FilterName = DocumentFilter | PhotoFilter | 'custom';

/**
 * Return format for filtered images
 */
export type ReturnFormat = 'uri' | 'base64' | 'both';

/**
 * Crop rectangle coordinates
 */
export interface CropRect {
  /** X coordinate (top-left) */
  x: number;
  /** Y coordinate (top-left) */
  y: number;
  /** Width of crop area */
  width: number;
  /** Height of crop area */
  height: number;
}

/**
 * Resize mode for image operations
 */
export type ResizeMode = 'cover' | 'contain' | 'stretch';

/**
 * Custom filter parameters for adjustable properties
 */
export interface CustomFilterParams {
  brightness?: number;
  contrast?: number;
  saturation?: number;
  exposure?: number;
  highlights?: number;
  shadows?: number;
  temperature?: number;
  tint?: number;
  sharpness?: number;
  vibrance?: number;
  hue?: number;
  gamma?: number;
  [key: string]: number | string | boolean | undefined;
}

/**
 * Options for applying a filter to an image
 */
export interface ApplyFilterOptions {
  /** Source image URI (local file:// or remote https://) */
  sourceUri: string;
  /** Filter name to apply */
  filter: FilterName;
  /** Filter intensity (0-1, default 1) */
  intensity?: number;
  /** Custom filter parameters */
  customParams?: CustomFilterParams;
  /** Output format (default 'uri') */
  returnFormat?: ReturnFormat;
  /** Output image quality (0-100, default 90) */
  quality?: number;
}

/**
 * Result of filter application
 */
export interface FilterResult {
  /** File URI to filtered image (if returnFormat includes 'uri') */
  uri?: string;
  /** Base64 encoded image data (if returnFormat includes 'base64') */
  base64?: string;
  /** Image width in pixels */
  width: number;
  /** Image height in pixels */
  height: number;
}

/**
 * Options for cropping an image
 */
export interface CropImageOptions {
  /** Source image URI (local file:// or remote https://) */
  sourceUri: string;
  /** Crop rectangle */
  cropRect: CropRect;
  /** Output format (default 'uri') */
  returnFormat?: ReturnFormat;
  /** Output image quality (0-100, default 90) */
  quality?: number;
}

/**
 * Options for resizing an image
 */
export interface ResizeImageOptions {
  /** Source image URI (local file:// or remote https://) */
  sourceUri: string;
  /** Target width in pixels (optional if height is set) */
  width?: number;
  /** Target height in pixels (optional if width is set) */
  height?: number;
  /** Resize mode (default 'contain') */
  mode?: ResizeMode;
  /** Output format (default 'uri') */
  returnFormat?: ReturnFormat;
  /** Output image quality (0-100, default 90) */
  quality?: number;
}

/**
 * Options for rotating an image
 */
export interface RotateImageOptions {
  /** Source image URI (local file:// or remote https://) */
  sourceUri: string;
  /** Rotation degrees (clockwise) */
  degrees: number;
  /** Expand canvas to fit rotated image (default true) */
  expand?: boolean;
  /** Output format (default 'uri') */
  returnFormat?: ReturnFormat;
  /** Output image quality (0-100, default 90) */
  quality?: number;
}

/**
 * Image source for components
 */
export type ImageSource = string | { uri: string };

/**
 * Props for FilteredImageView component
 */
export interface FilteredImageViewProps extends ViewProps {
  /** Image source (local or remote URI) */
  source: ImageSource;
  /** Filter to apply */
  filter: FilterName;
  /** Filter intensity (0-1, default 1) */
  intensity?: number;
  /** Custom filter parameters */
  customParams?: CustomFilterParams;
  /** Callback when filter is applied */
  onFilterApplied?: () => void;
  /** Error callback */
  onError?: (error: Error) => void;
  /** Content mode for image display */
  resizeMode?: 'cover' | 'contain' | 'stretch' | 'center';
}

/**
 * Filter metadata
 */
export interface FilterMetadata {
  /** Filter name */
  name: FilterName;
  /** Display name */
  displayName: string;
  /** Filter description */
  description: string;
  /** Filter category */
  category: FilterType;
  /** Whether filter supports intensity adjustment */
  supportsIntensity: boolean;
  /** Available custom parameters */
  customParams?: string[];
}

/**
 * Batch filter operation
 */
export interface BatchFilterOperation {
  /** Operation ID for tracking */
  id?: string;
  /** Filter options */
  options: ApplyFilterOptions;
}

/**
 * Batch filter result
 */
export interface BatchFilterResult extends FilterResult {
  /** Operation ID */
  id?: string;
  /** Whether operation succeeded */
  success: boolean;
  /** Error message if failed */
  error?: string;
}

/**
 * Filter preset configuration
 */
export interface FilterPreset {
  /** Preset name */
  name: string;
  /** Filter to use */
  filter: FilterName;
  /** Preset intensity */
  intensity?: number;
  /** Preset custom parameters */
  customParams?: CustomFilterParams;
}

/**
 * Image loading cache options
 */
export interface CacheOptions {
  /** Maximum cache size in MB */
  maxSize?: number;
  /** Cache TTL in seconds */
  ttl?: number;
}

/**
 * Props for CropperView component
 */
export interface CropperViewProps extends ViewProps {
  /** Image source (local or remote URI) */
  source: ImageSource;
  /** Initial crop rectangle (optional) */
  initialCropRect?: CropRect;
  /** Fixed aspect ratio (e.g., 16/9, 1 for square, undefined for free) */
  aspectRatio?: number;
  /** Minimum crop size */
  minCropSize?: { width: number; height: number };
  /** Callback when crop rectangle changes */
  onCropRectChange?: (rect: CropRect) => void;
  /** Callback when user finishes gesture */
  onGestureEnd?: (rect: CropRect) => void;
  /** Show grid overlay */
  showGrid?: boolean;
  /** Grid color */
  gridColor?: string;
  /** Overlay color */
  overlayColor?: string;
}

/**
 * Native module spec interface
 */
export interface NativeImageFiltersSpec {
  applyFilter(options: Record<string, any>): Promise<Record<string, any>>;
  applyFilters(optionsArray: Array<Record<string, any>>): Promise<Array<Record<string, any>>>;
  cropImage(options: Record<string, any>): Promise<Record<string, any>>;
  resizeImage(options: Record<string, any>): Promise<Record<string, any>>;
  rotateImage(options: Record<string, any>): Promise<Record<string, any>>;
  getAvailableFilters(type?: string): Promise<string[]>;
  preloadImage(uri: string): Promise<void>;
  clearCache(): Promise<void>;
}

