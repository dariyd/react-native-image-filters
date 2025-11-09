#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>

@interface RCT_EXTERN_MODULE(CropperViewManager, RCTViewManager)

// Props
RCT_EXPORT_VIEW_PROPERTY(sourceUri, NSString)
RCT_EXPORT_VIEW_PROPERTY(initialCropRect, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(aspectRatio, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(minCropSize, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(showGrid, BOOL)
RCT_EXPORT_VIEW_PROPERTY(gridColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(overlayColor, NSString)

// Events
RCT_EXPORT_VIEW_PROPERTY(onCropRectChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onGestureEnd, RCTDirectEventBlock)

// Commands
RCT_EXTERN_METHOD(getCropRect:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(resetCropRect:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(setCropRect:(nonnull NSNumber *)node cropRect:(nonnull NSDictionary *)cropRect)

@end

