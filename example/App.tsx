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
  applyFilter,
  getAvailableFilters,
  type FilterName,
} from 'react-native-image-filters';

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
  const [activeTab, setActiveTab] = useState<'preview' | 'saved'>('preview');
  const [showOriginal, setShowOriginal] = useState(false);

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
            Real-time Preview
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
            Saved Image
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
});
