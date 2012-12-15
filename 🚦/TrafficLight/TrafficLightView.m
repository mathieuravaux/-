//
//  TriView.m
//  🚦
//
//  Created by Maxime Bokobza on 15/12/12.
//  Copyright (c) 2012 Maxime Bokobza. All rights reserved.
//

#import "TrafficLightView.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat kHeight = 400.f;
static CGFloat kWidth = 150.f;
static CGFloat kLightRadius = 56.f;


@interface TrafficLightView ()

@property (nonatomic, strong) NSMutableArray *lightLayers;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;

- (void)tap:(UITapGestureRecognizer *)gesture;

@end


@implementation TrafficLightView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSArray *ys = @[@(0), @(floorf((kHeight - kWidth) / 2)), @(kHeight - kWidth)];
    
    self.lightLayers = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < 3; i++) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.bounds = CGRectMake(0, 0, kLightRadius * 2, kLightRadius * 2);
        layer.position = CGPointMake(floorf(self.bounds.size.width / 2),
                                     floorf((self.bounds.size.height - kHeight + kWidth) / 2) + [ys[i] floatValue]);
        [layer setPath:[[UIBezierPath bezierPathWithOvalInRect:layer.bounds] CGPath]];
        [layer setFillColor:[@[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor]][i] CGColor]];
        [self.layer addSublayer:layer];
        self.lightLayers[i] = layer;
    }
    
    self.singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(tap:)];
    [self addGestureRecognizer:self.singleTapGesture];
    self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(tap:)];
    self.doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:self.doubleTapGesture];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor blackColor] setFill];
    
    UIBezierPath *backgroundPath = [UIBezierPath bezierPath];
    [backgroundPath moveToPoint:CGPointMake(0, floorf(kWidth / 2))];
    [backgroundPath addArcWithCenter:CGPointMake(floorf(kWidth / 2), floorf(kWidth / 2))
                              radius:floorf(kWidth / 2)
                          startAngle:M_PI
                            endAngle:0
                           clockwise:YES];
    [backgroundPath addLineToPoint:CGPointMake(kWidth, kHeight - floorf(kWidth / 2))];
    [backgroundPath addArcWithCenter:CGPointMake(floorf(kWidth / 2), kHeight - floorf(kWidth / 2))
                              radius:floorf(kWidth / 2)
                          startAngle:0
                            endAngle:M_PI
                           clockwise:YES];
    [backgroundPath addLineToPoint:CGPointMake(0, floorf(kWidth / 2))];
    
    NSArray *ys = @[@(floorf(kWidth / 2)), @(floorf(kHeight / 2)), @(kHeight - floorf(kWidth / 2))];
    for (NSNumber *centerY in ys) {
        [backgroundPath moveToPoint:CGPointMake(kLightRadius, [centerY floatValue])];
        [backgroundPath addArcWithCenter:CGPointMake(floorf(kWidth / 2), [centerY floatValue])
                                  radius:kLightRadius
                              startAngle:0
                                endAngle:M_PI * 2
                               clockwise:NO];
    }
    
    [backgroundPath closePath];
    
    CGContextTranslateCTM(context,
                          floorf((rect.size.width - kWidth) / 2),
                          floorf((rect.size.height - kHeight) / 2));
    
    [backgroundPath fill];
}

- (void)tap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    for (int i = 0; i < [self.lightLayers count]; i++) {
        if (CGRectContainsPoint([self.lightLayers[i] frame], point)) {
            if ([gesture isEqual:self.doubleTapGesture]) {
                [self.delegate lightTapped:i state:@"blinking"];
                [self.lightLayers[i] setOpacity:1];
                return;
            }
            [self.delegate lightTapped:i state:@[@"on", @"off"][(int)[self.lightLayers[i] opacity]]];
            [self.lightLayers[i] setOpacity:![self.lightLayers[i] opacity]];
            return;
        }
    }
}

@end
