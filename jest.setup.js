// Mock React Native modules
jest.mock('react-native', () => {
  const RN = jest.requireActual('react-native');
  
  RN.NativeModules.ImageFilters = {
    applyFilter: jest.fn(),
    applyFilters: jest.fn(),
    getAvailableFilters: jest.fn(),
    preloadImage: jest.fn(),
    clearCache: jest.fn(),
  };
  
  RN.UIManager.getViewManagerConfig = jest.fn(() => ({}));
  
  return RN;
});

