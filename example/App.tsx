import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Image,
  Alert,
  ActivityIndicator,
  Dimensions,
  SafeAreaView,
} from 'react-native';
import Slider from '@react-native-community/slider';
import {
  FilteredImageView,
  CropperView,
  applyFilter,
  cropImage,
  resizeImage,
  rotateImage,
  getAvailableFilters,
  type FilterName,
  type CropRect,
} from '@dariyd/react-native-image-filters';

const { width } = Dimensions.get('window');

// Sample images - using specific image IDs from picsum to avoid caching issues
const SAMPLE_IMAGES = [
  'https://picsum.photos/id/237/800/600', // Dog
  'https://picsum.photos/id/1015/800/600', // Mountain
  'https://picsum.photos/id/1025/800/600', // Puppy
];

const FILTER_CATEGORIES = {
  document: 'Document Scanning',
  photo: 'Photo Effects',
};

export default function App() {
  const [selectedImage, setSelectedImage] = useState(SAMPLE_IMAGES[0]);
  const [selectedFilter, setSelectedFilter] = useState<FilterName>('sepia');
  const [intensity, setIntensity] = useState(1.0);
  const [documentFilters, setDocumentFilters] = useState<string[]>([]);
  const [photoFilters, setPhotoFilters] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [savedImageUri, setSavedImageUri] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'preview' | 'saved' | 'transform'>('preview');
  const [showOriginal, setShowOriginal] = useState(false);
  
  // Transform tab state
  const [cropRect, setCropRect] = useState<CropRect | null>(null);
  const [transformedImageUri, setTransformedImageUri] = useState<string | null>(null);
  const [rotationDegrees, setRotationDegrees] = useState(0);
  const [resizeWidth, setResizeWidth] = useState(800);
  const [resizeHeight, setResizeHeight] = useState(600);

  useEffect(() => {
    loadFilters();
  }, []);

  const loadFilters = async () => {
    try {
      const docFilters = await getAvailableFilters('document');
      const phtFilters = await getAvailableFilters('photo');
      setDocumentFilters(docFilters);
      setPhotoFilters(phtFilters);
    } catch (error) {
      console.error('Failed to load filters:', error);
}
  };

  const handleSaveImage = async () => {
    setLoading(true);
    try {
      const result = await applyFilter({
        sourceUri: selectedImage,
        filter: selectedFilter,
        intensity,
        returnFormat: 'uri',
        quality: 90,
      });

      setSavedImageUri(result.uri || null);
      setActiveTab('saved');
      Alert.alert('Success', 'Image saved successfully!');
    } catch (error) {
      Alert.alert('Error', `Failed to save image: ${error}`);
    } finally {
      setLoading(false);
    }
  };
  
  const handleCrop = async () => {
    if (!cropRect) {
      Alert.alert('Error', 'Please select a crop area first');
      return;
    }
    
    setLoading(true);
    try {
      const result = await cropImage({
        sourceUri: selectedImage,
        cropRect,
        returnFormat: 'uri',
        quality: 90,
      });
      
      setTransformedImageUri(result.uri || null);
      Alert.alert('Success', `Image cropped! ${result.width}x${result.height}px`);
    } catch (error) {
      Alert.alert('Error', `Failed to crop image: ${error}`);
    } finally {
      setLoading(false);
    }
  };
  
  const handleResize = async () => {
    setLoading(true);
    try {
      const result = await resizeImage({
        sourceUri: selectedImage,
        width: resizeWidth,
        height: resizeHeight,
        mode: 'contain',
        returnFormat: 'uri',
        quality: 90,
      });
      
      setTransformedImageUri(result.uri || null);
      Alert.alert('Success', `Image resized to ${result.width}x${result.height}px`);
    } catch (error) {
      Alert.alert('Error', `Failed to resize image: ${error}`);
    } finally {
      setLoading(false);
    }
  };
  
  const handleRotate = async () => {
    setLoading(true);
    try {
      const result = await rotateImage({
        sourceUri: selectedImage,
        degrees: rotationDegrees,
        expand: true,
        returnFormat: 'uri',
        quality: 90,
      });
      
      setTransformedImageUri(result.uri || null);
      Alert.alert('Success', `Image rotated by ${rotationDegrees}°`);
    } catch (error) {
      Alert.alert('Error', `Failed to rotate image: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Image Filters Demo</Text>
        <Text style={styles.headerSubtitle}>
          GPU-accelerated filters for React Native
        </Text>
      </View>

      {/* Tab Bar */}
      <View style={styles.tabBar}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'preview' && styles.activeTab]}
          onPress={() => setActiveTab('preview')}>
          <Text
            style={[
              styles.tabText,
              activeTab === 'preview' && styles.activeTabText,
            ]}>
            Filters
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'transform' && styles.activeTab]}
          onPress={() => setActiveTab('transform')}>
          <Text
            style={[
              styles.tabText,
              activeTab === 'transform' && styles.activeTabText,
            ]}>
            Transform
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'saved' && styles.activeTab]}
          onPress={() => setActiveTab('saved')}>
          <Text
            style={[
              styles.tabText,
              activeTab === 'saved' && styles.activeTabText,
            ]}>
            Saved
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content}>
        {/* Image Preview */}
        {activeTab === 'preview' ? (
          <View style={styles.imageContainer}>
            {showOriginal ? (
              <Image
                source={{ uri: selectedImage }}
                style={styles.filteredImage}
                resizeMode="cover"
              />
            ) : (
              <FilteredImageView
                source={{ uri: selectedImage }}
                filter={selectedFilter}
                intensity={intensity}
                style={styles.filteredImage}
                resizeMode="cover"
                onFilterApplied={() => console.log('Filter applied!')}
                onError={(error) => console.error('Filter error:', error)}
              />
            )}
          </View>
        ) : activeTab === 'transform' ? (
          <>
            <View style={styles.imageContainer}>
              {transformedImageUri ? (
                <Image
                  source={{ uri: transformedImageUri }}
                  style={styles.filteredImage}
                  resizeMode="contain"
                />
              ) : (
                <CropperView
                  source={{ uri: selectedImage }}
                  aspectRatio={undefined}
                  showGrid={true}
                  onCropRectChange={(rect) => setCropRect(rect)}
                  onGestureEnd={(rect) => {
                    console.log('Crop rect:', rect);
                    setCropRect(rect);
                  }}
                  style={styles.filteredImage}
                />
              )}
            </View>
            
            {transformedImageUri && (
              <TouchableOpacity
                style={styles.resetButton}
                onPress={() => setTransformedImageUri(null)}>
                <Text style={styles.resetButtonText}>Back to Cropper</Text>
              </TouchableOpacity>
            )}
            
            <View style={styles.transformControls}>
              <Text style={styles.sectionTitle}>Transform Operations</Text>
              
              {/* Crop Button */}
              <TouchableOpacity
                style={styles.transformButton}
                onPress={handleCrop}
                disabled={loading || !cropRect}>
                {loading ? (
                  <ActivityIndicator color="#FFF" />
                ) : (
                  <Text style={styles.transformButtonText}>
                    📐 Crop Image
                    {cropRect && ` (${Math.round(cropRect.width)}x${Math.round(cropRect.height)})`}
                  </Text>
                )}
              </TouchableOpacity>
              
              {/* Resize Controls */}
              <View style={styles.controlRow}>
                <Text style={styles.controlLabel}>Resize to:</Text>
                <View style={styles.dimensionInputs}>
                  <TouchableOpacity
                    style={styles.dimensionButton}
                    onPress={() => {
                      setResizeWidth(400);
                      setResizeHeight(300);
                    }}>
                    <Text style={styles.dimensionText}>400x300</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.dimensionButton}
                    onPress={() => {
                      setResizeWidth(800);
                      setResizeHeight(600);
                    }}>
                    <Text style={styles.dimensionText}>800x600</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.dimensionButton}
                    onPress={() => {
                      setResizeWidth(1024);
                      setResizeHeight(768);
                    }}>
                    <Text style={styles.dimensionText}>1024x768</Text>
                  </TouchableOpacity>
                </View>
              </View>
              
              <TouchableOpacity
                style={styles.transformButton}
                onPress={handleResize}
                disabled={loading}>
                {loading ? (
                  <ActivityIndicator color="#FFF" />
                ) : (
                  <Text style={styles.transformButtonText}>
                    🔍 Resize to {resizeWidth}x{resizeHeight}
                  </Text>
                )}
              </TouchableOpacity>
              
              {/* Rotate Controls */}
              <View style={styles.controlRow}>
                <Text style={styles.controlLabel}>Rotation: {rotationDegrees}°</Text>
              </View>
              <Slider
                style={styles.slider}
                minimumValue={-180}
                maximumValue={180}
                value={rotationDegrees}
                onValueChange={setRotationDegrees}
                step={15}
                minimumTrackTintColor="#007AFF"
                maximumTrackTintColor="#E0E0E0"
              />
              
              <View style={styles.quickRotateButtons}>
                <TouchableOpacity
                  style={styles.quickRotateButton}
                  onPress={() => setRotationDegrees(-90)}>
                  <Text style={styles.quickRotateText}>↺ -90°</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.quickRotateButton}
                  onPress={() => setRotationDegrees(0)}>
                  <Text style={styles.quickRotateText}>↻ 0°</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.quickRotateButton}
                  onPress={() => setRotationDegrees(90)}>
                  <Text style={styles.quickRotateText}>↻ 90°</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.quickRotateButton}
                  onPress={() => setRotationDegrees(180)}>
                  <Text style={styles.quickRotateText}>↻ 180°</Text>
                </TouchableOpacity>
              </View>
              
              <TouchableOpacity
                style={styles.transformButton}
                onPress={handleRotate}
                disabled={loading}>
                {loading ? (
                  <ActivityIndicator color="#FFF" />
                ) : (
                  <Text style={styles.transformButtonText}>
                    🔄 Rotate {rotationDegrees}°
                  </Text>
                )}
              </TouchableOpacity>
            </View>
          </>
        ) : (
          <View style={styles.imageContainer}>
            {savedImageUri ? (
              <Image
                source={{ uri: savedImageUri }}
                style={styles.filteredImage}
                resizeMode="cover"
              />
            ) : (
              <View style={styles.placeholder}>
                <Text style={styles.placeholderText}>
                  No saved image yet. Apply and save a filter first!
                </Text>
              </View>
            )}
          </View>
        )}

        {/* Intensity Slider */}
        {activeTab === 'preview' && !showOriginal && (
          <View style={styles.sliderContainer}>
            <Text style={styles.label}>
              Intensity: {(intensity * 100).toFixed(0)}%
            </Text>
            <Slider
              style={styles.slider}
              minimumValue={0}
              maximumValue={1}
              value={intensity}
              onValueChange={setIntensity}
              minimumTrackTintColor="#007AFF"
              maximumTrackTintColor="#E0E0E0"
      />
    </View>
        )}

        {/* Show Original / Apply Filter Toggle */}
        {activeTab === 'preview' && (
          <TouchableOpacity
            style={[
              styles.originalButton,
              showOriginal && styles.originalButtonActive,
            ]}
            onPress={() => setShowOriginal(!showOriginal)}>
            <Text
              style={[
                styles.originalButtonText,
                showOriginal && styles.originalButtonTextActive,
              ]}>
              {showOriginal ? '✓ Original Image' : 'Show Original'}
            </Text>
          </TouchableOpacity>
        )}

        {/* Save Button */}
        {activeTab === 'preview' && !showOriginal && (
          <TouchableOpacity
            style={styles.saveButton}
            onPress={handleSaveImage}
            disabled={loading}>
            {loading ? (
              <ActivityIndicator color="#FFF" />
            ) : (
              <Text style={styles.saveButtonText}>Save Filtered Image</Text>
            )}
          </TouchableOpacity>
        )}

        

        {/* Document Filters */}
        {activeTab === 'preview' && !showOriginal && documentFilters.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>
              {FILTER_CATEGORIES.document}
            </Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View style={styles.filterList}>
                {documentFilters.map((filter) => (
                  <TouchableOpacity
                    key={filter}
                    style={[
                      styles.filterButton,
                      selectedFilter === filter && styles.selectedFilter,
                    ]}
                    onPress={() => setSelectedFilter(filter as FilterName)}>
                    <Text
                      style={[
                        styles.filterButtonText,
                        selectedFilter === filter &&
                          styles.selectedFilterText,
                      ]}>
                      {filter}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </>
        )}

        {/* Photo Filters */}
        {activeTab === 'preview' && !showOriginal && photoFilters.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>{FILTER_CATEGORIES.photo}</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View style={styles.filterList}>
                {photoFilters.map((filter) => (
                  <TouchableOpacity
                    key={filter}
                    style={[
                      styles.filterButton,
                      selectedFilter === filter && styles.selectedFilter,
                    ]}
                    onPress={() => setSelectedFilter(filter as FilterName)}>
                    <Text
                      style={[
                        styles.filterButtonText,
                        selectedFilter === filter &&
                          styles.selectedFilterText,
                      ]}>
                      {filter}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </>
        )}

        {/* Sample Images Selector */}
        {activeTab === 'preview' && !showOriginal && (
          <>
            <Text style={styles.sectionTitle}>Select Image</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View style={styles.imageSelector}>
                {SAMPLE_IMAGES.map((uri, index) => (
                  <TouchableOpacity
                    key={index}
                    onPress={() => setSelectedImage(uri)}>
                    <Image
                      source={{ uri }}
                      style={[
                        styles.thumbnailImage,
                        selectedImage === uri && styles.selectedThumbnail,
                      ]}
                    />
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </>
        )}

        <View style={styles.footer}>
          <Text style={styles.footerText}>
            {documentFilters.length + photoFilters.length} filters available
          </Text>
          <Text style={styles.footerText}>
            Powered by Metal (iOS) & GPU (Android)
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  header: {
    backgroundColor: '#007AFF',
    padding: 20,
    paddingTop: 10,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFF',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#E0E0E0',
    marginTop: 5,
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E0E0E0',
  },
  tab: {
    flex: 1,
    paddingVertical: 15,
    alignItems: 'center',
  },
  activeTab: {
    borderBottomWidth: 2,
    borderBottomColor: '#007AFF',
  },
  tabText: {
    fontSize: 16,
    color: '#666',
  },
  activeTabText: {
    color: '#007AFF',
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  imageContainer: {
    width: width,
    height: width * 0.75,
    backgroundColor: '#000',
  },
  filteredImage: {
    width: '100%',
    height: '100%',
  },
  placeholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
  },
  placeholderText: {
    fontSize: 16,
    color: '#999',
    textAlign: 'center',
  },
  sliderContainer: {
    padding: 20,
    backgroundColor: '#FFF',
    marginTop: 10,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 10,
    color: '#333',
  },
  slider: {
    width: '100%',
    height: 40,
  },
  originalButton: {
    backgroundColor: '#FFF',
    padding: 15,
    marginHorizontal: 20,
    marginTop: 10,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#007AFF',
  },
  originalButtonActive: {
    backgroundColor: '#007AFF',
  },
  originalButtonText: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: '600',
  },
  originalButtonTextActive: {
    color: '#FFF',
  },
  saveButton: {
    backgroundColor: '#007AFF',
    padding: 15,
    margin: 20,
    marginTop: 10,
    borderRadius: 8,
    alignItems: 'center',
  },
  saveButtonText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 10,
  },
  imageSelector: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingBottom: 10,
  },
  thumbnailImage: {
    width: 100,
    height: 100,
    borderRadius: 8,
    marginRight: 10,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedThumbnail: {
    borderColor: '#007AFF',
  },
  filterList: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingBottom: 10,
  },
  filterButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: '#FFF',
    borderRadius: 20,
    marginRight: 10,
    borderWidth: 1,
    borderColor: '#E0E0E0',
  },
  selectedFilter: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  filterButtonText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  selectedFilterText: {
    color: '#FFF',
  },
  footer: {
    padding: 20,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#999',
    marginBottom: 5,
  },
  transformControls: {
    padding: 20,
    backgroundColor: '#FFF',
    marginTop: 10,
  },
  transformButton: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  transformButtonText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
  },
  resetButton: {
    backgroundColor: '#FFF',
    padding: 15,
    marginHorizontal: 20,
    marginTop: 10,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#007AFF',
  },
  resetButtonText: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: '600',
  },
  controlRow: {
    marginTop: 15,
  },
  controlLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 10,
  },
  dimensionInputs: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 5,
  },
  dimensionButton: {
    flex: 1,
    padding: 10,
    backgroundColor: '#F0F0F0',
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 5,
  },
  dimensionText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  quickRotateButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginVertical: 10,
  },
  quickRotateButton: {
    flex: 1,
    padding: 10,
    backgroundColor: '#F0F0F0',
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 3,
  },
  quickRotateText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
});
