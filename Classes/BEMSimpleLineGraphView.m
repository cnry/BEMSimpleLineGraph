//
//  BEMSimpleLineGraphView.m
//  SimpleLineGraph
//
//  Created by Bobo on 12/27/13. Updated by Sam Spencer on 1/11/14.
//  Copyright (c) 2013 Boris Emorine. All rights reserved.
//  Copyright (c) 2014 Sam Spencer.
//

#import "BEMSimpleLineGraphView.h"

const CGFloat BEMNullGraphValue = CGFLOAT_MAX;


#if !__has_feature(objc_arc)
// Add the -fobjc-arc flag to enable ARC for only these files, as described in the ARC documentation: http://clang.llvm.org/docs/AutomaticReferenceCounting.html
#error BEMSimpleLineGraph is built with Objective-C ARC. You must enable ARC for these files.
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define DEFAULT_FONT_NAME @"HelveticaNeue-Light"


typedef NS_ENUM(NSInteger, BEMInternalTags)
{
    DotFirstTag100 = 100,
    DotLastTag10000 = 10000,
    LabelYAxisTag20000 = 20000,
    BackgroundYAxisTag21000 = 21000,
    BackgroundXAxisTag22000 = 22000,
    PermanentPopUpViewTag31000 = 31000,
    ReferenceLabelYAxisTag40000 = 40000,
};

@interface BEMSimpleLineGraphView () {
    /// The number of Points in the Graph
    NSInteger numberOfPoints;
    
    /// The closest point to the touch point
    BEMCircle *closestDot;
    CGFloat currentlyCloser;
    
    /// All of the X-Axis Values
    NSMutableArray *xAxisValues;
    
    /// All of the X-Axis Label Points
    NSMutableArray *xAxisLabelPoints;
    
    /// All of the X-Axis Label Points
    CGFloat xAxisHorizontalFringeNegationValue;
    
    /// All of the X-Axis Reference Points
    NSMutableArray *xAxisReferencePoints;
    
    /// All of the Y-Axis Label Points
    NSMutableArray *yAxisLabelPoints;
    
    /// All of the Y-Axis Values
    NSMutableArray *yAxisValues;
    
    /// All of the Y-Axis Reference Points
    NSMutableArray *yAxisReferencePoints;
    
    /// All of the Data Values
    NSMutableArray *dataValues;
    
    /// All of the Data Points
    NSMutableArray *dataPoints;
    
    /// All of the X-Axis Labels
    NSMutableArray *xAxisLabels;
    
    /// All of the Y-Axis Labels
    NSMutableArray *yAxisLabels;
    
    /// All of the Y-Axis Reference Labels
    NSMutableArray *yAxisReferenceLabels;
    
    /// All of the Circle Views
    NSMutableArray *circleViews;
}

/// The vertical line which appears when the user drags across the graph
@property (strong, nonatomic) UIView *touchInputLine;

/// View for picking up pan gesture
@property (strong, nonatomic, readwrite) UIView *panView;

/// Label to display when there is no data
@property (strong, nonatomic) UILabel *noDataLabel;

/// The gesture recognizer picking up the pan in the graph view
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

/// This gesture recognizer picks up the initial touch on the graph view
@property (nonatomic) UILongPressGestureRecognizer *longPressGesture;

/// The label displayed when enablePopUpReport is set to YES
@property (strong, nonatomic) UILabel *popUpLabel;

/// The view used for the background of the popup label
@property (strong, nonatomic) UIView *popUpView;

/// The X position (center) of the view for the popup label
@property (nonatomic) CGFloat xCenterLabel;

/// The Y position (center) of the view for the popup label
@property (nonatomic) CGFloat yCenterLabel;

/// The biggest value out of all of the data points
@property (nonatomic) CGFloat maxValue;

/// The smallest value out of all of the data points
@property (nonatomic) CGFloat minValue;

/// The biggest value out of all the X values.
@property (nonatomic) CGFloat maxXValue;

/// The smallest value out of all the X values.
@property (nonatomic) CGFloat minXValue;

/// The biggest calculated value out of all the X values.
@property (nonatomic) CGFloat maxCalcXValue;

/// The smallest calculated value out of all the X values.
@property (nonatomic) CGFloat minCalcXValue;

/// Find which point is currently the closest to the vertical line
- (BEMCircle *)closestDotFromTouchInputLine:(UIView *)touchInputLine;

/// Determines the biggest Y-axis value from all the points
- (CGFloat)maxValue;

/// Determines the smallest Y-axis value from all the points
- (CGFloat)minValue;

// Tracks whether the popUpView is custom or default
@property (nonatomic) BOOL usingCustomPopupView;

// Stores the current view size to detect whether a redraw is needed in layoutSubviews
@property (nonatomic) CGSize currentViewSize;

// Stores the background X Axis view
@property (nonatomic) UIView *backgroundXAxis;

// Stores the line that is drawn
@property (nonatomic) BEMLine *line;

@end

@implementation BEMSimpleLineGraphView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit {
    // Do any initialization that's common to both -initWithFrame: and -initWithCoder: in this method
    
    // Set the X Axis label font
    _labelFont = [UIFont fontWithName:DEFAULT_FONT_NAME size:13];
    
    // Set Animation Values
    _animationGraphEntranceTime = 1.5;
    
    // Set Color Values
    _colorXaxisLabel = [UIColor blackColor];
    _colorYaxisLabel = [UIColor blackColor];
    _colorTop = [UIColor colorWithRed:0 green:122.0/255.0 blue:255/255 alpha:1];
    _colorLine = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1];
    _colorBottom = [UIColor colorWithRed:0 green:122.0/255.0 blue:255/255 alpha:1];
    _colorPoint = [UIColor colorWithWhite:1.0 alpha:0.7];
    _colorTouchInputLine = [UIColor grayColor];
    _colorBackgroundPopUplabel = [UIColor whiteColor];
    _alphaTouchInputLine = 0.2;
    _widthTouchInputLine = 1.0;
    _colorBackgroundXaxis = nil;
    _alphaBackgroundXaxis = 1.0;
    _colorBackgroundYaxis = nil;
    _alphaBackgroundYaxis = 1.0;
    _displayDotsWhileAnimating = YES;
    
    // Set Alpha Values
    _alphaTop = 1.0;
    _alphaBottom = 1.0;
    _alphaLine = 1.0;
    
    // Set Size Values
    _widthLine = 1.0;
    _widthReferenceLines = 1.0;
    _sizePoint = 10.0;
    
    // Set Default Feature Values
    _enableTouchReport = NO;
    _touchReportFingersRequired = 1;
    _enablePopUpReport = NO;
    _enableBezierCurve = NO;
    _enableXAxisLabel = YES;
    _enableYAxisLabel = NO;
    _autoScaleYAxis = YES;
    _alwaysDisplayDots = NO;
    _alwaysDisplayPopUpLabels = NO;
    _enableLeftReferenceAxisFrameLine = YES;
    _enableBottomReferenceAxisFrameLine = YES;
    _formatStringForValues = @"%.0f";
    _interpolateNullValues = YES;
    _displayDotsOnly = NO;
    
    // Initialize the various arrays
    xAxisValues = [NSMutableArray array];
    xAxisHorizontalFringeNegationValue = 0.0;
    xAxisLabelPoints = [NSMutableArray array];
    xAxisReferencePoints = [NSMutableArray array];
    yAxisLabelPoints = [NSMutableArray array];
    yAxisReferencePoints = [NSMutableArray array];
    dataValues = [NSMutableArray array];
    dataPoints = [NSMutableArray array];
    xAxisLabels = [NSMutableArray array];
    yAxisLabels = [NSMutableArray array];
    yAxisReferenceLabels = [NSMutableArray array];
    circleViews = [NSMutableArray array];

    // Initialize BEM Objects
    _averageLine = [[BEMAverageLine alloc] init];
}

- (void)prepareForInterfaceBuilder {
    // Set points and remove all dots that were previously on the graph
    numberOfPoints = 10;
    if ( [self.noDataLabel superview] == self ) {
        [self.noDataLabel removeFromSuperview];
    }
    
    [self drawEntireGraph];
}

- (void)drawGraph {
    // Let the delegate know that the graph began layout updates
    if ([self.delegate respondsToSelector:@selector(lineGraphDidBeginLoading:)])
        [self.delegate lineGraphDidBeginLoading:self];
    
    // Get the number of points in the graph
    [self layoutNumberOfPoints];
    
    // Draw the graph
    [self drawEntireGraph];
    
    // Setup the touch report
    [self layoutTouchReport];
    
    // Let the delegate know that the graph finished updates
    if ([self.delegate respondsToSelector:@selector(lineGraphDidFinishLoading:)])
        [self.delegate lineGraphDidFinishLoading:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(self.currentViewSize, self.bounds.size))  return;
    self.currentViewSize = self.bounds.size;

    [self drawGraph];
}

- (void)layoutNumberOfPoints {
    // Get the total number of data points from the delegate
    if ([self.dataSource respondsToSelector:@selector(numberOfPointsInLineGraph:)]) {
        numberOfPoints = [self.dataSource numberOfPointsInLineGraph:self];
        
    } else if ([self.delegate respondsToSelector:@selector(numberOfPointsInGraph)]) {
        [self printDeprecationWarningForOldMethod:@"numberOfPointsInGraph" andReplacementMethod:@"numberOfPointsInLineGraph:"];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        numberOfPoints = [self.delegate numberOfPointsInGraph];
#pragma clang diagnostic pop
        
    } else if ([self.delegate respondsToSelector:@selector(numberOfPointsInLineGraph:)]) {
        [self printDeprecationAndUnavailableWarningForOldMethod:@"numberOfPointsInLineGraph:"];
        numberOfPoints = 0;
        
    } else numberOfPoints = 0;
    
    // There are no points to load
    if (numberOfPoints == 0) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(noDataLabelEnableForLineGraph:)] &&
            ![self.delegate noDataLabelEnableForLineGraph:self]) return;

        NSLog(@"[BEMSimpleLineGraph] Data source contains no data. A no data label will be displayed and drawing will stop. Add data to the data source and then reload the graph.");
        
#if !TARGET_INTERFACE_BUILDER
        self.noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.viewForBaselineLayout.frame.size.width, self.viewForBaselineLayout.frame.size.height)];
#else
        self.noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.viewForBaselineLayout.frame.size.width, self.viewForBaselineLayout.frame.size.height-(self.viewForBaselineLayout.frame.size.height/4))];
#endif
        
        self.noDataLabel.backgroundColor = [UIColor clearColor];
        self.noDataLabel.textAlignment = NSTextAlignmentCenter;

#if !TARGET_INTERFACE_BUILDER
        NSString *noDataText;
        if ([self.delegate respondsToSelector:@selector(noDataLabelTextForLineGraph:)]) {
            noDataText = [self.delegate noDataLabelTextForLineGraph:self];
        }
        self.noDataLabel.text = noDataText ?: NSLocalizedString(@"No Data", nil);
#else
        self.noDataLabel.text = @"Data is not loaded in Interface Builder";
#endif
        self.noDataLabel.font = self.noDataLabelFont ?: [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
        self.noDataLabel.textColor = self.noDataLabelColor ?: self.colorLine;

        [self.viewForBaselineLayout addSubview:self.noDataLabel];
        
        // Let the delegate know that the graph finished layout updates
        if ([self.delegate respondsToSelector:@selector(lineGraphDidFinishLoading:)])
            [self.delegate lineGraphDidFinishLoading:self];
        return;
        
    } else {
        // Remove all dots that were previously on the graph
        if ( [self.noDataLabel superview] == self ) {
            [self.noDataLabel removeFromSuperview];
        }
    }
}

- (void)layoutTouchReport {
    // If the touch report is enabled, set it up
    if (self.enableTouchReport == YES || self.enablePopUpReport == YES) {
        // Initialize the vertical gray line that appears where the user touches the graph.
        self.touchInputLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.widthTouchInputLine, self.frame.size.height)];
        self.touchInputLine.backgroundColor = self.colorTouchInputLine;
        self.touchInputLine.alpha = 0;
        [self addSubview:self.touchInputLine];
        
        self.panView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, self.viewForBaselineLayout.frame.size.width, self.viewForBaselineLayout.frame.size.height)];
        self.panView.backgroundColor = [UIColor clearColor];
        [self.viewForBaselineLayout addSubview:self.panView];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureAction:)];
        self.panGesture.delegate = self;
        [self.panGesture setMaximumNumberOfTouches:1];
        [self.panView addGestureRecognizer:self.panGesture];
        
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureAction:)];
        self.longPressGesture.minimumPressDuration = 0.1f;
        [self.panView addGestureRecognizer:self.longPressGesture];
        
        if (self.enablePopUpReport == YES && self.alwaysDisplayPopUpLabels == NO) {
            if ([self.delegate respondsToSelector:@selector(popUpViewForLineGraph:)]) {
                self.popUpView = [self.delegate popUpViewForLineGraph:self];
                self.usingCustomPopupView = YES;
                self.popUpView.alpha = 0;
                [self addSubview:self.popUpView];
            } else {
                NSString *maxValueString = [NSString stringWithFormat:self.formatStringForValues, [self calculateMaximumPointValue].doubleValue];
                NSString *minValueString = [NSString stringWithFormat:self.formatStringForValues, [self calculateMinimumPointValue].doubleValue];
                
                NSString *longestString = @"";
                if (maxValueString.length > minValueString.length) {
                    longestString = maxValueString;
                } else {
                    longestString = minValueString;
                }
                
                NSString *prefix = @"";
                NSString *suffix = @"";
                if ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)]) {
                    suffix = [self.delegate popUpSuffixForlineGraph:self];
                }
                if ([self.delegate respondsToSelector:@selector(popUpPrefixForlineGraph:)]) {
                    prefix = [self.delegate popUpPrefixForlineGraph:self];
                }
                
                NSString *fullString = [NSString stringWithFormat:@"%@%@%@", prefix, longestString, suffix];
                
                NSString *mString = [fullString stringByReplacingOccurrencesOfString:@"[0-9-]" withString:@"N" options:NSRegularExpressionSearch range:NSMakeRange(0, [longestString length])];
                
                self.popUpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
                self.popUpLabel.text = mString;
                self.popUpLabel.textAlignment = 1;
                self.popUpLabel.numberOfLines = 1;
                self.popUpLabel.font = self.labelFont;
                self.popUpLabel.backgroundColor = [UIColor clearColor];
                [self.popUpLabel sizeToFit];
                self.popUpLabel.alpha = 0;
                
                self.popUpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.popUpLabel.frame.size.width + 10, self.popUpLabel.frame.size.height + 2)];
                self.popUpView.backgroundColor = self.colorBackgroundPopUplabel;
                self.popUpView.alpha = 0;
                self.popUpView.layer.cornerRadius = 3;
                [self addSubview:self.popUpView];
                [self addSubview:self.popUpLabel];
            }
        }
    }
}

#pragma mark - Property Overrides

- (void)setColorPoint:(UIColor *)colorPoint {
    _colorPoint = colorPoint;
    for (BEMCircle *circle in circleViews) {
        [circle setBackgroundColor:colorPoint];
    }
}

- (void)setColorLine:(UIColor *)colorLine {
    _colorLine = colorLine;
    [self.line setColor:colorLine];
}

- (void)setColorTouchInputLine:(UIColor *)colorTouchInputLine {
    _colorTouchInputLine = colorTouchInputLine;
    [self.touchInputLine setBackgroundColor:colorTouchInputLine];
}

- (void)setColorLineShadow:(UIColor *)colorLineShadow {
    _colorLineShadow = colorLineShadow;
    [self.line setShadowColor:colorLineShadow];
}

- (void)setColorTop:(UIColor *)colorTop {
    _colorTop = colorTop;
    [self.line setTopColor:colorTop];
}

- (void)setColorBottom:(UIColor *)colorBottom {
    _colorBottom = colorBottom;
    [self.line setBottomColor:colorBottom];
}

- (void)setColorReferenceLines:(UIColor *)colorReferenceLines {
    _colorReferenceLines = colorReferenceLines;
    [self.line setReferenceLineColor:colorReferenceLines];
}

- (void)setColorXaxisLabel:(UIColor *)colorXaxisLabel {
    _colorXaxisLabel = colorXaxisLabel;
    for (UILabel *xAxisLabel in xAxisLabels) {
        [xAxisLabel setTextColor:colorXaxisLabel];
    }
}

- (void)setColorYaxisLabel:(UIColor *)colorYaxisLabel {
    _colorYaxisLabel = colorYaxisLabel;
    for (UILabel *yAxisLabel in yAxisLabels) {
        [yAxisLabel setTextColor:colorYaxisLabel];
    }
    if (self.colorReferenceYaxisLabel == nil) {
        for (UILabel *yAxisReferenceLabel in yAxisReferenceLabels) {
            [yAxisReferenceLabel setTextColor:colorYaxisLabel];
        }
    }
}

- (void)setColorReferenceYaxisLabel:(UIColor *)colorReferenceYaxisLabel {
    _colorReferenceYaxisLabel = colorReferenceYaxisLabel;
    for (UILabel *yAxisReferenceLabel in yAxisReferenceLabels) {
        [yAxisReferenceLabel setTextColor:colorReferenceYaxisLabel ?: self.colorYaxisLabel];
    }
}

#pragma mark - Drawing

- (void)didFinishDrawingIncludingYAxis:(BOOL)yAxisFinishedDrawing {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.animationGraphEntranceTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.enableYAxisLabel == NO) {
            // Let the delegate know that the graph finished rendering
            if ([self.delegate respondsToSelector:@selector(lineGraphDidFinishDrawing:)])
                [self.delegate lineGraphDidFinishDrawing:self];
            return;
        } else {
            if (yAxisFinishedDrawing == YES) {
                // Let the delegate know that the graph finished rendering
                if ([self.delegate respondsToSelector:@selector(lineGraphDidFinishDrawing:)])
                    [self.delegate lineGraphDidFinishDrawing:self];
                return;
            }
        }
    });
}

- (void)drawEntireGraph {
    // The following method calls are in this specific order for a reason
    // Changing the order of the method calls below can result in drawing glitches and even crashes
    
    self.maxValue = [self getMaximumValue];
    self.minValue = [self getMinimumValue];
    self.maxXValue = [self getMaxXValue];
    self.minXValue = [self getMinXValue];
    self.maxCalcXValue = [self getMaxCalcXValue];
    self.minCalcXValue = [self getMinCalcXValue];
    
    // Draw the X-Axis
    [self drawXAxis];

    // Draw the graph
    [self drawDots];

    // Draw the Y-Axis
    if (self.enableYAxisLabel) [self drawYAxis];
}

- (void)drawDots {
    CGFloat positionOnXAxis; // The position on the X-axis of the point currently being created.
    CGFloat positionOnYAxis; // The position on the Y-axis of the point currently being created.
    
    // Remove all dots that were previously on the graph
    for (BEMCircle *circleView in circleViews) {
        [circleView removeFromSuperview];
    }
    [circleViews removeAllObjects];
    
    // Remove all data points before adding them to the array
    [dataValues removeAllObjects];
    [dataPoints removeAllObjects];
    
    // Loop through each point and add it to the graph
    @autoreleasepool {
        for (int i = 0; i < numberOfPoints; i++) {
            CGFloat dotValue = 0;
            
#if !TARGET_INTERFACE_BUILDER
            if ([self.dataSource respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                dotValue = [self.dataSource lineGraph:self valueForPointAtIndex:i];
                
            } else if ([self.delegate respondsToSelector:@selector(valueForIndex:)]) {
                [self printDeprecationWarningForOldMethod:@"valueForIndex:" andReplacementMethod:@"lineGraph:valueForPointAtIndex:"];
                
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                dotValue = [self.delegate valueForIndex:i];
#pragma clang diagnostic pop
                
            } else if ([self.delegate respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                [self printDeprecationAndUnavailableWarningForOldMethod:@"lineGraph:valueForPointAtIndex:"];
                NSException *exception = [NSException exceptionWithName:@"Implementing Unavailable Delegate Method" reason:@"lineGraph:valueForPointAtIndex: is no longer available on the delegate. It must be implemented on the data source." userInfo:nil];
                [exception raise];
                
                
            } else [NSException raise:@"lineGraph:valueForPointAtIndex: protocol method is not implemented in the data source. Throwing exception here before the system throws a CALayerInvalidGeometry Exception." format:@"Value for point %f at index %lu is invalid. CALayer position may contain NaN: [0 nan]", dotValue, (unsigned long)i];
#else
            dotValue = (int)(arc4random() % 10000);
#endif
            [dataValues addObject:@(dotValue)];
            
            CGFloat xValue;
            if ([self.dataSource respondsToSelector:@selector(lineGraph:xValueForPointAtIndex:)]) {
                xValue = [self.dataSource lineGraph:self xValueForPointAtIndex:i];
            } else xValue = i;
            
            positionOnXAxis = self.frame.size.width * (xValue - self.minXValue) / (self.maxXValue - self.minXValue);
            positionOnYAxis = [self yPositionForDotValue:dotValue];
            
            
            // If we're dealing with an null value, don't draw the dot
            
            if (dotValue != BEMNullGraphValue) {
                CGPoint circlePoint = CGPointMake(positionOnXAxis, positionOnYAxis);
                [dataPoints addObject:[NSValue valueWithCGPoint:circlePoint]];
                
                BEMCircle *circleDot = [[BEMCircle alloc] initWithFrame:CGRectMake(0, 0, self.sizePoint, self.sizePoint)];
                [circleDot setBackgroundColor:self.colorPoint];
                circleDot.center = circlePoint;
                circleDot.tag = i+ DotFirstTag100;
                circleDot.alpha = 0;
                circleDot.absoluteValue = dotValue;
                
                [self addSubview:circleDot];
                [circleViews addObject:circleDot];
                if (self.alwaysDisplayPopUpLabels == YES) {
                    if ([self.delegate respondsToSelector:@selector(lineGraph:alwaysDisplayPopUpAtIndex:)]) {
                        if ([self.delegate lineGraph:self alwaysDisplayPopUpAtIndex:i] == YES) {
                            [self displayPermanentLabelForPoint:circleDot];
                        }
                    } else [self displayPermanentLabelForPoint:circleDot];
                }
                
                // Dot entrance animation
                if (self.animationGraphEntranceTime == 0) {
                    if (self.displayDotsOnly == YES) circleDot.alpha = 1.0;
                    else {
                        if (self.alwaysDisplayDots == NO) circleDot.alpha = 0;
                        else circleDot.alpha = 1.0;
                    }
                } else {
                    if (self.displayDotsWhileAnimating) {
                        [UIView animateWithDuration:(float)self.animationGraphEntranceTime/numberOfPoints delay:(float)i*((float)self.animationGraphEntranceTime/numberOfPoints) options:UIViewAnimationOptionCurveLinear animations:^{
                            circleDot.alpha = 1.0;
                        } completion:^(BOOL finished) {
                            if (self.alwaysDisplayDots == NO && self.displayDotsOnly == NO) {
                                [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    circleDot.alpha = 0;
                                } completion:nil];
                            }
                        }];
                    }
                }
            }
        }
    }
    
    // CREATION OF THE LINE AND BOTTOM AND TOP FILL
    [self drawLine];
}

- (void)drawLine {
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[BEMLine class]])
            [subview removeFromSuperview];
    }
    
    BEMLine *line = [[BEMLine alloc] initWithFrame:[self drawableGraphArea]];
    
    line.opaque = NO;
    line.alpha = 1;
    line.backgroundColor = [UIColor clearColor];
    line.topColor = self.colorTop;
    line.bottomColor = self.colorBottom;
    line.topAlpha = self.alphaTop;
    line.bottomAlpha = self.alphaBottom;
    line.topGradient = self.gradientTop;
    line.bottomGradient = self.gradientBottom;
    line.lineWidth = self.widthLine;
    line.referenceLineWidth = self.widthReferenceLines?self.widthReferenceLines:(self.widthLine/2);
    line.lineAlpha = self.alphaLine;
    line.bezierCurveIsEnabled = self.enableBezierCurve;
    line.arrayOfPoints = dataPoints;
    line.lineDashPatternForReferenceYAxisLines = self.lineDashPatternForReferenceYAxisLines;
    line.lineDashPatternForReferenceXAxisLines = self.lineDashPatternForReferenceXAxisLines;
    line.interpolateNullValues = self.interpolateNullValues;
    
    line.enableRefrenceFrame = self.enableReferenceAxisFrame;
    line.enableRightReferenceFrameLine = self.enableRightReferenceAxisFrameLine;
    line.enableTopReferenceFrameLine = self.enableTopReferenceAxisFrameLine;
    line.enableLeftReferenceFrameLine = self.enableLeftReferenceAxisFrameLine;
    line.enableBottomReferenceFrameLine = self.enableBottomReferenceAxisFrameLine;
    
    if (self.enableReferenceXAxisLines || self.enableReferenceYAxisLines) {
        line.enableRefrenceLines = YES;
        line.referenceLineColor = self.colorReferenceLines;
        line.verticalReferenceHorizontalFringeNegation = xAxisHorizontalFringeNegationValue;
        line.arrayOfVerticalRefrenceLinePoints = self.enableReferenceXAxisLines ? xAxisReferencePoints : nil;
        line.arrayOfHorizontalRefrenceLinePoints = self.enableReferenceYAxisLines ? yAxisReferencePoints : nil;
    }
    
    line.color = self.colorLine;
    line.lineGradient = self.gradientLine;
    line.lineGradientDirection = self.gradientLineDirection;
    line.animationTime = self.animationGraphEntranceTime;
    line.animationType = self.animationGraphStyle;
    
    if (self.averageLine.enableAverageLine == YES) {
        if (self.averageLine.yValue == 0.0) self.averageLine.yValue = [self calculatePointValueAverage].floatValue;
        line.averageLineYCoordinate = [self yPositionForDotValue:self.averageLine.yValue];
        line.averageLine = self.averageLine;
    } else line.averageLine = self.averageLine;
    
    line.disableMainLine = self.displayDotsOnly;
    
    [self addSubview:line];
    [self sendSubviewToBack:line];
    [self sendSubviewToBack:self.backgroundXAxis];
    
    self.line = line;
    
    [self didFinishDrawingIncludingYAxis:NO];
}

- (void)drawXAxis {
    if (!self.enableXAxisLabel) return;
    if (![self.dataSource respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)] && ![self.dataSource respondsToSelector:@selector(lineGraph:labelOnXAxisForValue:)]) return;
    
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[UILabel class]] && subview.tag == DotLastTag10000) [subview removeFromSuperview];
        else if ([subview isKindOfClass:[UIView class]] && subview.tag == BackgroundXAxisTag22000) [subview removeFromSuperview];
    }
    
    // Remove all X-Axis Labels before adding them to the array
    [xAxisValues removeAllObjects];
    [xAxisLabels removeAllObjects];
    [xAxisLabelPoints removeAllObjects];
    xAxisHorizontalFringeNegationValue = 0.0;
    
    // Draw X-Axis Background Area
    self.backgroundXAxis = [[UIView alloc] initWithFrame:[self drawableXAxisArea]];
    self.backgroundXAxis.tag = BackgroundXAxisTag22000;
    if (self.colorBackgroundXaxis == nil) self.backgroundXAxis.backgroundColor = self.colorBottom;
    else self.backgroundXAxis.backgroundColor = self.colorBackgroundXaxis;
    self.backgroundXAxis.alpha = self.alphaBackgroundXaxis;
    [self addSubview:self.backgroundXAxis];
    
    if ([self.delegate respondsToSelector:@selector(baseValueForXAxisOnLineGraph:)] && [self.delegate respondsToSelector:@selector(incrementValueForXAxisOnLineGraph:)]) {
        CGFloat baseValue = [self.delegate baseValueForXAxisOnLineGraph:self];
        CGFloat increment = [self.delegate incrementValueForXAxisOnLineGraph:self];
        
        CGFloat startingValue = baseValue;;
        while (startingValue < self.maxXValue) {
            NSString *xAxisLabelText = [self xAxisTextForValue:startingValue];
            
            UILabel *labelXAxis = [self xAxisLabelWithText:xAxisLabelText atValue:startingValue];
            [xAxisLabels addObject:labelXAxis];
            
            NSNumber *xAxisLabelCoordinate = [NSNumber numberWithFloat:labelXAxis.center.x];
            [xAxisLabelPoints addObject:xAxisLabelCoordinate];
            
            [self addSubview:labelXAxis];
            [xAxisValues addObject:xAxisLabelText];
            
            startingValue += increment;
        }
    } else if ([self.delegate respondsToSelector:@selector(incrementPositionsForXAxisOnLineGraph:)]) {
        NSArray *axisValues = [self.delegate incrementPositionsForXAxisOnLineGraph:self];
        for (NSNumber *increment in axisValues) {
            NSInteger index = increment.integerValue;
            NSString *xAxisLabelText = [self xAxisTextForValue:index];
            
            UILabel *labelXAxis = [self xAxisLabelWithText:xAxisLabelText atValue:index];
            [xAxisLabels addObject:labelXAxis];
            
            NSNumber *xAxisLabelCoordinate = [NSNumber numberWithFloat:labelXAxis.center.x];
            [xAxisLabelPoints addObject:xAxisLabelCoordinate];
            
            [self addSubview:labelXAxis];
            [xAxisValues addObject:xAxisLabelText];
        }
    } else if ([self.delegate respondsToSelector:@selector(baseIndexForXAxisOnLineGraph:)] && [self.delegate respondsToSelector:@selector(incrementIndexForXAxisOnLineGraph:)]) {
        NSInteger baseIndex = [self.delegate baseIndexForXAxisOnLineGraph:self];
        NSInteger increment = [self.delegate incrementIndexForXAxisOnLineGraph:self];
        
        NSInteger startingIndex = baseIndex;
        while (startingIndex < numberOfPoints) {
            
            NSString *xAxisLabelText = [self xAxisTextForValue:startingIndex];
            
            UILabel *labelXAxis = [self xAxisLabelWithText:xAxisLabelText atValue:startingIndex];
            [xAxisLabels addObject:labelXAxis];
            
            NSNumber *xAxisLabelCoordinate = [NSNumber numberWithFloat:labelXAxis.center.x];
            [xAxisLabelPoints addObject:xAxisLabelCoordinate];
            
            [self addSubview:labelXAxis];
            [xAxisValues addObject:xAxisLabelText];
            
            startingIndex += increment;
        }
    } else {
        NSInteger numberOfGaps = 1;
        
        if ([self.delegate respondsToSelector:@selector(numberOfGapsBetweenLabelsOnLineGraph:)]) {
            numberOfGaps = [self.delegate numberOfGapsBetweenLabelsOnLineGraph:self] + 1;
            
        } else if ([self.delegate respondsToSelector:@selector(numberOfGapsBetweenLabels)]) {
            [self printDeprecationWarningForOldMethod:@"numberOfGapsBetweenLabels" andReplacementMethod:@"numberOfGapsBetweenLabelsOnLineGraph:"];
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            numberOfGaps = [self.delegate numberOfGapsBetweenLabels] + 1;
#pragma clang diagnostic pop
            
        } else {
            numberOfGaps = 1;
        }
        
        if (numberOfGaps >= (numberOfPoints - 1)) {
            NSString *firstXLabel = [self xAxisTextForValue:0];
            NSString *lastXLabel = [self xAxisTextForValue:numberOfPoints - 1];
            
            CGFloat viewWidth = self.frame.size.width;
            
            CGFloat xAxisXPositionFirstOffset = 3;
            CGFloat xAxisXPositionLastOffset = xAxisXPositionFirstOffset + 1 + viewWidth/2;
            
            UILabel *firstLabel = [self xAxisLabelWithText:firstXLabel atValue:0];
            firstLabel.frame = CGRectMake(xAxisXPositionFirstOffset, self.frame.size.height-20, viewWidth/2, 20);
            
            firstLabel.textAlignment = NSTextAlignmentLeft;
            [self addSubview:firstLabel];
            [xAxisValues addObject:firstXLabel];
            [xAxisLabels addObject:firstLabel];
            
            UILabel *lastLabel = [self xAxisLabelWithText:lastXLabel atValue:numberOfPoints - 1];
            lastLabel.frame = CGRectMake(xAxisXPositionLastOffset, self.frame.size.height-20, viewWidth/2 - 4, 20);
            lastLabel.textAlignment = NSTextAlignmentRight;
            [self addSubview:lastLabel];
            [xAxisValues addObject:lastXLabel];
            [xAxisLabels addObject:lastLabel];
            
            NSNumber *xFirstAxisLabelCoordinate = @(firstLabel.center.x);
            NSNumber *xLastAxisLabelCoordinate = @(lastLabel.center.x);
            [xAxisLabelPoints addObject:xFirstAxisLabelCoordinate];
            [xAxisLabelPoints addObject:xLastAxisLabelCoordinate];
        } else {
            @autoreleasepool {
                NSInteger offset = [self offsetForXAxisWithNumberOfGaps:numberOfGaps]; // The offset (if possible and necessary) used to shift the Labels on the X-Axis for them to be centered.
                
                for (int i = 1; i <= (numberOfPoints/numberOfGaps); i++) {
                    NSInteger index = i *numberOfGaps - 1 - offset;
                    NSString *xAxisLabelText = [self xAxisTextForValue:index];
                    
                    UILabel *labelXAxis = [self xAxisLabelWithText:xAxisLabelText atValue:index];
                    [xAxisLabels addObject:labelXAxis];
                    
                    NSNumber *xAxisLabelCoordinate = [NSNumber numberWithFloat:labelXAxis.center.x];
                    [xAxisLabelPoints addObject:xAxisLabelCoordinate];
                    
                    [self addSubview:labelXAxis];
                    [xAxisValues addObject:xAxisLabelText];
                }
                
            }
        }
    }
    __block NSUInteger lastMatchIndex;
    
    NSMutableArray *overlapLabels = [NSMutableArray arrayWithCapacity:0];
    [xAxisLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            lastMatchIndex = 0;
        } else { // Skip first one
            UILabel *prevLabel = [xAxisLabels objectAtIndex:lastMatchIndex];
            CGRect r = CGRectIntersection(prevLabel.frame, label.frame);
            if (CGRectIsNull(r)) lastMatchIndex = idx;
            else [overlapLabels addObject:label]; // Overlapped
        }
        
        BOOL fullyContainsLabel = CGRectContainsRect(self.bounds, label.frame);
        if (!fullyContainsLabel) {
            [overlapLabels addObject:label];
        }
    }];
    
    for (UILabel *l in overlapLabels) {
        [l removeFromSuperview];
    }
    
    [xAxisReferencePoints removeAllObjects];
    if ( self.referenceXAxisValues != nil ) {
        for ( NSNumber *xAxisValue in self.referenceXAxisValues ) {
            CGFloat xAxisPosition = self.frame.size.width * (xAxisValue.doubleValue - self.minXValue) / (self.maxXValue - self.minXValue);
            [xAxisReferencePoints addObject:@(xAxisPosition)];
        }
    } else {
        [xAxisReferencePoints addObjectsFromArray:xAxisLabelPoints];
    }
}

- (NSString *)xAxisTextForValue:(CGFloat)value {
    NSString *xAxisLabelText = @"";
    
    if ([self.dataSource respondsToSelector:@selector(lineGraph:labelOnXAxisForValue:)]) {
        xAxisLabelText = [self.dataSource lineGraph:self labelOnXAxisForValue:value];
        
    } else if ([self.dataSource respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)]) {
        xAxisLabelText = [self.dataSource lineGraph:self labelOnXAxisForIndex:(NSUInteger)value];
        
    } else if ([self.delegate respondsToSelector:@selector(labelOnXAxisForIndex:)]) {
        [self printDeprecationWarningForOldMethod:@"labelOnXAxisForIndex:" andReplacementMethod:@"lineGraph:labelOnXAxisForIndex:"];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        xAxisLabelText = [self.delegate labelOnXAxisForIndex:(NSUInteger)value];
#pragma clang diagnostic pop
        
    } else if ([self.delegate respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)]) {
        [self printDeprecationAndUnavailableWarningForOldMethod:@"lineGraph:labelOnXAxisForIndex:"];
        NSException *exception = [NSException exceptionWithName:@"Implementing Unavailable Delegate Method" reason:@"lineGraph:labelOnXAxisForIndex: is no longer available on the delegate. It must be implemented on the data source." userInfo:nil];
        [exception raise];
        
    } else {
        xAxisLabelText = @"";
    }
    
    return xAxisLabelText;
}

- (UILabel *)xAxisLabelWithText:(NSString *)text atValue:(CGFloat)value {
    UILabel *labelXAxis = [[UILabel alloc] init];
    labelXAxis.text = text;
    labelXAxis.font = self.labelFont;
    labelXAxis.textAlignment = 1;
    labelXAxis.textColor = self.colorXaxisLabel;
    labelXAxis.backgroundColor = [UIColor clearColor];
    labelXAxis.tag = DotLastTag10000;
    
    // Add support multi-line, but this might overlap with the graph line if text have too many lines
    labelXAxis.numberOfLines = 0;
    CGRect lRect = [labelXAxis.text boundingRectWithSize:self.viewForBaselineLayout.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:labelXAxis.font} context:nil];
    CGFloat halfWidth = lRect.size.width/2;
    CGPoint center;
    
    // Determine the final x-axis position
    CGFloat positionOnXAxis = self.frame.size.width * (value - self.minXValue) / (self.maxXValue - self.minXValue);
    
    // Determine the horizontal translation to perform on the far left and far right labels
    // This property is negated when calculating the position of reference frames
    CGFloat horizontalTranslation;
    if (positionOnXAxis - halfWidth < 0) {
        horizontalTranslation = halfWidth;
    } else if (positionOnXAxis + halfWidth > self.frame.size.width) {
        horizontalTranslation = -halfWidth;
    } else horizontalTranslation = 0;
    xAxisHorizontalFringeNegationValue = horizontalTranslation;
    positionOnXAxis += horizontalTranslation;
    
    // Set the final center point of the x-axis labels
    if (self.positionYAxisRight) {
        center = CGPointMake(positionOnXAxis, self.frame.size.height - lRect.size.height/2);
    } else {
        center = CGPointMake(positionOnXAxis, self.frame.size.height - lRect.size.height/2);
    }
    
    CGRect rect = labelXAxis.frame;
    rect.size = lRect.size;
    labelXAxis.frame = rect;
    labelXAxis.center = center;
    
    return labelXAxis;
}

- (void)drawYAxis {
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[UILabel class]] && subview.tag == LabelYAxisTag20000 ) {
            [subview removeFromSuperview];
        } else if ([subview isKindOfClass:[UIView class]] && subview.tag == BackgroundYAxisTag21000 ) {
            [subview removeFromSuperview];
        }
    }
    
    CGRect frameForBackgroundYAxis;
    CGRect frameForLabelYAxis;
    NSTextAlignment textAlignmentForLabelYAxis;
    
    if (self.positionYAxisRight) {
        frameForBackgroundYAxis = CGRectMake(self.frame.size.width, 0.0f, 0.0f, self.frame.size.height);
        frameForLabelYAxis = CGRectMake(self.frame.size.width - 5.0f, 0.0f, 0.0f, 15.0f);
        textAlignmentForLabelYAxis = NSTextAlignmentRight;
    } else {
        frameForBackgroundYAxis = CGRectMake(0.0f, 0.0f, 0.0f, self.frame.size.height);
        frameForLabelYAxis = CGRectMake(5.0f, 0.0f, 0.0f, 15.0f);
        textAlignmentForLabelYAxis = NSTextAlignmentRight;
    }
    
    UIView *backgroundYaxis = [[UIView alloc] initWithFrame:frameForBackgroundYAxis];
    backgroundYaxis.tag = BackgroundYAxisTag21000;
    if (self.colorBackgroundYaxis == nil) backgroundYaxis.backgroundColor = self.colorTop;
    else backgroundYaxis.backgroundColor = self.colorBackgroundYaxis;
    backgroundYaxis.alpha = self.alphaBackgroundYaxis;
    [self addSubview:backgroundYaxis];
    
    [yAxisLabels removeAllObjects];
    [yAxisLabelPoints removeAllObjects];
    
    NSString *yAxisSuffix = @"";
    NSString *yAxisPrefix = @"";
    
    if ([self.delegate respondsToSelector:@selector(yAxisPrefixOnLineGraph:)]) yAxisPrefix = [self.delegate yAxisPrefixOnLineGraph:self];
    if ([self.delegate respondsToSelector:@selector(yAxisSuffixOnLineGraph:)]) yAxisSuffix = [self.delegate yAxisSuffixOnLineGraph:self];
    
    if (self.autoScaleYAxis) {
        // Plot according to min-max range
        NSNumber *minimumValue;
        NSNumber *maximumValue;

        minimumValue = [self calculateMinimumPointValue];
        maximumValue = [self calculateMaximumPointValue];
        
        CGFloat numberOfLabels;
        if ([self.delegate respondsToSelector:@selector(numberOfYAxisLabelsOnLineGraph:)]) {
            numberOfLabels = [self.delegate numberOfYAxisLabelsOnLineGraph:self];
        } else numberOfLabels = 3;
        
        NSMutableArray *dotValues = [[NSMutableArray alloc] initWithCapacity:numberOfLabels];
        if ([self.delegate respondsToSelector:@selector(yAxisValuesToShowForLineGraph:)]) {
            dotValues = [NSMutableArray arrayWithArray:[self.delegate yAxisValuesToShowForLineGraph:self]];
        } else if ([self.delegate respondsToSelector:@selector(baseValueForYAxisOnLineGraph:)] && [self.delegate respondsToSelector:@selector(incrementValueForYAxisOnLineGraph:)]) {
            CGFloat baseValue = [self.delegate baseValueForYAxisOnLineGraph:self];
            CGFloat increment = [self.delegate incrementValueForYAxisOnLineGraph:self];
            
            float yAxisPosition = baseValue;
            if (baseValue + increment * 100 < maximumValue.doubleValue) {
                NSLog(@"[BEMSimpleLineGraph] Increment does not properly lay out Y axis, bailing early");
                return;
            }
            
            while(yAxisPosition < maximumValue.floatValue + increment) {
                [dotValues addObject:@(yAxisPosition)];
                yAxisPosition += increment;
            }
        } else if (numberOfLabels <= 0) return;
        else if (numberOfLabels == 1) {
            [dotValues removeAllObjects];
            [dotValues addObject:[NSNumber numberWithInt:(minimumValue.intValue + maximumValue.intValue)/2]];
        } else {
            [dotValues addObject:minimumValue];
            [dotValues addObject:maximumValue];
            for (int i=1; i<numberOfLabels-1; i++) {
                [dotValues addObject:[NSNumber numberWithFloat:(minimumValue.doubleValue + ((maximumValue.doubleValue - minimumValue.doubleValue)/(numberOfLabels-1))*i)]];
            }
        }
        
        for (NSNumber *dotValue in dotValues) {
            CGFloat yValue = dotValue.doubleValue;
            NSString *formattedValue;
            if ( [self.delegate respondsToSelector:@selector(lineGraph:labelOnYAxisForValue:)] ) {
                formattedValue = [self.delegate lineGraph:self labelOnYAxisForValue:yValue];
            } else {
                formattedValue = [NSString stringWithFormat:self.formatStringForValues, dotValue.doubleValue];
            }
            CGFloat yAxisPosition = [self yPositionForDotValue:yValue];
            UILabel *labelYAxis = [[UILabel alloc] initWithFrame:frameForLabelYAxis];
            labelYAxis.text = formattedValue;
            labelYAxis.textAlignment = textAlignmentForLabelYAxis;
            labelYAxis.font = self.labelFont;
            labelYAxis.textColor = self.colorYaxisLabel;
            labelYAxis.backgroundColor = [UIColor clearColor];
            labelYAxis.tag = LabelYAxisTag20000;
            [labelYAxis sizeToFit];
            labelYAxis.center = CGPointMake(labelYAxis.center.x, yAxisPosition);
            [self addSubview:labelYAxis];
            [yAxisLabels addObject:labelYAxis];
            
            NSNumber *yAxisLabelCoordinate = @(labelYAxis.center.y);
            [yAxisLabelPoints addObject:yAxisLabelCoordinate];
        }
    } else {
        NSInteger numberOfLabels;
        if ([self.delegate respondsToSelector:@selector(numberOfYAxisLabelsOnLineGraph:)]) numberOfLabels = [self.delegate numberOfYAxisLabelsOnLineGraph:self];
        else numberOfLabels = 3;
        
        CGFloat graphHeight = self.frame.size.height;
        CGFloat graphSpacing = graphHeight / numberOfLabels;
        
        CGFloat yAxisPosition = graphHeight + graphSpacing/2;
        
        for (NSInteger i = numberOfLabels; i > 0; i--) {
            yAxisPosition -= graphSpacing;
            
            UILabel *labelYAxis = [[UILabel alloc] initWithFrame:frameForLabelYAxis];
            labelYAxis.center = CGPointMake(0.0f, yAxisPosition);
            labelYAxis.text = [NSString stringWithFormat:self.formatStringForValues, (graphHeight - yAxisPosition)];
            labelYAxis.font = self.labelFont;
            labelYAxis.textAlignment = textAlignmentForLabelYAxis;
            labelYAxis.textColor = self.colorYaxisLabel;
            labelYAxis.backgroundColor = [UIColor clearColor];
            labelYAxis.tag = LabelYAxisTag20000;
            [labelYAxis sizeToFit];
            
            [self addSubview:labelYAxis];
            
            [yAxisLabels addObject:labelYAxis];
            
            NSNumber *yAxisLabelCoordinate = @(labelYAxis.center.y);
            [yAxisLabelPoints addObject:yAxisLabelCoordinate];
        }
    }
    
    // Detect overlapped labels
    __block NSUInteger lastMatchIndex = 0;
    NSMutableArray *overlapLabels = [NSMutableArray arrayWithCapacity:0];
    
    [yAxisLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        
        if (idx==0) lastMatchIndex = 0;
        else { // Skip first one
            UILabel *prevLabel = yAxisLabels[lastMatchIndex];
            CGRect r = CGRectIntersection(prevLabel.frame, label.frame);
            if (CGRectIsNull(r)) lastMatchIndex = idx;
            else [overlapLabels addObject:label]; // overlapped
        }
        
        // Axis should fit into our own view
        BOOL fullyContainsLabel = CGRectContainsRect(self.bounds, label.frame);
        if (!fullyContainsLabel) {
            [overlapLabels addObject:label];
            [yAxisLabelPoints removeObject:@(label.center.y)];
        }
    }];
    
    for (UILabel *label in overlapLabels) {
        [label removeFromSuperview];
    }
    
    [yAxisReferencePoints removeAllObjects];
    if (self.referenceYAxisValues != nil) {
        for (NSNumber *yAxisValue in self.referenceYAxisValues) {
            CGFloat yAxisPosition = [self yPositionForDotValue:yAxisValue.doubleValue];
            [yAxisReferencePoints addObject:@(yAxisPosition)];
        }
    } else {
        [yAxisReferencePoints addObjectsFromArray:yAxisLabelPoints];
    }
    
    [self drawYAxisReferenceLabels];
    
    [self didFinishDrawingIncludingYAxis:YES];  
}

- (void)drawYAxisReferenceLabels {
    if (!self.enableReferenceYAxisLines) return;
    else if (self.referenceYAxisValues == nil) return;
    else if (![self.delegate respondsToSelector:@selector(lineGraph:labelOnYAxisReferenceLineForValue:)]) return;
    
    for (UIView *yAxisReferenceLabel in yAxisReferenceLabels) {
        [yAxisReferenceLabel removeFromSuperview];
    }
    
    [yAxisReferenceLabels removeAllObjects];
    
    for (NSNumber *yAxisValue in self.referenceYAxisValues)
    {
        UILabel *referenceLabelYAxis = [[UILabel alloc] init];
        referenceLabelYAxis.text = [self.delegate lineGraph:self labelOnYAxisReferenceLineForValue:yAxisValue.doubleValue];
        referenceLabelYAxis.font = self.referenceLabelFont ?: self.labelFont;
        referenceLabelYAxis.textAlignment = NSTextAlignmentRight;
        referenceLabelYAxis.textColor = self.colorYaxisLabel;
        referenceLabelYAxis.backgroundColor = [UIColor clearColor];
        referenceLabelYAxis.tag = ReferenceLabelYAxisTag40000;
        [referenceLabelYAxis sizeToFit];
        
        CGSize labelSize = referenceLabelYAxis.frame.size;
        CGFloat labelOriginX;
        if (self.positionYAxisRight) {
            labelOriginX = 5.0f;
        } else {
            labelOriginX = self.frame.size.width - 5.0f - labelSize.width;
        }
        
        CGFloat referenceYAxisPosition = [self yPositionForDotValue:yAxisValue.doubleValue];
        CGRect rect = CGRectMake(labelOriginX, referenceYAxisPosition - labelSize.height - 2.0f, labelSize.width, labelSize.height);
        if (!CGRectContainsRect(self.bounds, rect)) {
            rect.origin = CGPointMake(labelOriginX, referenceYAxisPosition + 2.0f);
        }
        [referenceLabelYAxis setFrame:rect];
        
        [self addSubview:referenceLabelYAxis];

        [yAxisReferenceLabels addObject:referenceLabelYAxis];
    }
}

/// Area on the graph that doesn't include the axes
- (CGRect)drawableGraphArea {
    CGFloat minXCord = 0.0f;
    CGFloat maxXCord = self.bounds.size.width;
    CGFloat viewWidth = maxXCord - minXCord;
    CGFloat adjustedHeight = self.bounds.size.height;
    
    CGRect rect = CGRectMake(minXCord, 0, viewWidth, adjustedHeight);
    return rect;
}

- (CGRect)drawableXAxisArea {
    NSInteger xAxisHeight = 20;
    CGFloat xAxisWidth = self.bounds.size.width;
    CGFloat xAxisXOrigin = self.bounds.origin.x;
    CGFloat xAxisYOrigin = self.bounds.size.height - xAxisHeight;
    return CGRectMake(xAxisXOrigin, xAxisYOrigin, xAxisWidth, xAxisHeight);
}

/// Calculates the optimum offset needed for the Labels to be centered on the X-Axis.
- (NSInteger)offsetForXAxisWithNumberOfGaps:(NSInteger)numberOfGaps {
    NSInteger leftGap = numberOfGaps - 1;
    NSInteger rightGap = numberOfPoints - (numberOfGaps*(numberOfPoints/numberOfGaps));
    NSInteger offset = 0;
    
    if (leftGap != rightGap) {
        for (int i = 0; i <= numberOfGaps; i++) {
            if (leftGap - i == rightGap + i) {
                offset = i;
            }
        }
    }
    
    return offset;
}

- (void)displayPermanentLabelForPoint:(BEMCircle *)circleDot {
    self.enablePopUpReport = NO;
    self.xCenterLabel = circleDot.center.x;
    
    BEMPermanentPopupLabel *permanentPopUpLabel = [[BEMPermanentPopupLabel alloc] init];
    permanentPopUpLabel.textAlignment = NSTextAlignmentCenter;
    permanentPopUpLabel.numberOfLines = 0;
    
    NSString *prefix = @"";
    NSString *suffix = @"";
    
    if ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)])
        suffix = [self.delegate popUpSuffixForlineGraph:self];

    if ([self.delegate respondsToSelector:@selector(popUpPrefixForlineGraph:)])
        prefix = [self.delegate popUpPrefixForlineGraph:self];

    int index = (int)(circleDot.tag - DotFirstTag100);
    NSNumber *value = dataValues[index]; // @((NSInteger) circleDot.absoluteValue)
    NSString *formattedValue = [NSString stringWithFormat:self.formatStringForValues, value.doubleValue];
    permanentPopUpLabel.text = [NSString stringWithFormat:@"%@%@%@", prefix, formattedValue, suffix];
    
    permanentPopUpLabel.font = self.labelFont;
    permanentPopUpLabel.backgroundColor = [UIColor clearColor];
    [permanentPopUpLabel sizeToFit];
    permanentPopUpLabel.center = CGPointMake(self.xCenterLabel, circleDot.center.y - circleDot.frame.size.height/2 - 15);
    permanentPopUpLabel.alpha = 0;
    
    BEMPermanentPopupView *permanentPopUpView = [[BEMPermanentPopupView alloc] initWithFrame:CGRectMake(0, 0, permanentPopUpLabel.frame.size.width + 7, permanentPopUpLabel.frame.size.height + 2)];
    permanentPopUpView.backgroundColor = self.colorBackgroundPopUplabel;
    permanentPopUpView.alpha = 0;
    permanentPopUpView.layer.cornerRadius = 3;
    permanentPopUpView.tag = PermanentPopUpViewTag31000;
    permanentPopUpView.center = permanentPopUpLabel.center;
    
    if (permanentPopUpLabel.frame.origin.x <= 0) {
        self.xCenterLabel = permanentPopUpLabel.frame.size.width/2 + 4;
        permanentPopUpLabel.center = CGPointMake(self.xCenterLabel, circleDot.center.y - circleDot.frame.size.height/2 - 15);
    } else if ((permanentPopUpLabel.frame.origin.x + permanentPopUpLabel.frame.size.width) >= self.frame.size.width) {
        self.xCenterLabel = self.frame.size.width - permanentPopUpLabel.frame.size.width/2 - 4;
        permanentPopUpLabel.center = CGPointMake(self.xCenterLabel, circleDot.center.y - circleDot.frame.size.height/2 - 15);
    }
    
    if (permanentPopUpLabel.frame.origin.y <= 2) {
        permanentPopUpLabel.center = CGPointMake(self.xCenterLabel, circleDot.center.y + circleDot.frame.size.height/2 + 15);
    }
    
    if ([self checkOverlapsForView:permanentPopUpView] == YES) {
        permanentPopUpLabel.center = CGPointMake(self.xCenterLabel, circleDot.center.y + circleDot.frame.size.height/2 + 15);
    }
    
    permanentPopUpView.center = permanentPopUpLabel.center;
    
    [self addSubview:permanentPopUpView];
    [self addSubview:permanentPopUpLabel];
    
    if (self.animationGraphEntranceTime == 0) {
        permanentPopUpLabel.alpha = 1;
        permanentPopUpView.alpha = 0.7;
    } else {
        [UIView animateWithDuration:0.5 delay:self.animationGraphEntranceTime options:UIViewAnimationOptionCurveLinear animations:^{
            permanentPopUpLabel.alpha = 1;
            permanentPopUpView.alpha = 0.7;
        } completion:nil];
    }
}

- (BOOL)checkOverlapsForView:(UIView *)view {
    for (UIView *viewForLabel in [self subviews]) {
        if ([viewForLabel isKindOfClass:[UIView class]] && viewForLabel.tag == PermanentPopUpViewTag31000 ) {
            if ((viewForLabel.frame.origin.x + viewForLabel.frame.size.width) >= view.frame.origin.x) {
                if (viewForLabel.frame.origin.y >= view.frame.origin.y && viewForLabel.frame.origin.y <= view.frame.origin.y + view.frame.size.height) return YES;
                else if (viewForLabel.frame.origin.y + viewForLabel.frame.size.height >= view.frame.origin.y && viewForLabel.frame.origin.y + viewForLabel.frame.size.height <= view.frame.origin.y + view.frame.size.height) return YES;
            }
        }
    }
    return NO;
}

- (UIImage *)graphSnapshotImage {
    return [self graphSnapshotImageRenderedWhileInBackground:NO];
}

- (UIImage *)graphSnapshotImageRenderedWhileInBackground:(BOOL)appIsInBackground {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    
    if (appIsInBackground == NO) [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    else [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Data Source

- (void)reloadGraph {
    for (UIView *subviews in self.subviews) {
        [subviews removeFromSuperview];
    }
    [self drawGraph];
}

#pragma mark - Calculations

- (NSArray *)calculationDataPoints {
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *value = (NSNumber *)evaluatedObject;
        BOOL retVal = ![value isEqualToNumber:@(BEMNullGraphValue)];
        return retVal;
    }];
    NSArray *filteredArray = [dataValues filteredArrayUsingPredicate:filter];
    return filteredArray;
}

- (NSNumber *)calculatePointValueAverage {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}

- (NSNumber *)calculatePointValueSum {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}

- (NSNumber *)calculatePointValueMedian {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"median:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}

- (NSNumber *)calculatePointValueMode {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"mode:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSMutableArray *value = [expression expressionValueWithObject:nil context:nil];
    
    return [value firstObject];
}

- (NSNumber *)calculateLineGraphStandardDeviation {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}

- (NSNumber *)calculateMinimumPointValue {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    return value;
}

- (NSNumber *)calculateMaximumPointValue {
    NSArray *filteredArray = [self calculationDataPoints];
    if (filteredArray.count == 0) return 0;
    
    NSExpression *expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForConstantValue:filteredArray]]];
    NSNumber *value = [expression expressionValueWithObject:nil context:nil];
    
    return value;
}


#pragma mark - Values

- (NSArray *)graphValuesForXAxis {
    return xAxisValues;
}

- (NSArray *)graphValuesForDataPoints {
    return dataValues;
}

- (NSArray *)graphLabelsForXAxis {
    return xAxisLabels;
}

- (NSArray *)graphLabelsForYAxis {
    return yAxisLabels;
}

- (NSArray *)graphReferenceLabelsForYAxis {
    return yAxisReferenceLabels;
}

- (void)setAnimationGraphStyle:(BEMLineAnimation)animationGraphStyle {
    _animationGraphStyle = animationGraphStyle;
    if (_animationGraphStyle == BEMLineAnimationNone)
        self.animationGraphEntranceTime = 0.f;
}


#pragma mark - Touch Gestures

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.panGesture]) {
        if (gestureRecognizer.numberOfTouches >= self.touchReportFingersRequired) {
            CGPoint translation = [self.panGesture velocityInView:self.panView];
            return fabs(translation.y) < fabs(translation.x);
        } else return NO;
        return YES;
    } else return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	    return YES;
}

- (void)handleGestureAction:(UIGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer locationInView:self.viewForBaselineLayout];
    CGFloat xTranslation = translation.x;
    [self panToXPositionOnGraph:xTranslation];
    
    CGFloat xAxisValue = ( xTranslation / self.frame.size.width ) * ( self.maxXValue - self.minXValue );
    BOOL endOfTouch = (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled);
    if ([self.delegate respondsToSelector:@selector(lineGraph:didTouchGraphWithXAxisValue:endOfTouch:)]) {
        BOOL endOfTouch = (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled);
        [self.delegate lineGraph:self didTouchGraphWithXAxisValue:xAxisValue endOfTouch:endOfTouch];
    }
    
    // ON RELEASE
    if (endOfTouch) [self stopPanningAnimation];
}

- (void)panToXValue:(CGFloat)xValue finishPan:(BOOL)finishPan {
    CGFloat positionOnXAxis = self.frame.size.width * (xValue - self.minXValue) / (self.maxXValue - self.minXValue);
    [self panToXPositionOnGraph:positionOnXAxis];
    if (finishPan) [self stopPanningAnimation];
}

- (void)panToXPositionOnGraph:(CGFloat)xPosition {
    if (xPosition >= 0.0f && xPosition <= self.frame.size.width) {
        self.touchInputLine.frame = CGRectMake(xPosition - self.widthTouchInputLine/2, 0, self.widthTouchInputLine, self.frame.size.height);
    }
    
    self.touchInputLine.alpha = self.alphaTouchInputLine;
    
    closestDot = [self closestDotFromTouchInputLine:self.touchInputLine];
    closestDot.alpha = 0.8;
    
    if (self.enablePopUpReport == YES && closestDot.tag >= DotFirstTag100 && closestDot.tag < DotLastTag10000 && [closestDot isKindOfClass:[BEMCircle class]] && self.alwaysDisplayPopUpLabels == NO) {
        [self setUpPopUpLabelAbovePoint:closestDot];
    }
    
    if ([self.delegate respondsToSelector:@selector(lineGraph:pannedToClosestIndex:)]) {
        [self.delegate lineGraph:self pannedToClosestIndex:(closestDot != nil ? closestDot.tag - DotFirstTag100 : NSNotFound)];
    }
}

- (void)stopPanningAnimation {
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (self.alwaysDisplayDots == NO && self.displayDotsOnly == NO) {
            closestDot.alpha = 0.0f;
        }
        
        if (self.enablePopUpReport == YES) {
            self.popUpView.alpha = 0;
            self.popUpLabel.alpha = 0;
        }
        
        if (self.autoHideTouchInputLine == YES) {
            self.touchInputLine.alpha = 0;
        }
    } completion:nil];
}

- (CGFloat)distanceToClosestPoint {
    return sqrt(pow(closestDot.center.x - self.touchInputLine.center.x, 2));
}

- (void)setUpPopUpLabelAbovePoint:(BEMCircle *)closestPoint {
    self.xCenterLabel = closestDot.center.x;
    self.yCenterLabel = closestDot.center.y - closestDot.frame.size.height/2 - 15;
    self.popUpView.center = CGPointMake(self.xCenterLabel, self.yCenterLabel);
    self.popUpLabel.center = self.popUpView.center;
    int index = (int)(closestDot.tag - DotFirstTag100);

    if ([self.delegate respondsToSelector:@selector(lineGraph:modifyPopupView:forIndex:)]) {
        [self.delegate lineGraph:self modifyPopupView:self.popUpView forIndex:index];
    }
    self.xCenterLabel = closestDot.center.x;
    self.yCenterLabel = closestDot.center.y - closestDot.frame.size.height/2 - 15;
    self.popUpView.center = CGPointMake(self.xCenterLabel, self.yCenterLabel);

    self.popUpView.alpha = 1.0;
    
    CGPoint popUpViewCenter = CGPointZero;
    
    if ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)])
        self.popUpLabel.text = [NSString stringWithFormat:@"%li%@", (long)[dataValues[(NSInteger) closestDot.tag - DotFirstTag100] integerValue], [self.delegate popUpSuffixForlineGraph:self]];
    else
        self.popUpLabel.text = [NSString stringWithFormat:@"%li", (long)[dataValues[(NSInteger) closestDot.tag - DotFirstTag100] integerValue]];
    
    if (self.popUpView.frame.origin.x <= 0) {
        self.xCenterLabel = self.popUpView.frame.size.width/2;
        popUpViewCenter = CGPointMake(self.xCenterLabel, self.yCenterLabel);
    } else if ((self.popUpView.frame.origin.x + self.popUpView.frame.size.width) >= self.frame.size.width) {
        self.xCenterLabel = self.frame.size.width - self.popUpView.frame.size.width/2;
        popUpViewCenter = CGPointMake(self.xCenterLabel, self.yCenterLabel);
    }
    
    if (self.popUpView.frame.origin.y <= 2) {
        self.yCenterLabel = closestDot.center.y + closestDot.frame.size.height/2 + 15;
        popUpViewCenter = CGPointMake(self.xCenterLabel, closestDot.center.y + closestDot.frame.size.height/2 + 15);
    }

    if (!CGPointEqualToPoint(popUpViewCenter, CGPointZero)) {
        self.popUpView.center = popUpViewCenter;
    }
    
    if (!self.usingCustomPopupView) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.popUpView.alpha = 0.7;
            self.popUpLabel.alpha = 1;
        } completion:nil];
        NSString *prefix = @"";
        NSString *suffix = @"";
        if ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)]) {
            suffix = [self.delegate popUpSuffixForlineGraph:self];
        }
        if ([self.delegate respondsToSelector:@selector(popUpPrefixForlineGraph:)]) {
            prefix = [self.delegate popUpPrefixForlineGraph:self];
        }
        NSNumber *value = dataValues[index];
        NSString *formattedValue = [NSString stringWithFormat:self.formatStringForValues, value.doubleValue];
        self.popUpLabel.text = [NSString stringWithFormat:@"%@%@%@", prefix, formattedValue, suffix];
        self.popUpLabel.center = self.popUpView.center;
    }
}

#pragma mark - Graph Calculations

- (BEMCircle *)closestDotFromTouchInputLine:(UIView *)touchInputLine {
    currentlyCloser = CGFLOAT_MAX;
    for (BEMCircle *point in self.subviews) {
        if (point.tag >= DotFirstTag100 && point.tag < DotLastTag10000 && [point isMemberOfClass:[BEMCircle class]]) {
            if (self.alwaysDisplayDots == NO && self.displayDotsOnly == NO) {
                point.alpha = 0;
            }
            if (pow(((point.center.x) - touchInputLine.center.x), 2) < currentlyCloser) {
                currentlyCloser = pow(((point.center.x) - touchInputLine.center.x), 2);
                closestDot = point;
            }
        }
    }
    return closestDot;
}

- (CGFloat)getMaximumValue {
    if ([self.delegate respondsToSelector:@selector(maxValueForLineGraph:)]) {
        return [self.delegate maxValueForLineGraph:self];
    } else {
        CGFloat dotValue;
        CGFloat maxValue = -FLT_MAX;
        
        @autoreleasepool {
            for (int i = 0; i < numberOfPoints; i++) {
                if ([self.dataSource respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                    dotValue = [self.dataSource lineGraph:self valueForPointAtIndex:i];
                    
                } else if ([self.delegate respondsToSelector:@selector(valueForIndex:)]) {
                    [self printDeprecationWarningForOldMethod:@"valueForIndex:" andReplacementMethod:@"lineGraph:valueForPointAtIndex:"];
                    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    dotValue = [self.delegate valueForIndex:i];
#pragma clang diagnostic pop
                    
                } else if ([self.delegate respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                    [self printDeprecationAndUnavailableWarningForOldMethod:@"lineGraph:valueForPointAtIndex:"];
                    NSException *exception = [NSException exceptionWithName:@"Implementing Unavailable Delegate Method" reason:@"lineGraph:valueForPointAtIndex: is no longer available on the delegate. It must be implemented on the data source." userInfo:nil];
                    [exception raise];
                    
                } else {
                    dotValue = 0;
                }
                if (dotValue == BEMNullGraphValue) {
                    continue;
                }
                
                if (dotValue > maxValue) {
                    maxValue = dotValue;
                }
            }
        }
        return maxValue;
    }
}

- (CGFloat)getMinimumValue {
    if ([self.delegate respondsToSelector:@selector(minValueForLineGraph:)]) {
        return [self.delegate minValueForLineGraph:self];
    } else {
        CGFloat dotValue;
        CGFloat minValue = INFINITY;
        
        @autoreleasepool {
            for (int i = 0; i < numberOfPoints; i++) {
                if ([self.dataSource respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                    dotValue = [self.dataSource lineGraph:self valueForPointAtIndex:i];
                    
                } else if ([self.delegate respondsToSelector:@selector(valueForIndex:)]) {
                    [self printDeprecationWarningForOldMethod:@"valueForIndex:" andReplacementMethod:@"lineGraph:valueForPointAtIndex:"];
                    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    dotValue = [self.delegate valueForIndex:i];
#pragma clang diagnostic pop
                    
                } else if ([self.delegate respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
                    [self printDeprecationAndUnavailableWarningForOldMethod:@"lineGraph:valueForPointAtIndex:"];
                    NSException *exception = [NSException exceptionWithName:@"Implementing Unavailable Delegate Method" reason:@"lineGraph:valueForPointAtIndex: is no longer available on the delegate. It must be implemented on the data source." userInfo:nil];
                    [exception raise];
                    
                } else dotValue = 0;
                
                if (dotValue == BEMNullGraphValue) {
                    continue;
                }
                if (dotValue < minValue) {
                    minValue = dotValue;
                }
            }
        }
        return minValue;
    }
}

- (CGFloat)getMinXValue {
    if ([self.delegate respondsToSelector:@selector(minXValueForLineGraph:)]) {
        return [self.delegate minXValueForLineGraph:self];
    } else {
        return [self getMinCalcXValue];
    }
}

- (CGFloat)getMaxXValue {
    if ([self.delegate respondsToSelector:@selector(maxXValueForLineGraph:)]) {
        return [self.delegate maxXValueForLineGraph:self];
    } else {
        return [self getMaxCalcXValue];
    }
}

- (CGFloat)getMinCalcXValue {
    CGFloat dotValue;
    CGFloat minValue = INFINITY;
    
    @autoreleasepool {
        for (int i = 0; i < numberOfPoints; i++) {
            if ([self.dataSource respondsToSelector:@selector(lineGraph:xValueForPointAtIndex:)]) {
                dotValue = [self.dataSource lineGraph:self xValueForPointAtIndex:i];
                
            } else dotValue = 0;
            
            if (dotValue < minValue) {
                minValue = dotValue;
            }
        }
    }
    return minValue;
}

- (CGFloat)getMaxCalcXValue {
    CGFloat dotValue;
    CGFloat maxValue = -FLT_MAX;
    
    @autoreleasepool {
        for (int i = 0; i < numberOfPoints; i++) {
            if ([self.dataSource respondsToSelector:@selector(lineGraph:xValueForPointAtIndex:)]) {
                dotValue = [self.dataSource lineGraph:self xValueForPointAtIndex:i];
                
            } else dotValue = numberOfPoints - 1;
            
            if (dotValue > maxValue) {
                maxValue = dotValue;
            }
        }
    }
    return maxValue;
}

- (CGFloat)yPositionForDotValue:(CGFloat)dotValue {
    if (dotValue == BEMNullGraphValue) {
        return BEMNullGraphValue;
    }
    
    CGFloat positionOnYAxis; // The position on the Y-axis of the point currently being created.
    CGFloat padding = self.frame.size.height/2;
    if (padding > 90.0) {
        padding = 90.0;
    }

    if ([self.delegate respondsToSelector:@selector(staticPaddingForLineGraph:)])
        padding = [self.delegate staticPaddingForLineGraph:self];
    
    if (self.minValue == self.maxValue && self.autoScaleYAxis == YES) positionOnYAxis = self.frame.size.height/2;
    else if (self.autoScaleYAxis == YES) positionOnYAxis = ((self.frame.size.height - padding/2) - ((dotValue - self.minValue) / ((self.maxValue - self.minValue) / (self.frame.size.height - padding))));
    else positionOnYAxis = ((self.frame.size.height) - dotValue);
    
    return positionOnYAxis;
}

#pragma mark - Other Methods

- (void)printDeprecationAndUnavailableWarningForOldMethod:(NSString *)oldMethod {
    NSLog(@"[BEMSimpleLineGraph] UNAVAILABLE, DEPRECATION ERROR. The delegate method, %@, is both deprecated and unavailable. It is now a data source method. You must implement this method from BEMSimpleLineGraphDataSource. Update your delegate method as soon as possible. One of two things will now happen: A) an exception will be thrown, or B) the graph will not load.", oldMethod);
}

- (void)printDeprecationWarningForOldMethod:(NSString *)oldMethod andReplacementMethod:(NSString *)replacementMethod {
    NSLog(@"[BEMSimpleLineGraph] DEPRECATION WARNING. The delegate method, %@, is deprecated and will become unavailable in a future version. Use %@ instead. Update your delegate method as soon as possible. An exception will be thrown in a future version.", oldMethod, replacementMethod);
}

@end
