import type { FilterMetadata, FilterPreset } from '../types';

/**
 * Document scanning filter metadata
 */
export const DOCUMENT_FILTERS: FilterMetadata[] = [
  {
    name: 'scan',
    displayName: 'Document Scan',
    description:
      'Optimized for document scanning with adaptive threshold, contrast enhancement, and edge detection',
    category: 'document',
    supportsIntensity: true,
    customParams: ['threshold', 'contrast', 'sharpness'],
  },
  {
    name: 'blackWhite',
    displayName: 'Black & White',
    description: 'High-contrast black and white conversion with intelligent noise reduction',
    category: 'document',
    supportsIntensity: true,
    customParams: ['threshold', 'noiseReduction'],
  },
  {
    name: 'enhance',
    displayName: 'Enhance',
    description: 'Smart enhancement of brightness, contrast, and color balance',
    category: 'document',
    supportsIntensity: true,
    customParams: ['brightness', 'contrast', 'saturation', 'sharpness'],
  },
  {
    name: 'perspective',
    displayName: 'Perspective Correction',
    description: 'Automatic perspective correction with corner detection',
    category: 'document',
    supportsIntensity: false,
    customParams: ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'],
  },
  {
    name: 'grayscale',
    displayName: 'Grayscale',
    description: 'Simple grayscale conversion',
    category: 'document',
    supportsIntensity: true,
  },
  {
    name: 'colorPop',
    displayName: 'Color Pop',
    description: 'Increases saturation and clarity for vibrant document colors',
    category: 'document',
    supportsIntensity: true,
    customParams: ['saturation', 'vibrance', 'clarity'],
  },
];

/**
 * Document scanning filter presets
 */
export const DOCUMENT_PRESETS: Record<string, FilterPreset> = {
  standardScan: {
    name: 'Standard Scan',
    filter: 'scan',
    intensity: 1.0,
    customParams: {
      threshold: 0.5,
      contrast: 1.2,
      sharpness: 1.1,
    },
  },
  highContrastScan: {
    name: 'High Contrast Scan',
    filter: 'blackWhite',
    intensity: 1.0,
    customParams: {
      threshold: 0.6,
      noiseReduction: 0.3,
    },
  },
  colorDocument: {
    name: 'Color Document',
    filter: 'enhance',
    intensity: 0.8,
    customParams: {
      brightness: 1.1,
      contrast: 1.15,
      saturation: 1.05,
      sharpness: 1.1,
    },
  },
  whiteboard: {
    name: 'Whiteboard',
    filter: 'scan',
    intensity: 1.0,
    customParams: {
      threshold: 0.7,
      contrast: 1.4,
      sharpness: 1.2,
    },
  },
  receipt: {
    name: 'Receipt',
    filter: 'blackWhite',
    intensity: 1.0,
    customParams: {
      threshold: 0.55,
      noiseReduction: 0.4,
    },
  },
};

/**
 * Get document filter by name
 */
export function getDocumentFilter(name: string): FilterMetadata | undefined {
  return DOCUMENT_FILTERS.find(f => f.name === name);
}

/**
 * Get all document filter names
 */
export function getDocumentFilterNames(): string[] {
  return DOCUMENT_FILTERS.map(f => f.name);
}

