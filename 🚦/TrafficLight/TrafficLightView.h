//
//  TriView.h
//  🚦
//
//  Created by Maxime Bokobza on 15/12/12.
//  Copyright (c) 2012 Maxime Bokobza. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol TrafficLightDelegate <NSObject>

- (void)lightTapped:(NSUInteger)lightIndex state:(NSString *)state;

@end


@interface TrafficLightView : UIView

@property (nonatomic, weak) IBOutlet id<TrafficLightDelegate> delegate;

@end
