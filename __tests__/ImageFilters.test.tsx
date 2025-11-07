import {
  applyFilter,
  applyFilters,
  getAvailableFilters,
  getFilterMetadata,
  getAllFilterMetadata,
  isValidFilter,
  preloadImage,
  clearCache,
} from '../src/index';

// Mock the native module
jest.mock('../src/NativeImageFilters', () => ({
  __esModule: true,
  default: {
    applyFilter: jest.fn(),
    applyFilters: jest.fn(),
    getAvailableFilters: jest.fn(),
    preloadImage: jest.fn(),
    clearCache: jest.fn(),
  },
}));

describe('ImageFilters', () => {
  describe('applyFilter', () => {
    it('should apply a filter with default options', async () => {
      const mockResult = {
        uri: 'file:///path/to/filtered.jpg',
        width: 800,
        height: 600,
      };

      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.applyFilter.mockResolvedValue(mockResult);

      const result = await applyFilter({
        sourceUri: 'file:///path/to/image.jpg',
        filter: 'sepia',
      });

      expect(result).toEqual(mockResult);
      expect(NativeImageFilters.applyFilter).toHaveBeenCalledWith({
        sourceUri: 'file:///path/to/image.jpg',
        filter: 'sepia',
        intensity: 1.0,
        customParams: {},
        returnFormat: 'uri',
        quality: 90,
      });
    });

    it('should apply a filter with custom options', async () => {
      const mockResult = {
        uri: 'file:///path/to/filtered.jpg',
        base64: 'base64data...',
        width: 800,
        height: 600,
      };

      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.applyFilter.mockResolvedValue(mockResult);

      const result = await applyFilter({
        sourceUri: 'https://example.com/image.jpg',
        filter: 'vivid',
        intensity: 0.7,
        customParams: { saturation: 1.5 },
        returnFormat: 'both',
        quality: 80,
      });

      expect(result).toEqual(mockResult);
      expect(NativeImageFilters.applyFilter).toHaveBeenCalledWith({
        sourceUri: 'https://example.com/image.jpg',
        filter: 'vivid',
        intensity: 0.7,
        customParams: { saturation: 1.5 },
        returnFormat: 'both',
        quality: 80,
      });
    });

    it('should handle errors', async () => {
      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.applyFilter.mockRejectedValue(
        new Error('Image not found')
      );

      await expect(
        applyFilter({
          sourceUri: 'invalid-uri',
          filter: 'sepia',
        })
      ).rejects.toThrow('Failed to apply filter');
    });
  });

  describe('applyFilters', () => {
    it('should apply multiple filters', async () => {
      const mockResults = [
        { uri: 'file:///filtered1.jpg', width: 800, height: 600 },
        { uri: 'file:///filtered2.jpg', width: 1024, height: 768 },
      ];

      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.applyFilters.mockResolvedValue(mockResults);

      const results = await applyFilters([
        { sourceUri: 'image1.jpg', filter: 'sepia' },
        { sourceUri: 'image2.jpg', filter: 'vivid' },
      ]);

      expect(results).toEqual(mockResults);
      expect(NativeImageFilters.applyFilters).toHaveBeenCalled();
    });
  });

  describe('getAvailableFilters', () => {
    it('should return document filters', async () => {
      const result = await getAvailableFilters('document');
      expect(result).toContain('scan');
      expect(result).toContain('blackWhite');
      expect(result).toContain('enhance');
    });

    it('should return photo filters', async () => {
      const result = await getAvailableFilters('photo');
      expect(result).toContain('sepia');
      expect(result).toContain('vivid');
      expect(result).toContain('dramatic');
    });

    it('should return all filters when no type specified', async () => {
      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.getAvailableFilters.mockResolvedValue([
        'scan',
        'sepia',
        'custom',
      ]);

      const result = await getAvailableFilters();
      expect(result.length).toBeGreaterThan(0);
    });
  });

  describe('getFilterMetadata', () => {
    it('should return metadata for a valid filter', () => {
      const metadata = getFilterMetadata('sepia');
      expect(metadata).toBeDefined();
      expect(metadata?.name).toBe('sepia');
      expect(metadata?.displayName).toBe('Sepia');
      expect(metadata?.category).toBe('photo');
    });

    it('should return undefined for invalid filter', () => {
      const metadata = getFilterMetadata('invalid-filter' as any);
      expect(metadata).toBeUndefined();
    });
  });

  describe('getAllFilterMetadata', () => {
    it('should return all filter metadata', () => {
      const metadata = getAllFilterMetadata();
      expect(metadata.length).toBeGreaterThan(0);
      expect(metadata.every((m) => m.name && m.displayName)).toBe(true);
    });

    it('should filter by type', () => {
      const documentMetadata = getAllFilterMetadata('document');
      expect(
        documentMetadata.every((m) => m.category === 'document')
      ).toBe(true);

      const photoMetadata = getAllFilterMetadata('photo');
      expect(photoMetadata.every((m) => m.category === 'photo')).toBe(
        true
      );
    });
  });

  describe('isValidFilter', () => {
    it('should return true for valid filters', () => {
      expect(isValidFilter('sepia')).toBe(true);
      expect(isValidFilter('scan')).toBe(true);
      expect(isValidFilter('custom')).toBe(true);
    });

    it('should return false for invalid filters', () => {
      expect(isValidFilter('invalid')).toBe(false);
      expect(isValidFilter('')).toBe(false);
    });
  });

  describe('preloadImage', () => {
    it('should preload an image', async () => {
      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.preloadImage.mockResolvedValue(undefined);

      await expect(
        preloadImage('https://example.com/image.jpg')
      ).resolves.toBeUndefined();

      expect(NativeImageFilters.preloadImage).toHaveBeenCalledWith(
        'https://example.com/image.jpg'
      );
    });

    it('should handle preload errors', async () => {
      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.preloadImage.mockRejectedValue(
        new Error('Network error')
      );

      await expect(
        preloadImage('https://invalid.com/image.jpg')
      ).rejects.toThrow('Failed to preload image');
    });
  });

  describe('clearCache', () => {
    it('should clear the cache', async () => {
      const NativeImageFilters = require('../src/NativeImageFilters').default;
      NativeImageFilters.clearCache.mockResolvedValue(undefined);

      await expect(clearCache()).resolves.toBeUndefined();

      expect(NativeImageFilters.clearCache).toHaveBeenCalled();
    });
  });
});

