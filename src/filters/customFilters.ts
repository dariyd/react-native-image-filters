import type { FilterMetadata, CustomFilterParams } from '../types';

/**
 * Custom filter metadata
 */
export const CUSTOM_FILTER: FilterMetadata = {
  name: 'custom',
  displayName: 'Custom Filter',
  description: 'Customizable filter with adjustable parameters',
  category: 'custom',
  supportsIntensity: true,
  customParams: [
    'brightness',
    'contrast',
    'saturation',
    'exposure',
    'highlights',
    'shadows',
    'temperature',
    'tint',
    'sharpness',
    'vibrance',
    'hue',
    'gamma',
  ],
};

/**
 * Default custom filter parameters
 */
export const DEFAULT_CUSTOM_PARAMS: CustomFilterParams = {
  brightness: 1.0,
  contrast: 1.0,
  saturation: 1.0,
  exposure: 1.0,
  highlights: 1.0,
  shadows: 1.0,
  temperature: 0,
  tint: 0,
  sharpness: 1.0,
  vibrance: 1.0,
  hue: 0,
  gamma: 1.0,
};

/**
 * Parameter ranges for validation
 */
export const PARAM_RANGES: Record<string, { min: number; max: number; default: number }> = {
  brightness: { min: 0, max: 2, default: 1.0 },
  contrast: { min: 0, max: 2, default: 1.0 },
  saturation: { min: 0, max: 2, default: 1.0 },
  exposure: { min: 0, max: 2, default: 1.0 },
  highlights: { min: 0, max: 2, default: 1.0 },
  shadows: { min: 0, max: 2, default: 1.0 },
  temperature: { min: -100, max: 100, default: 0 },
  tint: { min: -100, max: 100, default: 0 },
  sharpness: { min: 0, max: 2, default: 1.0 },
  vibrance: { min: 0, max: 2, default: 1.0 },
  hue: { min: -180, max: 180, default: 0 },
  gamma: { min: 0.1, max: 3, default: 1.0 },
};

/**
 * Validate and clamp custom parameters
 */
export function validateCustomParams(params: CustomFilterParams): CustomFilterParams {
  const validated: CustomFilterParams = {};

  for (const [key, value] of Object.entries(params)) {
    if (typeof value === 'number' && PARAM_RANGES[key]) {
      const { min, max } = PARAM_RANGES[key];
      validated[key] = Math.max(min, Math.min(max, value));
    } else {
      validated[key] = value;
    }
  }

  return validated;
}

/**
 * Merge custom parameters with defaults
 */
export function mergeWithDefaults(params?: CustomFilterParams): CustomFilterParams {
  return {
    ...DEFAULT_CUSTOM_PARAMS,
    ...(params ? validateCustomParams(params) : {}),
  };
}

/**
 * Get parameter description
 */
export function getParamDescription(paramName: string): string {
  const descriptions: Record<string, string> = {
    brightness: 'Adjusts overall brightness (0-2, 1.0 = no change)',
    contrast: 'Adjusts contrast (0-2, 1.0 = no change)',
    saturation: 'Adjusts color saturation (0-2, 1.0 = no change)',
    exposure: 'Adjusts exposure (0-2, 1.0 = no change)',
    highlights: 'Adjusts bright areas (0-2, 1.0 = no change)',
    shadows: 'Adjusts dark areas (0-2, 1.0 = no change)',
    temperature: 'Color temperature adjustment (-100 to 100, 0 = no change)',
    tint: 'Green/magenta tint adjustment (-100 to 100, 0 = no change)',
    sharpness: 'Sharpness adjustment (0-2, 1.0 = no change)',
    vibrance: 'Vibrance adjustment (0-2, 1.0 = no change)',
    hue: 'Hue rotation in degrees (-180 to 180, 0 = no change)',
    gamma: 'Gamma correction (0.1-3, 1.0 = no change)',
  };

  return descriptions[paramName] || 'Custom parameter';
}

