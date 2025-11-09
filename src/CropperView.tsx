import React, { useCallback } from 'react';
import {
  requireNativeComponent,
  UIManager,
  Platform,
  StyleSheet,
  type ViewStyle,
  type StyleProp,
  type NativeSyntheticEvent,
} from 'react-native';
import type { CropperViewProps, CropRect } from './types';

interface NativeCropperViewProps {
  sourceUri: string;
  initialCropRect?: CropRect;
  aspectRatio?: number;
  minCropSize?: { width: number; height: number };
  showGrid?: boolean;
  gridColor?: string;
  overlayColor?: string;
  style?: StyleProp<ViewStyle>;
  onCropRectChange?: (event: NativeSyntheticEvent<{ cropRect: CropRect }>) => void;
  onGestureEnd?: (event: NativeSyntheticEvent<{ cropRect: CropRect }>) => void;
}

const COMPONENT_NAME = 'CropperView';

const NativeCropperView =
  requireNativeComponent<NativeCropperViewProps>(COMPONENT_NAME);

/**
 * Interactive image cropper component with gesture support
 * 
 * Features:
 * - Pinch to zoom
 * - Pan to move
 * - Drag corners/edges to resize crop area
 * - Aspect ratio locking
 * - Grid overlay
 * - Real-time crop rect updates
 * 
 * @example
 * ```tsx
 * <CropperView
 *   source={{ uri: 'file:///path/to/image.jpg' }}
 *   aspectRatio={16/9}
 *   showGrid={true}
 *   onCropRectChange={(rect) => console.log('Crop rect:', rect)}
 *   onGestureEnd={(rect) => console.log('Final rect:', rect)}
 *   style={{ width: '100%', height: 400 }}
 * />
 * ```
 */
export const CropperView: React.FC<CropperViewProps> = ({
  source,
  initialCropRect,
  aspectRatio,
  minCropSize = { width: 50, height: 50 },
  showGrid = true,
  gridColor = '#FFFFFF',
  overlayColor = 'rgba(0, 0, 0, 0.5)',
  onCropRectChange,
  onGestureEnd,
  style,
  ...rest
}) => {
  // Convert ImageSource to string URI
  const sourceUri = typeof source === 'string' ? source : source.uri;

  // Handle crop rect change events
  const handleCropRectChange = useCallback(
    (event: NativeSyntheticEvent<{ cropRect: CropRect }>) => {
      if (onCropRectChange) {
        onCropRectChange(event.nativeEvent.cropRect);
      }
    },
    [onCropRectChange]
  );

  // Handle gesture end events
  const handleGestureEnd = useCallback(
    (event: NativeSyntheticEvent<{ cropRect: CropRect }>) => {
      if (onGestureEnd) {
        onGestureEnd(event.nativeEvent.cropRect);
      }
    },
    [onGestureEnd]
  );

  return (
    <NativeCropperView
      sourceUri={sourceUri}
      initialCropRect={initialCropRect}
      aspectRatio={aspectRatio}
      minCropSize={minCropSize}
      showGrid={showGrid}
      gridColor={gridColor}
      overlayColor={overlayColor}
      onCropRectChange={handleCropRectChange}
      onGestureEnd={handleGestureEnd}
      style={[styles.container, style]}
      {...rest}
    />
  );
};

/**
 * Get the current crop rectangle from the CropperView
 * Note: This function dispatches a command but does not return the result synchronously.
 * Use the onCropRectChange callback to get the current crop rect in real-time.
 * @param viewRef Reference to CropperView component
 */
export const getCropRect = (viewRef: React.RefObject<any>): void => {
  if (!viewRef.current) {
    return;
  }

  try {
    const viewManagerConfig = UIManager.getViewManagerConfig(COMPONENT_NAME);
    if (!viewManagerConfig || !viewManagerConfig.Commands) {
      return;
    }

    const commandId = viewManagerConfig.Commands.getCropRect;

    if (Platform.OS === 'ios') {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        commandId,
        []
      );
    } else {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        'getCropRect',
        []
      );
    }
  } catch (error) {
    console.error('Failed to get crop rect:', error);
  }
};

/**
 * Reset the crop rectangle to full image
 * @param viewRef Reference to CropperView component
 */
export const resetCropRect = (viewRef: React.RefObject<any>): void => {
  if (!viewRef.current) {
    return;
  }

  try {
    const viewManagerConfig = UIManager.getViewManagerConfig(COMPONENT_NAME);
    if (!viewManagerConfig || !viewManagerConfig.Commands) {
      return;
    }

    const commandId = viewManagerConfig.Commands.resetCropRect;

    if (Platform.OS === 'ios') {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        commandId,
        []
      );
    } else {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        'resetCropRect',
        []
      );
    }
  } catch (error) {
    console.error('Failed to reset crop rect:', error);
  }
};

/**
 * Set a new crop rectangle
 * @param viewRef Reference to CropperView component
 * @param cropRect New crop rectangle
 */
export const setCropRect = (
  viewRef: React.RefObject<any>,
  cropRect: CropRect
): void => {
  if (!viewRef.current) {
    return;
  }

  try {
    const viewManagerConfig = UIManager.getViewManagerConfig(COMPONENT_NAME);
    if (!viewManagerConfig || !viewManagerConfig.Commands) {
      return;
    }

    const commandId = viewManagerConfig.Commands.setCropRect;

    if (Platform.OS === 'ios') {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        commandId,
        [cropRect]
      );
    } else {
      UIManager.dispatchViewManagerCommand(
        viewRef.current,
        'setCropRect',
        [cropRect]
      );
    }
  } catch (error) {
    console.error('Failed to set crop rect:', error);
  }
};

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
  },
});

export default CropperView;

