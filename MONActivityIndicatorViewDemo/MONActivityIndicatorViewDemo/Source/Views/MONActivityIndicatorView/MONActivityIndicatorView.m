//
//  MONActivityIndicatorView.m
//
//  Created by Mounir Ybanez on 4/24/14.
//

#import <QuartzCore/QuartzCore.h>
#import "MONActivityIndicatorView.h"

@interface MONActivityIndicatorLayer : CALayer

@property (nonatomic, weak, readonly) MONActivityIndicatorView *view;

@end

@implementation MONActivityIndicatorLayer

- (MONActivityIndicatorView *)view {
    return (MONActivityIndicatorView *)self.delegate;
}

- (void)removeAllAnimations {
    [super removeAllAnimations];
    
    // `-[UITableViewCell prepareForReuse]` and `-[UICollectionViewCell prepareForReuse]` remove all animations from
    // child views. There is no way to restart animations automatically (as we do it in `-didMoveToWindow`).
    // So, we have to stop animating.
    // Note: We can't do it in `-animationDidStop:finished:` animation delegate, because the delegate method is called
    // asynchronously.
    [self.view stopAnimating];
}

@end

@interface MONActivityIndicatorView ()

/** The default color of each circle. */
@property (strong, nonatomic) UIColor *defaultColor;

/** Indicates whether the activity indicator view is animating. */
@property (readwrite, nonatomic, getter=isAnimating) BOOL animating;

/**
 Sets up default values
 */
- (void)setupDefaults;

/**
 Adds circles.
 */
- (void)addCircles;

/**
 Removes circles.
 */
- (void)removeCircles;

/**
 Adds animations to the circle layers.
 */
- (void)addCircleAnimations;

/**
 Creates the circle view.
 @param radius The radius of the circle.
 @param color The background color of the circle.
 @param x The x-position of the circle in the contentView.
 @return The circle view.
 */
- (UIView *)createCircleWithRadius:(CGFloat)radius color:(UIColor *)color positionX:(CGFloat)x;

/**
 Creates the animation of the circle.
 @param duration The duration of the animation.
 @param delay The delay of the animation
 @return The animation of the circle.
 */
- (CABasicAnimation *)createAnimationWithDuration:(CGFloat)duration delay:(CGFloat)delay;

@end

@implementation MONActivityIndicatorView

#pragma mark -
#pragma mark - Initializations

- (id)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

#pragma mark -
#pragma mark - UIViews

+ (Class)layerClass {
    return [MONActivityIndicatorLayer class];
}

- (CGSize)intrinsicContentSize {
    CGFloat width = (self.numberOfCircles * ((2 * self.radius) + self.internalSpacing)) - self.internalSpacing;
    CGFloat height = self.radius * 2;
    return CGSizeMake(width, height);
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.intrinsicContentSize;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    // Core Animation animations are removed when the view is remove from a window.
    // So, we have to add the animations again when the view is added to a window.
    if (self.window && self.animating) {
        [self addCircleAnimations];
    }
}

#pragma mark -
#pragma mark - Private Methods

- (void)setupDefaults {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberOfCircles = 5;
    self.internalSpacing = 5;
    self.radius = 10;
    self.delay = 0.2;
    self.duration = 0.8;
    self.defaultColor = [UIColor lightGrayColor];
}

- (UIView *)createCircleWithRadius:(CGFloat)radius
                             color:(UIColor *)color
                         positionX:(CGFloat)x {
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(x, 0, radius * 2, radius * 2)];
    circle.backgroundColor = color;
    circle.layer.cornerRadius = radius;
    circle.translatesAutoresizingMaskIntoConstraints = NO;
    return circle;
}

- (CABasicAnimation *)createAnimationWithDuration:(CGFloat)duration delay:(CGFloat)delay {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    anim.fromValue = [NSNumber numberWithFloat:0.0f];
    anim.toValue = [NSNumber numberWithFloat:1.0f];
    anim.autoreverses = YES;
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.beginTime = CACurrentMediaTime()+delay;
    anim.repeatCount = INFINITY;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return anim;
}

- (void)addCircles {
    for (NSUInteger i = 0; i < self.numberOfCircles; i++) {
        UIColor *color = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(activityIndicatorView:circleBackgroundColorAtIndex:)]) {
            color = [self.delegate activityIndicatorView:self circleBackgroundColorAtIndex:i];
        }
        UIView *circle = [self createCircleWithRadius:self.radius
                                                color:color ?: self.defaultColor
                                            positionX:(i * ((2 * self.radius) + self.internalSpacing))];
        circle.transform = CGAffineTransformMakeScale(0, 0);
        [self addSubview:circle];
    }
    
    if (self.window) {
        [self addCircleAnimations];
    }
}

- (void)removeCircles {
    [self.subviews enumerateObjectsUsingBlock:^(UIView *circle, NSUInteger index, BOOL *stop) {
        [circle removeFromSuperview];
    }];
}

- (void)addCircleAnimations {
    [self.subviews enumerateObjectsUsingBlock:^(UIView *circle, NSUInteger index, BOOL *stop) {
        [circle.layer addAnimation:[self createAnimationWithDuration:self.duration delay:(index * self.delay)] forKey:@"scale"];
    }];
}

#pragma mark -
#pragma mark - Public Methods

- (void)startAnimating {
    if (!self.animating) {
        [self addCircles];
        self.hidden = NO;
        self.animating = YES;
    }
}

- (void)stopAnimating {
    if (self.animating) {
        [self removeCircles];
        self.hidden = YES;
        self.animating = NO;
    }
}

#pragma mark -
#pragma mark - Custom Setters and Getters

- (void)setNumberOfCircles:(NSUInteger)numberOfCircles {
    _numberOfCircles = numberOfCircles;
    [self invalidateIntrinsicContentSize];
}

- (void)setRadius:(CGFloat)radius {
    _radius = radius;
    [self invalidateIntrinsicContentSize];
}

- (void)setInternalSpacing:(CGFloat)internalSpacing {
    _internalSpacing = internalSpacing;
    [self invalidateIntrinsicContentSize];
}

@end
