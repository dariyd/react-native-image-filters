import type { FilterMetadata, FilterPreset } from '../types';

/**
 * Photo editing filter metadata (Instagram-style)
 */
export const PHOTO_FILTERS: FilterMetadata[] = [
  {
    name: 'sepia',
    displayName: 'Sepia',
    description: 'Classic sepia tone effect',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'noir',
    displayName: 'Noir',
    description: 'High-contrast black and white',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'fade',
    displayName: 'Fade',
    description: 'Faded, washed-out look',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'chrome',
    displayName: 'Chrome',
    description: 'Metallic, high-contrast effect',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'transfer',
    displayName: 'Transfer',
    description: 'Soft, warm vintage effect',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'instant',
    displayName: 'Instant',
    description: 'Polaroid-style instant photo',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'vivid',
    displayName: 'Vivid',
    description: 'Enhanced saturation and contrast',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'dramatic',
    displayName: 'Dramatic',
    description: 'Bold, high-contrast dramatic look',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'warm',
    displayName: 'Warm',
    description: 'Warm temperature and soft glow',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'cool',
    displayName: 'Cool',
    description: 'Cool blue tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'vintage',
    displayName: 'Vintage',
    description: 'Retro film-inspired look',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'clarendon',
    displayName: 'Clarendon',
    description: 'Brightens and adds contrast',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'gingham',
    displayName: 'Gingham',
    description: 'Soft, pastel tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'juno',
    displayName: 'Juno',
    description: 'Enhanced warm tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'lark',
    displayName: 'Lark',
    description: 'Bright, desaturated look',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'luna',
    displayName: 'Luna',
    description: 'Cool, moody tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'reyes',
    displayName: 'Reyes',
    description: 'Vintage with subtle gold tone',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'valencia',
    displayName: 'Valencia',
    description: 'Warm, faded effect',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'brooklyn',
    displayName: 'Brooklyn',
    description: 'Subtle warm filter',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'earlybird',
    displayName: 'Earlybird',
    description: 'Sunrise-inspired warm tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'hudson',
    displayName: 'Hudson',
    description: 'Cool, icy blue tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'inkwell',
    displayName: 'Inkwell',
    description: 'Classic black and white',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'lofi',
    displayName: 'Lo-Fi',
    description: 'Enhanced colors and shadows',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'mayfair',
    displayName: 'Mayfair',
    description: 'Warm center with cool edges',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'nashville',
    displayName: 'Nashville',
    description: 'Warm, pink-tinted filter',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'perpetua',
    displayName: 'Perpetua',
    description: 'Soft, pastel greens and blues',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'toaster',
    displayName: 'Toaster',
    description: 'Vintage with strong vignette',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'walden',
    displayName: 'Walden',
    description: 'Increased exposure and warm tones',
    category: 'photo',
    supportsIntensity: true,
  },
  {
    name: 'xpro2',
    displayName: 'X-Pro II',
    description: 'Cross-processed film look',
    category: 'photo',
    supportsIntensity: true,
  },
];

/**
 * Photo filter presets with specific parameter combinations
 */
export const PHOTO_PRESETS: Record<string, FilterPreset> = {
  portraitEnhance: {
    name: 'Portrait Enhance',
    filter: 'warm',
    intensity: 0.6,
    customParams: {
      temperature: 15,
      saturation: 1.1,
      contrast: 1.05,
    },
  },
  landscapeVivid: {
    name: 'Landscape Vivid',
    filter: 'vivid',
    intensity: 0.8,
    customParams: {
      saturation: 1.3,
      vibrance: 1.2,
      contrast: 1.15,
    },
  },
  softPortrait: {
    name: 'Soft Portrait',
    filter: 'fade',
    intensity: 0.5,
    customParams: {
      contrast: 0.9,
      saturation: 0.95,
      highlights: 1.1,
    },
  },
  dramaticBW: {
    name: 'Dramatic B&W',
    filter: 'noir',
    intensity: 1.0,
    customParams: {
      contrast: 1.4,
      shadows: 0.8,
    },
  },
  sunsetGlow: {
    name: 'Sunset Glow',
    filter: 'warm',
    intensity: 0.9,
    customParams: {
      temperature: 25,
      saturation: 1.15,
      exposure: 1.05,
    },
  },
};

/**
 * Get photo filter by name
 */
export function getPhotoFilter(name: string): FilterMetadata | undefined {
  return PHOTO_FILTERS.find(f => f.name === name);
}

/**
 * Get all photo filter names
 */
export function getPhotoFilterNames(): string[] {
  return PHOTO_FILTERS.map(f => f.name);
}

