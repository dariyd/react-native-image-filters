import React, { useEffect, useCallback } from 'react';
import {
  requireNativeComponent,
  UIManager,
  Platform,
  StyleSheet,
  View,
  type ViewStyle,
} from 'react-native';
import type { FilteredImageViewProps, ImageSource } from './types';

const COMPONENT_NAME = 'FilteredImageView';

// Native component interface
interface NativeFilteredImageViewProps {
  sourceUri: string;
  filter: string;
  intensity: number;
  customParams?: Record<string, any>;
  resizeMode: string;
  style?: ViewStyle;
  onFilterApplied?: () => void;
  onError?: (event: { nativeEvent: { error: string } }) => void;
}

const NativeFilteredImageView =
  UIManager.getViewManagerConfig(COMPONENT_NAME) != null
    ? requireNativeComponent<NativeFilteredImageViewProps>(COMPONENT_NAME)
    : () => {
        throw new Error(
          `The package 'react-native-image-filters' doesn't seem to be linked. Make sure: \n\n` +
            Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
            '- You rebuilt the app after installing the package\n' +
            '- You are not using Expo Go\n'
        );
      };

/**
 * FilteredImageView component for real-time filter preview
 * 
 * Displays an image with a filter applied in real-time using GPU acceleration.
 * Changes to filter or intensity are reflected immediately without disk I/O.
 * 
 * @example
 * <FilteredImageView
 *   source={{ uri: 'https://example.com/image.jpg' }}
 *   filter="sepia"
 *   intensity={0.8}
 *   style={{ width: 300, height: 400 }}
 *   onFilterApplied={() => console.log('Filter applied!')}
 *   onError={(error) => console.error('Filter error:', error)}
 * />
 */
export function FilteredImageView({
  source,
  filter,
  intensity = 1.0,
  customParams = {},
  style,
  onFilterApplied,
  onError,
  resizeMode = 'cover',
}: FilteredImageViewProps): React.ReactElement {
  // Parse source URI
  const sourceUri = typeof source === 'string' ? source : source.uri;

  // Handle error callback
  const handleError = useCallback(
    (event: { nativeEvent: { error: string } }) => {
      if (onError) {
        onError(new Error(event.nativeEvent.error));
      }
    },
    [onError]
  );

  // Handle filter applied callback
  const handleFilterApplied = useCallback(() => {
    if (onFilterApplied) {
      onFilterApplied();
    }
  }, [onFilterApplied]);

  // Validate props
  useEffect(() => {
    if (!sourceUri) {
      console.warn('FilteredImageView: source URI is required');
    }
    if (!filter) {
      console.warn('FilteredImageView: filter is required');
    }
    if (intensity < 0 || intensity > 1) {
      console.warn('FilteredImageView: intensity should be between 0 and 1');
    }
  }, [sourceUri, filter, intensity]);

  if (!sourceUri || !filter) {
    return <View style={[styles.placeholder, style]} />;
  }

  // Prepare props - only include customParams if it's not empty
  const nativeProps: NativeFilteredImageViewProps = {
    sourceUri,
    filter,
    intensity: Math.max(0, Math.min(1, intensity)),
    resizeMode,
    style,
    onFilterApplied: handleFilterApplied,
    onError: handleError,
  };

  // Only add customParams if it has values
  if (customParams && Object.keys(customParams).length > 0) {
    nativeProps.customParams = customParams;
  }

  return <NativeFilteredImageView {...nativeProps} />;
}

const styles = StyleSheet.create({
  placeholder: {
    backgroundColor: '#f0f0f0',
  },
});

export default FilteredImageView;

