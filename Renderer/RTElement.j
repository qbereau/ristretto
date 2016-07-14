
@implementation RTElement : CPObject
{
    DOMObject       _domObject;
    RTView          _view;

    CGPoint         _localPos;
    CGSize          _localSize;
    float           _angleRotation;
}

- (id)init
{
    [CPException raise:CPUnsupportedMethodException reason:"Can't init abstract class. Use concrete class"];
    return nil;
}

- (id)_initWithView:(RTView)aView
{
    if (self = [super init])
    {
        _view = aView;

        _localPos       = CGPointMake(0, 0);
        _localSize      = CGPointMake(0, 0);
    }
    return self;
}

- (DOMObject)DOMObject
{
    return _domObject;
}

- (DOMObject)graphicsContext
{
    return nil;
}

- (void)release
{

}

- (void)moveTo:(CGPoint)aPoint
{

}

- (void)moveLocallyTo:(CGPoint)aPoint
{

}

- (void)resizeTo:(CGSize)aSize
{

}

- (void)resizeLocallyTo:(CGSize)aSize
{

}

- (void)rotateLocallyTo:(float)anAngle
{

}

- (void)hide:(BOOL)isHidden
{

}

- (void)clip:(BOOL)shouldClip
{

}

- (void)setOpacity:(float)aOpacity
{

}

- (void)update
{

}

- (void)render
{

}
