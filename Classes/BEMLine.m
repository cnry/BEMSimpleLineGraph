//
//  BEMLine.m
//  SimpleLineGraph
//
//  Created by Bobo on 12/27/13. Updated by Sam Spencer on 1/11/14.
//  Copyright (c) 2013 Boris Emorine. All rights reserved.
//  Copyright (c) 2014 Sam Spencer.
//

#import "BEMLine.h"
#import "BEMSimpleLineGraphView.h"

#if CGFLOAT_IS_DOUBLE
#define CGFloatValue doubleValue
#else
#define CGFloatValue floatValue
#endif


@interface BEMLine()

@property (nonatomic, strong) NSMutableArray *points;

@property (strong, nonatomic) CAShapeLayer *pathLayer;
@property (strong, nonatomic) CAShapeLayer *abovePathLayer;
@property (strong, nonatomic) CAShapeLayer *belowPathLayer;
@property (strong, nonatomic) CAShapeLayer *verticalReferenceLinesPathLayer;
@property (strong, nonatomic) CAShapeLayer *horizontalReferenceLinesPathLayer;

@end

@implementation BEMLine

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _enableLeftReferenceFrameLine = YES;
        _enableBottomReferenceFrameLine = YES;
        _interpolateNullValues = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    //----------------------------//
    //---- Draw Refrence Lines ---//
    //----------------------------//
    UIBezierPath *verticalReferenceLinesPath = [UIBezierPath bezierPath];
    UIBezierPath *horizontalReferenceLinesPath = [UIBezierPath bezierPath];
    UIBezierPath *referenceFramePath = [UIBezierPath bezierPath];

    verticalReferenceLinesPath.lineCapStyle = kCGLineCapButt;
    verticalReferenceLinesPath.lineWidth = 0.7;

    horizontalReferenceLinesPath.lineCapStyle = kCGLineCapButt;
    horizontalReferenceLinesPath.lineWidth = 0.7;

    referenceFramePath.lineCapStyle = kCGLineCapButt;
    referenceFramePath.lineWidth = 0.7;

    if (self.enableRefrenceFrame == YES) {
        if (self.enableBottomReferenceFrameLine) {
            // Bottom Line
            [referenceFramePath moveToPoint:CGPointMake(0, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        }

        if (self.enableLeftReferenceFrameLine) {
            // Left Line
            [referenceFramePath moveToPoint:CGPointMake(0+self.referenceLineWidth/2, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(0+self.referenceLineWidth/2, 0)];
        }

        if (self.enableTopReferenceFrameLine) {
            // Top Line
            [referenceFramePath moveToPoint:CGPointMake(0+self.referenceLineWidth/2, 0)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width, 0)];
        }

        if (self.enableRightReferenceFrameLine) {
            // Right Line
            [referenceFramePath moveToPoint:CGPointMake(self.frame.size.width - self.referenceLineWidth/2, self.frame.size.height)];
            [referenceFramePath addLineToPoint:CGPointMake(self.frame.size.width - self.referenceLineWidth/2, 0)];
        }
    }

    if (self.enableRefrenceLines == YES) {
        if (self.arrayOfVerticalRefrenceLinePoints.count > 0) {
            for (NSNumber *xNumber in self.arrayOfVerticalRefrenceLinePoints) {
                CGFloat xValue;
                if (self.verticalReferenceHorizontalFringeNegation != 0.0) {
                    if ([self.arrayOfVerticalRefrenceLinePoints indexOfObject:xNumber] == 0) { // far left reference line
                        xValue = [xNumber floatValue] + self.verticalReferenceHorizontalFringeNegation;
                    } else if ([self.arrayOfVerticalRefrenceLinePoints indexOfObject:xNumber] == [self.arrayOfVerticalRefrenceLinePoints count]-1) { // far right reference line
                        xValue = [xNumber floatValue] - self.verticalReferenceHorizontalFringeNegation;
                    } else xValue = [xNumber floatValue];
                } else xValue = [xNumber floatValue];

                CGPoint initialPoint = CGPointMake(xValue, self.frame.size.height);
                CGPoint finalPoint = CGPointMake(xValue, 0);

                [verticalReferenceLinesPath moveToPoint:initialPoint];
                [verticalReferenceLinesPath addLineToPoint:finalPoint];
            }
        }

        if (self.arrayOfHorizontalRefrenceLinePoints.count > 0) {
            for (NSNumber *yNumber in self.arrayOfHorizontalRefrenceLinePoints) {
                CGFloat yValue = yNumber.floatValue;
                if ( yValue < 0.0f || yValue > self.frame.size.height )
                {
                    continue;
                }
                CGPoint initialPoint = CGPointMake(0.0f, yValue);
                CGPoint finalPoint = CGPointMake(self.frame.size.width, yValue);
                
                [horizontalReferenceLinesPath moveToPoint:initialPoint];
                [horizontalReferenceLinesPath addLineToPoint:finalPoint];
            }
        }
    }


    //----------------------------//
    //----- Draw Average Line ----//
    //----------------------------//
    UIBezierPath *averageLinePath = [UIBezierPath bezierPath];
    if (self.averageLine.enableAverageLine == YES) {
        averageLinePath.lineCapStyle = kCGLineCapButt;
        averageLinePath.lineWidth = self.averageLine.width;

        CGPoint initialPoint = CGPointMake(0, self.averageLineYCoordinate);
        CGPoint finalPoint = CGPointMake(self.frame.size.width, self.averageLineYCoordinate);

        [averageLinePath moveToPoint:initialPoint];
        [averageLinePath addLineToPoint:finalPoint];
    }


    //----------------------------//
    //------ Draw Graph Line -----//
    //----------------------------//
    // LINE
    UIBezierPath *line = [UIBezierPath bezierPath];
    UIBezierPath *fillTop;
    UIBezierPath *fillBottom;

    self.points = [NSMutableArray arrayWithCapacity:self.arrayOfPoints.count];
    for (int i = 0; i < self.arrayOfPoints.count; i++) {
        NSValue *pointValue = self.arrayOfPoints[i];
        CGPoint point = [pointValue CGPointValue];
        if (point.y != BEMNullGraphValue || !self.interpolateNullValues) {
            [self.points addObject:pointValue];
        }
    }

    BOOL bezierStatus = self.bezierCurveIsEnabled;
    if (self.arrayOfPoints.count <= 2 && self.bezierCurveIsEnabled == YES) bezierStatus = NO;
    
    if (!self.disableMainLine && bezierStatus) {
        line = [BEMLine quadCurvedPathWithPoints:self.points];
        fillBottom = [BEMLine quadCurvedPathWithPoints:self.bottomPointsArray];
        fillTop = [BEMLine quadCurvedPathWithPoints:self.topPointsArray];
    } else if (!self.disableMainLine && !bezierStatus) {
        line = [BEMLine linesToPoints:self.points];
        fillBottom = [BEMLine linesToPoints:self.bottomPointsArray];
        fillTop = [BEMLine linesToPoints:self.topPointsArray];
    } else {
        fillBottom = [BEMLine linesToPoints:self.bottomPointsArray];
        fillTop = [BEMLine linesToPoints:self.topPointsArray];
    }

    //----------------------------//
    //----- Draw Fill Colors -----//
    //----------------------------//
    CAShapeLayer *abovePathLayer = [CAShapeLayer layer];
    abovePathLayer.frame = self.bounds;
    abovePathLayer.path  = fillTop.CGPath;
    abovePathLayer.fillColor = self.topColor.CGColor;
    abovePathLayer.opacity = self.topAlpha;
    abovePathLayer.lineWidth = 0.0f;
    abovePathLayer.lineJoin = kCALineJoinBevel;
    abovePathLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:abovePathLayer];
    self.abovePathLayer = abovePathLayer;
    
    CAShapeLayer *belowPathLayer = [CAShapeLayer layer];
    belowPathLayer.frame = self.bounds;
    belowPathLayer.path  = fillBottom.CGPath;
    belowPathLayer.fillColor = self.bottomColor.CGColor;
    belowPathLayer.opacity = self.bottomAlpha;
    belowPathLayer.lineWidth = 0.0f;
    belowPathLayer.lineJoin = kCALineJoinBevel;
    belowPathLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:belowPathLayer];
    self.belowPathLayer = belowPathLayer;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.topGradient != nil) {
        CGContextSaveGState(ctx);
        CGContextAddPath(ctx, [fillTop CGPath]);
        CGContextClip(ctx);
        CGContextDrawLinearGradient(ctx, self.topGradient, CGPointZero, CGPointMake(0, CGRectGetMaxY(fillTop.bounds)), 0);
        CGContextRestoreGState(ctx);
    }

    if (self.bottomGradient != nil) {
        CGContextSaveGState(ctx);
        CGContextAddPath(ctx, [fillBottom CGPath]);
        CGContextClip(ctx);
        CGContextDrawLinearGradient(ctx, self.bottomGradient, CGPointZero, CGPointMake(0, CGRectGetMaxY(fillBottom.bounds)), 0);
        CGContextRestoreGState(ctx);
    }


    //----------------------------//
    //------ Animate Drawing -----//
    //----------------------------//
    if (self.enableRefrenceLines == YES) {
        CAShapeLayer *verticalReferenceLinesPathLayer = [CAShapeLayer layer];
        verticalReferenceLinesPathLayer.frame = self.bounds;
        verticalReferenceLinesPathLayer.path = verticalReferenceLinesPath.CGPath;
        verticalReferenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
        verticalReferenceLinesPathLayer.fillColor = nil;
        verticalReferenceLinesPathLayer.lineWidth = self.referenceLineWidth;
        
        if (self.lineDashPatternForReferenceYAxisLines) {
            verticalReferenceLinesPathLayer.lineDashPattern = self.lineDashPatternForReferenceYAxisLines;
        }

        if (self.referenceLineColor) {
            verticalReferenceLinesPathLayer.strokeColor = self.referenceLineColor.CGColor;
        } else {
            verticalReferenceLinesPathLayer.strokeColor = self.color.CGColor;
        }

        if (self.animationTime > 0)
            [self animateForLayer:verticalReferenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
        [self.layer addSublayer:verticalReferenceLinesPathLayer];
        self.verticalReferenceLinesPathLayer = verticalReferenceLinesPathLayer;

        CAShapeLayer *horizontalReferenceLinesPathLayer = [CAShapeLayer layer];
        horizontalReferenceLinesPathLayer.frame = self.bounds;
        horizontalReferenceLinesPathLayer.path = horizontalReferenceLinesPath.CGPath;
        horizontalReferenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
        horizontalReferenceLinesPathLayer.fillColor = nil;
        horizontalReferenceLinesPathLayer.lineWidth = self.referenceLineWidth;
        if(self.lineDashPatternForReferenceXAxisLines) {
            horizontalReferenceLinesPathLayer.lineDashPattern = self.lineDashPatternForReferenceXAxisLines;
        }

        if (self.referenceLineColor) {
            horizontalReferenceLinesPathLayer.strokeColor = self.referenceLineColor.CGColor;
        } else {
            horizontalReferenceLinesPathLayer.strokeColor = self.color.CGColor;
        }

        if (self.animationTime > 0)
            [self animateForLayer:horizontalReferenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
        [self.layer addSublayer:horizontalReferenceLinesPathLayer];
        self.horizontalReferenceLinesPathLayer = horizontalReferenceLinesPathLayer;
    }

    CAShapeLayer *referenceLinesPathLayer = [CAShapeLayer layer];
    referenceLinesPathLayer.frame = self.bounds;
    referenceLinesPathLayer.path = referenceFramePath.CGPath;
    referenceLinesPathLayer.opacity = self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2;
    referenceLinesPathLayer.fillColor = nil;
    referenceLinesPathLayer.lineWidth = self.referenceLineWidth;

    if (self.referenceLineColor) referenceLinesPathLayer.strokeColor = self.referenceLineColor.CGColor;
    else referenceLinesPathLayer.strokeColor = self.color.CGColor;

    if (self.animationTime > 0)
        [self animateForLayer:referenceLinesPathLayer withAnimationType:self.animationType isAnimatingReferenceLine:YES];
    [self.layer addSublayer:referenceLinesPathLayer];

    if (self.disableMainLine == NO) {
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.frame = self.bounds;
        pathLayer.path = line.CGPath;
        pathLayer.strokeColor = self.color.CGColor;
        pathLayer.fillColor = nil;
        pathLayer.opacity = self.lineAlpha;
        pathLayer.lineWidth = self.lineWidth;
        pathLayer.lineJoin = kCALineJoinBevel;
        pathLayer.lineCap = kCALineCapRound;
        if (self.animationTime > 0) [self animateForLayer:pathLayer withAnimationType:self.animationType isAnimatingReferenceLine:NO];
        if (self.lineGradient) [self.layer addSublayer:[self backgroundGradientLayerForLayer:pathLayer]];
        else [self.layer addSublayer:pathLayer];
        self.pathLayer = pathLayer;
    }

    if (self.averageLine.enableAverageLine == YES) {
        CAShapeLayer *averageLinePathLayer = [CAShapeLayer layer];
        averageLinePathLayer.frame = self.bounds;
        averageLinePathLayer.path = averageLinePath.CGPath;
        averageLinePathLayer.opacity = self.averageLine.alpha;
        averageLinePathLayer.fillColor = nil;
        averageLinePathLayer.lineWidth = self.averageLine.width;

        if (self.averageLine.dashPattern) averageLinePathLayer.lineDashPattern = self.averageLine.dashPattern;

        if (self.averageLine.color) averageLinePathLayer.strokeColor = self.averageLine.color.CGColor;
        else averageLinePathLayer.strokeColor = self.color.CGColor;

        if (self.animationTime > 0)
            [self animateForLayer:averageLinePathLayer withAnimationType:self.animationType isAnimatingReferenceLine:NO];
        [self.layer addSublayer:averageLinePathLayer];
    }
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self.pathLayer setStrokeColor:color.CGColor];
}

- (void)setShadowColor:(UIColor *)shadowColor {
    _shadowColor = shadowColor;
    [self.pathLayer setShadowColor:shadowColor.CGColor];
}

- (void)setTopColor:(UIColor *)topColor {
    _topColor = topColor;
    [self.abovePathLayer setFillColor:topColor.CGColor];
}

- (void)setTopAlpha:(float)topAlpha {
    _topAlpha = topAlpha;
    [self.abovePathLayer setOpacity:topAlpha];
}

- (void)setBottomColor:(UIColor *)bottomColor {
    _bottomColor = bottomColor;
    [self.belowPathLayer setFillColor:bottomColor.CGColor];
}

- (void)setBottomAlpha:(float)bottomAlpha {
    _bottomAlpha = bottomAlpha;
    [self.belowPathLayer setOpacity:bottomAlpha];
}

- (void)setReferenceLineColor:(UIColor *)referenceLineColor {
    _referenceLineColor = referenceLineColor;
    struct CGColor *referenceLineCGColor = ( referenceLineColor ? referenceLineColor.CGColor : self.color.CGColor );
    self.horizontalReferenceLinesPathLayer.strokeColor = referenceLineCGColor;
    self.verticalReferenceLinesPathLayer.strokeColor = referenceLineCGColor;
}

- (NSArray *)topPointsArray {
    NSMutableArray *topPoints = [NSMutableArray arrayWithArray:self.points];
    NSNumber *firstPointValue = [topPoints firstObject];
    CGPoint firstPoint = firstPointValue != nil ? [firstPointValue CGPointValue] : CGPointMake(0.0f, self.frame.size.height);
    NSNumber *lastPointValue = [topPoints lastObject];
    CGPoint lastPoint = lastPointValue != nil ? [lastPointValue CGPointValue] : CGPointMake(self.frame.size.width, self.frame.size.height);
    
    NSValue *topPointZeroValue = [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.0f)];
    NSValue *bottomPointZeroValue = [NSValue valueWithCGPoint:CGPointMake(0.0f, self.frame.size.height)];
    NSValue *bottomPointStartValue = [NSValue valueWithCGPoint:CGPointMake(firstPoint.x, self.frame.size.height)];
    NSArray *startPointValues = @[topPointZeroValue, bottomPointZeroValue, bottomPointStartValue];
    
    NSValue *bottomPointEndValue = [NSValue valueWithCGPoint:CGPointMake(lastPoint.x, self.frame.size.height)];
    NSValue *bottomPointFullValue = [NSValue valueWithCGPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    NSValue *topPointFullValue = [NSValue valueWithCGPoint:CGPointMake(self.frame.size.width, 0.0f)];
    NSArray *endPointValues = @[bottomPointEndValue, bottomPointFullValue, topPointFullValue];
    
    [topPoints insertObjects:startPointValues atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, startPointValues.count)]];
    [topPoints addObjectsFromArray:endPointValues];
    return topPoints;
}

- (NSArray *)bottomPointsArray {
    NSMutableArray *bottomPoints = [NSMutableArray arrayWithArray:self.points];
    
    NSNumber *firstPointValue = [bottomPoints firstObject];
    CGPoint firstPoint = firstPointValue != nil ? [firstPointValue CGPointValue] : CGPointMake(0.0f, self.frame.size.height);
    NSNumber *lastPointValue = [bottomPoints lastObject];
    CGPoint lastPoint = lastPointValue != nil ? [lastPointValue CGPointValue] : CGPointMake(self.frame.size.width, self.frame.size.height);
    CGPoint bottomPointStart = CGPointMake(firstPoint.x, self.frame.size.height);
    CGPoint bottomPointEnd = CGPointMake(lastPoint.x, self.frame.size.height);
    [bottomPoints insertObject:[NSValue valueWithCGPoint:bottomPointStart] atIndex:0];
    [bottomPoints addObject:[NSValue valueWithCGPoint:bottomPointEnd]];
    return bottomPoints;
}

+ (UIBezierPath *)linesToPoints:(NSArray *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    if ( [points count] == 0 ) {
        return path;
    }
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
    }
    return path;
}

+ (UIBezierPath *)quadCurvedPathWithPoints:(NSArray *)points {
    UIBezierPath *path = [UIBezierPath bezierPath];
    if ( [points count] == 0 ) {
        return path;
    }
    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    if (points.count == 2) {
        value = points[1];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
        return path;
    }
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = midPointForPoints(p1, p2);
        [path addQuadCurveToPoint:midPoint controlPoint:controlPointForPoints(midPoint, p1)];
        [path addQuadCurveToPoint:p2 controlPoint:controlPointForPoints(midPoint, p2)];
        
        p1 = p2;
    }
    return path;
}

static CGPoint midPointForPoints(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

static CGPoint controlPointForPoints(CGPoint p1, CGPoint p2) {
    CGPoint controlPoint = midPointForPoints(p1, p2);
    CGFloat diffY = fabs(p2.y - controlPoint.y);

    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;

    return controlPoint;
}

- (void)animateForLayer:(CAShapeLayer *)shapeLayer withAnimationType:(BEMLineAnimation)animationType isAnimatingReferenceLine:(BOOL)shouldHalfOpacity {
    if (animationType == BEMLineAnimationNone) return;
    else if (animationType == BEMLineAnimationFade) {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pathAnimation.duration = self.animationTime;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        if (shouldHalfOpacity == YES) pathAnimation.toValue = [NSNumber numberWithFloat:self.lineAlpha == 0 ? 0.1 : self.lineAlpha/2];
        else pathAnimation.toValue = [NSNumber numberWithFloat:self.lineAlpha];
        [shapeLayer addAnimation:pathAnimation forKey:@"opacity"];

        return;
    } else if (animationType == BEMLineAnimationExpand) {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
        pathAnimation.duration = self.animationTime;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:shapeLayer.lineWidth];
        [shapeLayer addAnimation:pathAnimation forKey:@"lineWidth"];

        return;
    } else {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = self.animationTime;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];

        return;
    }
}

- (CALayer *)backgroundGradientLayerForLayer:(CAShapeLayer *)shapeLayer {
    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef imageCtx = UIGraphicsGetCurrentContext();
    CGPoint start, end;
    if (self.lineGradientDirection == BEMLineGradientDirectionHorizontal) {
        start = CGPointMake(0, CGRectGetMidY(shapeLayer.bounds));
        end = CGPointMake(CGRectGetMaxX(shapeLayer.bounds), CGRectGetMidY(shapeLayer.bounds));
    } else {
        start = CGPointMake(CGRectGetMidX(shapeLayer.bounds), 0);
        end = CGPointMake(CGRectGetMidX(shapeLayer.bounds), CGRectGetMaxY(shapeLayer.bounds));
    }

    CGContextDrawLinearGradient(imageCtx, self.lineGradient, start, end, 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CALayer *gradientLayer = [CALayer layer];
    gradientLayer.frame = self.bounds;
    gradientLayer.contents = (id)image.CGImage;
    gradientLayer.mask = shapeLayer;
    return gradientLayer;
}

@end
