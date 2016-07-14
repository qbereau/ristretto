@import <Foundation/CPArray.j>
@import <Foundation/CPObjJRuntime.j>
@import <Foundation/CPSet.j>

@import "../CoreGraphics/CGAffineTransform.j"
@import "../CoreGraphics/CGGeometry.j"

@import "../Cappuccino/CPResponder.j"
@import "../Cappuccino/CPColor.j"
@import "../Cappuccino/CPGeometry.j"

@import "../Renderer/Renderer.j"


/*
    @global
    @group RTViewAutoresizingMasks
    The default resizingMask, the view will not resize or reposition itself.
*/
RTViewNotSizable    = 0;
/*
    @global
    @group RTViewAutoresizingMasks
    Allow for flexible space on the left hand side of the view.
*/
RTViewMinXMargin    = 1;
/*
    @global
    @group RTViewAutoresizingMasks
    The view should grow and shrink horizontally with its parent view.
*/
RTViewWidthSizable  = 2;
/*
    @global
    @group RTViewAutoresizingMasks
    Allow for flexible space to the right hand side of the view.
*/
RTViewMaxXMargin    = 4;
/*
    @global
    @group RTViewAutoresizingMasks
    Allow for flexible space above the view.
*/
RTViewMinYMargin    = 8;
/*
    @global
    @group RTViewAutoresizingMasks
    The view should grow and shrink vertically with its parent view.
*/
RTViewHeightSizable = 16;
/*
    @global
    @group RTViewAutoresizingMasks
    Allow for flexible space below the view.
*/
RTViewMaxYMargin    = 32;

RTViewBoundsDidChangeNotification   = @"RTViewBoundsDidChangeNotification";
RTViewFrameDidChangeNotification    = @"RTViewFrameDidChangeNotification";

var CachedNotificationCenter    = nil,
    CachedThemeAttributes       = nil;

var RTViewFlags                     = { },
    RTViewHasCustomDrawRect         = 1 << 0,
    RTViewHasCustomLayoutSubviews   = 1 << 1;


BackgroundTrivialColor              = 0,
BackgroundVerticalThreePartImage    = 1,
BackgroundHorizontalThreePartImage  = 2,
BackgroundNinePartImage             = 3,
BackgroundTransparentColor          = 4;
BackgroundImage                     = 5;


// Animation
RTViewAnimationOptionLayoutSubviews             = 0;
RTViewAnimationOptionAllowUserInteraction       = 1;
RTViewAnimationOptionRepeat                     = 2;
RTViewAnimationOptionAutoreverse                = 4;

RTViewAnimationOptionCurveEaseInOut             = 8;
RTViewAnimationOptionCurveEaseIn                = 16;
RTViewAnimationOptionCurveEaseOut               = 32;
RTViewAnimationOptionCurveLinear                = 64;

RTAnimationDirectionStraight                    = 1;
RTAnimationDirectionReverse                     = -1;

/*!
    @ingroup appkit
    @class RTView

    <p>RTView is a class which provides facilities for drawing
    in a window and receiving events. It is the superclass of many of the visual
    elements of the GUI.</p>

    <p>In order to display itself, a view must be placed in a window (represented by an
    CPWindow object). Within the window is a hierarchy of RTViews,
    headed by the window's content view. Every other view in a window is a descendant
    of this view.</p>

    <p>Subclasses can override \c -drawRect: in order to implement their
    appearance. Other methods of RTView and CPResponder can
    also be overridden to handle user generated events.
*/
@implementation RTView : CPResponder
{
    RTView              _superview;
    CPArray             _subviews;

    int                 _tag;

    RTElement           _element    @accessors(readonly,getter=element);

    CGRect              _frame;
    CGRect              _bounds;
    CGAffineTransform   _boundsTransform;
    CGAffineTransform   _inverseBoundsTransform;

    BOOL                _isHidden;

    BOOL                _postsFrameChangedNotifications;
    BOOL                _postsBoundsChangedNotifications;
    BOOL                _inhibitFrameAndBoundsChangedNotifications;
    BOOL                _inLiveResize;

    CGRect              _dirtyRect;

    float               _opacity;
    CPColor             _backgroundColor;

    BOOL                _autoresizesSubviews;
    unsigned            _autoresizingMask;

    // Layout Support
    BOOL                _needsLayout;

    unsigned            _viewClassFlags;

    // Animation
    int                 _animationAutoRepeat;
    BOOL                _animationAutoReverse;
}

/*
    Private method for Objective-J.
    @ignore
*/
+ (void)initialize
{
    if (self !== [RTView class])
        return;

    CachedNotificationCenter = [CPNotificationCenter defaultCenter];
}

- (void)_setupViewFlags
{
    var theClass = [self class],
        classUID = [theClass UID];

    if (RTViewFlags[classUID] === undefined)
    {
        var flags = 0;

        if ([theClass instanceMethodForSelector:@selector(drawRect:)] !== [RTView instanceMethodForSelector:@selector(drawRect:)])
            flags |= RTViewHasCustomDrawRect;

        if ([theClass instanceMethodForSelector:@selector(layoutSubviews)] !== [RTView instanceMethodForSelector:@selector(layoutSubviews)])
            flags |= RTViewHasCustomLayoutSubviews;

        RTViewFlags[classUID] = flags;
    }

    _viewClassFlags = RTViewFlags[classUID];
}

+ (CPSet)keyPathsForValuesAffectingFrame
{
    return [CPSet setWithObjects:@"frameOrigin", @"frameSize"];
}

+ (CPSet)keyPathsForValuesAffectingBounds
{
    return [CPSet setWithObjects:@"boundsOrigin", @"boundsSize"];
}

- (id)init
{
    return [self initWithFrame:CGRectMakeZero()];
}

/*!
    Initializes the receiver for usage with the specified bounding rectangle
    @return the initialized view
*/
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super init];

    if (self)
    {
        var width = CGRectGetWidth(aFrame),
            height = CGRectGetHeight(aFrame);

        _subviews = [];

        _tag = -1;

        _frame = CGRectMakeCopy(aFrame);
        _bounds = CGRectMake(0.0, 0.0, width, height);

        _autoresizingMask = RTViewNotSizable;
        _autoresizesSubviews = YES;
        _clipsToBounds = YES;

        _opacity = 1.0;
        _isHidden = NO;
        _hitTests = YES;

        _element = [[RTRenderer sharedRenderer] createViewElement:self];

        [self _setupViewFlags];
    }

    return self;
}

/*!
    Returns the container view of the receiver
    @return the receiver's containing view
*/
- (RTView)superview
{
    return _superview;
}

/*!
    Returns an array of all the views contained as direct children of the receiver
    @return an array of RTViews
*/
- (CPArray)subviews
{
    return [_subviews copy];
}

/*!
    Makes the argument a subview of the receiver.
    @param aSubview the RTView to make a subview
*/
- (void)addSubview:(RTView)aSubview
{
    if (aSubview)
        [self _insertSubview:aSubview atIndex:CPNotFound];
}

/* @ignore */
- (void)_insertSubview:(RTView)aSubview atIndex:(int)anIndex
{
    if (aSubview === self)
        [CPException raise:CPInvalidArgumentException reason:"can't add a view as a subview of itself"];

    // We will have to adjust the z-index of all views starting at this index.
    var count = _subviews.length;

    // If this is already one of our subviews, remove it.
    if (aSubview._superview == self)
    {
        var index = [_subviews indexOfObjectIdenticalTo:aSubview];

        // FIXME: should this be anIndex >= count? (last one)
        if (index === anIndex || index === count - 1 && anIndex === count)
            return;

        [_subviews removeObjectAtIndex:index];

        [[RTRenderer sharedRenderer] removeView:self];

        if (anIndex > index)
            --anIndex;

        //We've effectively made the subviews array shorter, so represent that.
        --count;
    }
    else
    {
        // Remove the view from its previous superview.
        [aSubview removeFromSuperview];

        // Notify the subview that it will be moving.
        [aSubview viewWillMoveToSuperview:self];

        // Set ourselves as the superview.
        aSubview._superview = self;
    }

    if (anIndex === CPNotFound || anIndex >= count)
    {
        _subviews.push(aSubview);

        [[RTRenderer sharedRenderer] appendView:aSubview];
    }
    else
    {
        _subviews.splice(anIndex, 0, aSubview);

        [[RTRenderer sharedRenderer] insertView:aSubview before:_subviews[anIndex + 1]];
    }

    //[aSubview setNextResponder:self];
    [aSubview viewDidMoveToSuperview];

    [self didAddSubview:aSubview];
}

/*!
    Called when the receiver has added \c aSubview to it's child views.
    @param aSubview the view that was added
*/
- (void)didAddSubview:(RTView)aSubview
{
}

/*!
    Removes the receiver from it's container view and window.
    Does nothing if there's no container view.
*/
- (void)removeFromSuperview
{
    if (!_superview)
        return;

    [_superview willRemoveSubview:self];
    [_superview._subviews removeObject:self];
    [[RTRenderer sharedRenderer] removeView:self];

    _superview = nil;

    if ([self respondsToSelector:@selector(removeAllAnimations)])
        [self removeAllAnimations];
}

/*!
    Remove all subviews from the receiver
*/
- (void)removeAllSubviews
{
    var subviews = [self subviews];

    for (var i = 0; i < [subviews count]; i++)
    {
        var view = [subviews objectAtIndex:i];
        [view removeFromSuperview];
    }
}

/*!
    Replaces the specified child view with another view
    @param aSubview the view to replace
    @param aView the replacement view
*/
- (void)replaceSubview:(RTView)aSubview with:(RTView)aView
{
    if (aSubview._superview != self)
        return;

    var index = [_subviews indexOfObjectIdenticalTo:aSubview];

    [aSubview removeFromSuperview];

    [self _insertSubview:aView atIndex:index];
}

- (void)setSubviews:(CPArray)newSubviews
{
    if (!newSubviews)
        [CPException raise:CPInvalidArgumentException reason:"newSubviews cannot be nil in -[RTView setSubviews:]"];

    // Trivial Case 0: Same array somehow
    if ([_subviews isEqual:newSubviews])
        return;

    // Trivial Case 1: No current subviews, simply add all new subviews.
    if ([_subviews count] === 0)
    {
        var index = 0,
            count = [newSubviews count];

        for (; index < count; ++index)
            [self addSubview:newSubviews[index]];

        return;
    }

    // Trivial Case 2: No new subviews, simply remove all current subviews.
    if ([newSubviews count] === 0)
    {
        var count = [_subviews count];

        while (count--)
            [_subviews[count] removeFromSuperview];

        return;
    }

    // Find out the views that were removed.
    var removedSubviews = [CPMutableSet setWithArray:_subviews];

    [removedSubviews removeObjectsInArray:newSubviews];
    [removedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // Find out which views need to be added.
    var addedSubviews = [CPMutableSet setWithArray:newSubviews];

    [addedSubviews removeObjectsInArray:_subviews];

    var addedSubview = nil,
        addedSubviewEnumerator = [addedSubviews objectEnumerator];

    while ((addedSubview = [addedSubviewEnumerator nextObject]) !== nil)
        [self addSubview:addedSubview];

    // If the order is fine, no need to reorder.
    if ([_subviews isEqual:newSubviews])
        return;

    _subviews = [newSubviews copy];

    var index = 0,
        count = [_subviews count];

    for (; index < count; ++index)
    {
        var subview = _subviews[index];

        [[RTRenderer sharedRenderer] removeView:subview];
        [[RTRenderer sharedRenderer] appendView:subview];
    }
}

/*!
    Returns \c YES if the receiver is, or is a descendant of, \c aView.
    @param aView the view to test for ancestry
*/
- (BOOL)isDescendantOf:(RTView)aView
{
    var view = self;

    do
    {
        if (view == aView)
            return YES;
    } while(view = [view superview])

    return NO;
}

/*!
    Called when the receiver's superview has changed.
*/
- (void)viewDidMoveToSuperview
{
    [self setNeedsDisplay:YES];
}

/*!
    Called when the receiver has been moved to a new CPWindow.
*/
- (void)viewDidMoveToWindow
{
}

/*!
    Called when the receiver is about to be moved to a new view.
    @param aView the view to which the receiver will be moved
*/
- (void)viewWillMoveToSuperview:(RTView)aView
{
}

/*!
    Called when the receiver is about to be remove one of its subviews.
    @param aView the view that will be removed
*/
- (void)willRemoveSubview:(RTView)aView
{
}

- (void)setTag:(CPInteger)aTag
{
    _tag = aTag;
}

- (CPInteger)tag
{
    return _tag;
}

- (RTView)viewWithTag:(CPInteger)aTag
{
    if ([self tag] == aTag)
        return self;

    var index = 0,
        count = _subviews.length;

    for (; index < count; ++index)
    {
        var view = [_subviews[index] viewWithTag:aTag];

        if (view)
            return view;
    }

    return nil;
}

/*!
    Sets the frame size of the receiver to the dimensions and origin of the provided rectangle in the coordinate system
    of the superview. The method also posts an RTViewFrameDidChangeNotification to the notification
    center if the receiver is configured to do so. If the frame is the same as the current frame, the method simply
    returns (and no notification is posted).
    @param aFrame the rectangle specifying the new origin and size  of the receiver
*/
- (void)setFrame:(CGRect)aFrame
{
    if (CGRectEqualToRect(_frame, aFrame))
        return;

    _inhibitFrameAndBoundsChangedNotifications = YES;

    [self setFrameOrigin:aFrame.origin];
    [self setFrameSize:aFrame.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsFrameChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewFrameDidChangeNotification object:self];
}

/*!
    Returns the receiver's frame.
    @return a copy of the receiver's frame
*/
- (CGRect)frame
{
    return CGRectMakeCopy(_frame);
}

- (CGPoint)frameOrigin
{
    return CGPointMakeCopy(_frame.origin);
}

- (CGSize)frameSize
{
    return CGSizeMakeCopy(_frame.size);
}

/*!
    Moves the center of the receiver's frame to the provided point. The point is defined in the superview's coordinate system.
    The method posts a RTViewFrameDidChangeNotification to the default notification center if the receiver
    is configured to do so. If the specified origin is the same as the frame's current origin, the method will
    simply return (and no notification will be posted).
    @param aPoint the new origin point
*/
- (void)setCenter:(CGPoint)aPoint
{
    [self setFrameOrigin:CGPointMake(aPoint.x - _frame.size.width / 2.0, aPoint.y - _frame.size.height / 2.0)];
}

/*!
    Returns the center of the receiver's frame to the provided point. The point is defined in the superview's coordinate system.
    @return CGPoint the center point of the receiver's frame
*/
- (CGPoint)center
{
    return CGPointMake(_frame.size.width / 2.0 + _frame.origin.x, _frame.size.height / 2.0 + _frame.origin.y);
}

/*!
    Sets the receiver's frame origin to the provided point. The point is defined in the superview's coordinate system.
    The method posts a RTViewFrameDidChangeNotification to the default notification center if the receiver
    is configured to do so. If the specified origin is the same as the frame's current origin, the method will
    simply return (and no notification will be posted).
    @param aPoint the new origin point
*/
- (void)setFrameOrigin:(CGPoint)aPoint
{
    var origin = _frame.origin;

    if (!aPoint || CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewFrameDidChangeNotification object:self];

    if (_superview && _superview._boundsTransform)
        var p = CGPointApplyAffineTransform(origin, _superview._boundsTransform);
    else
        var p = CGPointMakeCopy(origin);


    for (var i = 0; i < [[self subviews] count]; ++i)
    {
        var subview = [[self subviews] objectAtIndex:i];
        //[subview setNeedsDisplay];
        [subview setNeedsLayout];
    }

    [_element moveTo:p];
}

/*!
    Sets the receiver's frame size. If \c aSize is the same as the frame's current dimensions, this
    method simply returns. The method posts a RTViewFrameDidChangeNotification to the
    default notification center if the receiver is configured to do so.
    @param aSize the new size for the frame
*/
- (void)setFrameSize:(CGSize)aSize
{
    var size = _frame.size;

    if (!aSize || CGSizeEqualToSize(size, aSize))
        return;

    var oldSize = CGSizeMakeCopy(size);

    size.width = aSize.width;
    size.height = aSize.height;

    _bounds.size.width = aSize.width;
    _bounds.size.height = aSize.height;

    if (_autoresizesSubviews)
        [self resizeSubviewsWithOldSize:oldSize];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];

    [_element resizeTo:size];

    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewFrameDidChangeNotification object:self];
}

/*!
    Sets the receiver's bounds. The bounds define the size and location of the receiver inside it's frame. Posts a
    RTViewBoundsDidChangeNotification to the default notification center if the receiver is configured to do so.
    @param bounds the new bounds
*/
- (void)setBounds:(CGRect)bounds
{
    if (CGRectEqualToRect(_bounds, bounds))
        return;

    _inhibitFrameAndBoundsChangedNotifications = YES;

    [self setBoundsOrigin:bounds.origin];
    [self setBoundsSize:bounds.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewBoundsDidChangeNotification object:self];
}

/*!
    Returns the receiver's bounds. The bounds define the size
    and location of the receiver inside its frame.
*/
- (CGRect)bounds
{
    return CGRectMakeCopy(_bounds);
}

- (CGPoint)boundsOrigin
{
    return CGPointMakeCopy(_bounds.origin);
}

- (CGSize)boundsSize
{
    return CGSizeMakeCopy(_bounds.size);
}

/*!
    Sets the location of the receiver inside its frame. The method
    posts a RTViewBoundsDidChangeNotification to the
    default notification center if the receiver is configured to do so.
    @param aPoint the new location for the receiver
*/
- (void)setBoundsOrigin:(CGPoint)aPoint
{
    var origin = _bounds.origin;

    if (CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    if (origin.x != 0 || origin.y != 0)
    {
        _boundsTransform = CGAffineTransformMakeTranslation(-origin.x, -origin.y);
        _inverseBoundsTransform = CGAffineTransformInvert(_boundsTransform);
    }
    else
    {
        _boundsTransform = nil;
        _inverseBoundsTransform = nil;
    }

    var index = _subviews.length;

    while (index--)
    {
        var view = _subviews[index],
            origin = view._frame.origin;

        var p = CGPointApplyAffineTransform(origin, _boundsTransform);
        [_element moveTo:p];
    }

    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewBoundsDidChangeNotification object:self];
}

/*!
    Sets the receiver's size inside its frame. The method posts a
    RTViewBoundsDidChangeNotification to the default
    notification center if the receiver is configured to do so.
    @param aSize the new size for the receiver
*/
- (void)setBoundsSize:(CGSize)aSize
{
    var size = _bounds.size;

    if (CGSizeEqualToSize(size, aSize))
        return;

    var frameSize = _frame.size;

    if (!CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;

        origin.x /= size.width / frameSize.width;
        origin.y /= size.height / frameSize.height;
    }

    size.width = aSize.width;
    size.height = aSize.height;

    if (!CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;

        origin.x *= size.width / frameSize.width;
        origin.y *= size.height / frameSize.height;
    }

    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewBoundsDidChangeNotification object:self];
}

/*!
    Notifies subviews that the superview changed size.
    @param aSize the size of the old superview
*/
- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    var mask = [self autoresizingMask];

    if (mask == RTViewNotSizable)
        return;

    var frame = _superview._frame,
        newFrame = CGRectMakeCopy(_frame),
        dX = (CGRectGetWidth(frame) - aSize.width) /
            (((mask & RTViewMinXMargin) ? 1 : 0) + (mask & RTViewWidthSizable ? 1 : 0) + (mask & RTViewMaxXMargin ? 1 : 0)),
        dY = (CGRectGetHeight(frame) - aSize.height) /
            ((mask & RTViewMinYMargin ? 1 : 0) + (mask & RTViewHeightSizable ? 1 : 0) + (mask & RTViewMaxYMargin ? 1 : 0));

    if (mask & RTViewMinXMargin)
        newFrame.origin.x += dX;
    if (mask & RTViewWidthSizable)
        newFrame.size.width += dX;

    if (mask & RTViewMinYMargin)
        newFrame.origin.y += dY;
    if (mask & RTViewHeightSizable)
        newFrame.size.height += dY;

    [self setFrame:newFrame];
}

/*!
    Initiates \c -superviewSizeChanged: messages to subviews.
    @param aSize the size for the subviews
*/
- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var count = _subviews.length;

    while (count--)
        [_subviews[count] resizeWithOldSuperviewSize:aSize];
}

/*!
    Specifies whether the receiver view should automatically resize its
    subviews when its \c -setFrameSize: method receives a change.
    @param aFlag If \c YES, then subviews will automatically be resized
    when this view is resized. \c NO means the views will not
    be resized automatically.
*/
- (void)setAutoresizesSubviews:(BOOL)aFlag
{
    _autoresizesSubviews = !!aFlag;
}

/*!
    Reports whether the receiver automatically resizes its subviews when its frame size changes.
    @return \c YES means it resizes its subviews on a frame size change.
*/
- (BOOL)autoresizesSubviews
{
    return _autoresizesSubviews;
}

/*!
    Determines automatic resizing behavior.
    @param aMask a bit mask with options
*/
- (void)setAutoresizingMask:(unsigned)aMask
{
    _autoresizingMask = aMask;
}

/*!
    Returns the bit mask options for resizing behavior
*/
- (unsigned)autoresizingMask
{
    return _autoresizingMask;
}

/*!
    Sets whether the receiver should be hidden.
    @param aFlag \c YES makes the receiver hidden.
*/
- (void)setHidden:(BOOL)aFlag
{
    aFlag = !!aFlag;

    if (_isHidden === aFlag)
        return;

    _isHidden = aFlag;
    [_element hide:_isHidden];


    if (aFlag)
    {
        [self _notifyViewDidHide];
    }
    else
    {
        [self _notifyViewDidUnhide];
    }
}

- (void)_notifyViewDidHide
{
    [self viewDidHide];

    var count = [_subviews count];
    while (count--)
        [_subviews[count] _notifyViewDidHide];
}

- (void)_notifyViewDidUnhide
{
    [self viewDidUnhide];

    var count = [_subviews count];
    while (count--)
        [_subviews[count] _notifyViewDidUnhide];
}

/*!
    Returns \c YES if the receiver is hidden.
*/
- (BOOL)isHidden
{
    return _isHidden;
}

- (void)setClipsToBounds:(BOOL)shouldClip
{
    if (_clipsToBounds === shouldClip)
        return;

    _clipsToBounds = shouldClip;

    [_element clip:_clipsToBounds];
    CPLog("[Warning] should be tested with SVG & Canvas renderer...");
}

- (BOOL)clipsToBounds
{
    return _clipsToBounds;
}

/*!
    Sets the opacity of the receiver. The value must be in the range of 0.0 to 1.0, where 0.0 is
    completely transparent and 1.0 is completely opaque.
    @param anAlphaValue an alpha value ranging from 0.0 to 1.0.
*/
- (void)setAlphaValue:(float)anAlphaValue
{
    if (_opacity == anAlphaValue)
        return;

    _opacity = anAlphaValue;

    [_element setOpacity:_opacity];
}

/*!
    Returns the alpha value of the receiver. Ranges from 0.0 to
    1.0, where 0.0 is completely transparent and 1.0 is completely opaque.
*/
- (float)alphaValue
{
    return _opacity;
}

/*!
    Returns \c YES if the receiver is hidden, or one
    of it's ancestor views is hidden. \c NO, otherwise.
*/
- (BOOL)isHiddenOrHasHiddenAncestor
{
    var view = self;

    while (view && ![view isHidden])
        view = [view superview];

    return view !== nil;
}

/*!
    Returns YES if the view is not hidden, has no hidden ancestor and doesn't belong to a hidden window.
*/
- (BOOL)_isVisible
{
    return ![self isHiddenOrHasHiddenAncestor] && [[self window] isVisible];
}

/*!
    Called when the return value of isHiddenOrHasHiddenAncestor becomes YES,
    e.g. when this view becomes hidden due to a setHidden:YES message to
    itself or to one of its superviews.

    Note: in the current implementation, viewDidHide may be called multiple
    times if additional superviews are hidden, even if
    isHiddenOrHasHiddenAncestor was already YES.
*/
- (void)viewDidHide
{

}

/*!
    Called when the return value of isHiddenOrHasHiddenAncestor becomes NO,
    e.g. when this view stops being hidden due to a setHidden:NO message to
    itself or to one of its superviews.

    Note: in the current implementation, viewDidUnhide may be called multiple
    times if additional superviews are unhidden, even if
    isHiddenOrHasHiddenAncestor was already NO.
*/
- (void)viewDidUnhide
{

}

/*!
    Sets the background color of the receiver.
    @param aColor the new color for the receiver's background
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    if (_backgroundColor == aColor)
        return;

    if (aColor == [CPNull null])
        aColor = nil;

    _backgroundColor = aColor;

    [_element update];
}

/*!
    Returns the background color of the receiver
*/
- (CPColor)backgroundColor
{
    return _backgroundColor;
}

// Converting Coordinates
/*!
    Converts \c aPoint from the coordinate space of \c aView to the coordinate space of the receiver.
    @param aPoint the point to convert
    @param aView the view space to convert from
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint fromView:(RTView)aView
{
    return CGPointApplyAffineTransform(aPoint, _RTViewGetTransform(aView, self));
}

/*!
    Converts the point from the base coordinate system to the receiver’s coordinate system.
    @param aPoint A point specifying a location in the base coordinate system
    @return The point converted to the receiver’s base coordinate system
*/
- (CGPoint)convertPointFromBase:(CGPoint)aPoint
{
    return CGPointApplyAffineTransform(aPoint, _RTViewGetTransform(nil, self));
}

/*!
    Converts \c aPoint from the receiver's coordinate space to the coordinate space of \c aView.
    @param aPoint the point to convert
    @param aView the coordinate space to which the point will be converted
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint toView:(RTView)aView
{
    return CGPointApplyAffineTransform(aPoint, _RTViewGetTransform(self, aView));
}

/*!
    Converts the point from the receiver’s coordinate system to the base coordinate system.
    @param aPoint A point specifying a location in the coordinate system of the receiver
    @return The point converted to the base coordinate system
*/
- (CGPoint)convertPointToBase:(CGPoint)aPoint
{
    return CGPointApplyAffineTransform(aPoint, _RTViewGetTransform(self, nil));
}

/*!
    Convert's \c aSize from \c aView's coordinate space to the receiver's coordinate space.
    @param aSize the size to convert
    @param aView the coordinate space to convert from
    @return the converted size
*/
- (CGSize)convertSize:(CGSize)aSize fromView:(RTView)aView
{
    return CGSizeApplyAffineTransform(aSize, _RTViewGetTransform(aView, self));
}

/*!
    Convert's \c aSize from the receiver's coordinate space to \c aView's coordinate space.
    @param aSize the size to convert
    @param the coordinate space to which the size will be converted
    @return the converted size
*/
- (CGSize)convertSize:(CGSize)aSize toView:(RTView)aView
{
    return CGSizeApplyAffineTransform(aSize, _RTViewGetTransform(self, aView));
}

/*!
    Converts \c aRect from \c aView's coordinate space to the receiver's space.
    @param aRect the rectangle to convert
    @param aView the coordinate space from which to convert
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect fromView:(RTView)aView
{
    return CGRectApplyAffineTransform(aRect, _RTViewGetTransform(aView, self));
}

/*!
    Converts the rectangle from the base coordinate system to the receiver’s coordinate system.
    @param aRect A rectangle specifying a location in the base coordinate system
    @return The rectangle converted to the receiver’s base coordinate system
*/
- (CGRect)convertRectFromBase:(CGRect)aRect
{
    return CGRectApplyAffineTransform(aRect, _RTViewGetTransform(nil, self));
}

/*!
    Converts \c aRect from the receiver's coordinate space to \c aView's coordinate space.
    @param aRect the rectangle to convert
    @param aView the coordinate space to which the rectangle will be converted
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect toView:(RTView)aView
{
    return CGRectApplyAffineTransform(aRect, _RTViewGetTransform(self, aView));
}

/*!
    Converts the rectangle from the receiver’s coordinate system to the base coordinate system.
    @param aRect  A rectangle specifying a location in the coordinate system of the receiver
    @return The rectangle converted to the base coordinate system
*/
- (CGRect)convertRectToBase:(CGRect)aRect
{
    return CGRectApplyAffineTransform(aRect, _RTViewGetTransform(self, nil));
}

/*!
    Sets whether the receiver posts a RTViewFrameDidChangeNotification notification
    to the default notification center when its frame is changed. The default is \c NO.
    Methods that could cause a frame change notification are:
<pre>
setFrame:
setFrameSize:
setFrameOrigin:
</pre>
    @param shouldPostFrameChangedNotifications \c YES makes the receiver post
    notifications on frame changes (size or origin)
*/
- (void)setPostsFrameChangedNotifications:(BOOL)shouldPostFrameChangedNotifications
{
    shouldPostFrameChangedNotifications = !!shouldPostFrameChangedNotifications;

    if (_postsFrameChangedNotifications === shouldPostFrameChangedNotifications)
        return;

    _postsFrameChangedNotifications = shouldPostFrameChangedNotifications;

    if (_postsFrameChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewFrameDidChangeNotification object:self];
}

/*!
    Returns \c YES if the receiver posts a RTViewFrameDidChangeNotification if its frame is changed.
*/
- (BOOL)postsFrameChangedNotifications
{
    return _postsFrameChangedNotifications;
}

/*!
    Sets whether the receiver posts a RTViewBoundsDidChangeNotification notification
    to the default notification center when its bounds is changed. The default is \c NO.
    Methods that could cause a bounds change notification are:
<pre>
setBounds:
setBoundsSize:
setBoundsOrigin:
</pre>
    @param shouldPostBoundsChangedNotifications \c YES makes the receiver post
    notifications on bounds changes
*/
- (void)setPostsBoundsChangedNotifications:(BOOL)shouldPostBoundsChangedNotifications
{
    shouldPostBoundsChangedNotifications = !!shouldPostBoundsChangedNotifications;

    if (_postsBoundsChangedNotifications === shouldPostBoundsChangedNotifications)
        return;

    _postsBoundsChangedNotifications = shouldPostBoundsChangedNotifications;

    if (_postsBoundsChangedNotifications)
        [CachedNotificationCenter postNotificationName:RTViewBoundsDidChangeNotification object:self];
}

/*!
    Returns \c YES if the receiver posts a
    RTViewBoundsDidChangeNotification when its
    bounds is changed.
*/
- (BOOL)postsBoundsChangedNotifications
{
    return _postsBoundsChangedNotifications;
}

/*!
    Draws the receiver into \c aRect. This method should be overridden by subclasses.
    @param aRect the area that should be drawn into
*/
- (void)drawRect:(CPRect)aRect
{

}

// Displaying

/*!
    Marks the entire view as dirty, and needing a redraw.
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    if (aFlag)
        [self setNeedsDisplayInRect:[self bounds]];
}

/*!
    Marks the area denoted by \c aRect as dirty, and initiates a redraw on it.
    @param aRect the area that needs to be redrawn
*/
- (void)setNeedsDisplayInRect:(CPRect)aRect
{
    if (!(_viewClassFlags & RTViewHasCustomDrawRect))
        return;

    if (CGRectIsEmpty(aRect))
        return;

    if (_dirtyRect && !CGRectIsEmpty(_dirtyRect))
        _dirtyRect = CGRectUnion(aRect, _dirtyRect);
    else
        _dirtyRect = CGRectMakeCopy(aRect);

    [[RTRenderer sharedRenderer] addDisplayObject:self];
}

- (BOOL)needsDisplay
{
    return _dirtyRect && !CGRectIsEmpty(_dirtyRect);
}

/*!
    Displays the receiver and any of its subviews that need to be displayed.
*/
- (void)displayIfNeeded
{
    if ([self needsDisplay])
        [self displayRect:_dirtyRect];
}

/*!
    Draws the entire area of the receiver as defined by its \c -bounds.
*/
- (void)display
{
    [self displayRect:[self visibleRect]];
}

- (void)displayIfNeededInRect:(CGRect)aRect
{
    if ([self needsDisplay])
        [self displayRect:aRect];
}

/*!
    Draws the receiver into the area defined by \c aRect.
    @param aRect the area to be drawn
*/
- (void)displayRect:(CPRect)aRect
{
    [self viewWillDraw];

    [self displayRectIgnoringOpacity:aRect inContext:nil];

    _dirtyRect = NULL;
}

- (void)displayRectIgnoringOpacity:(CGRect)aRect inContext:(CPGraphicsContext)aGraphicsContext
{
    if ([self isHidden])
        return;

    [self drawRect:aRect];
}

- (void)viewWillDraw
{

}

- (void)setNeedsLayout
{
    if (!(_viewClassFlags & RTViewHasCustomLayoutSubviews))
        return;

    _needsLayout = YES;

    [[RTRenderer sharedRenderer] addLayoutObject:self];
}

- (void)layoutIfNeeded
{
    if (_needsLayout)
    {
        _needsLayout = NO;

        [self layoutSubviews];
    }
}

- (void)layoutSubviews
{
}

/*!
    Returns whether the receiver is completely opaque. By default, returns \c NO.
*/
- (BOOL)isOpaque
{
    return NO;
}

/*!
    Returns the rectangle of the receiver not clipped by its superview.
*/
- (CGRect)visibleRect
{
    if (!_superview)
        return _bounds;

    return CGRectIntersection([self convertRect:[_superview visibleRect] fromView:_superview], _bounds);
}

/*!
    Return yes if the receiver is in a live-resize operation.
*/
- (BOOL)inLiveResize
{
    return _inLiveResize;
}

/*!
    Not implemented.

    A view will be sent this message before a window begins a resize operation. The
    receiver might choose to simplify its drawing operations during a live resize
    for speed.

    Subclasses should call super.
*/
- (void)viewWillStartLiveResize
{
    _inLiveResize = YES;
}

/*!
    Not implemented.

    A view will be sent this message after a window finishes a resize operation. The
    receiver which simplified its drawing operations in viewWillStartLiveResize might
    stop doing so now. Note the view might no longer be in a window, so use
    [self setNeedsDisplay:YES] if a final non-simplified redraw is required.

    Subclasses should call super.
*/
- (void)viewDidEndLiveResize
{
    _inLiveResize = NO;
}

// Animations
+ (void)_fireAnimation:(CPTimer)aTimer
{
    var params = [aTimer userInfo];
    [RTView animateWithDuration:[params objectForKey:@"duration"]
                          delay:0
                        options:[params objectForKey:@"options"]
                     animations:[params objectForKey:@"animations"]
                     completion:[params objectForKey:@"completion"]
    ];
}

+ (void)animateWithDuration:(CPTimeInterval)aDuration
                      delay:(CPTimeInterval)aDelay
                    options:(RTViewAnimationOption)aOptions
                 animations:(block)anAnimationBlock
                 completion:(block)aCompletionBlock
{
    if (aDelay > 0)
    {
        var params = [CPDictionary dictionaryWithObjectsAndKeys:
            aDuration, "duration",
            aOptions, "options",
            anAnimationBlock, "animations",
            aCompletionBlock, "completion"];
        [CPTimer scheduledTimerWithTimeInterval:aDelay
                                         target:self
                                       selector:@selector(_fireAnimation:)
                                       userInfo:params
                                        repeats:NO];
        return;
    }

    var animator = [RTAnimator animatorWithDuration:aDuration
                                              delay:aDelay
                                            options:aOptions
                                         animations:anAnimationBlock
                                         completion:aCompletionBlock];
    [animator startAnimation];
}

- (void)removeAllAnimations
{
    [RTAnimator resetAnimationObject:self];
}

@end

var _RTViewFullScreenModeStateMake = function(aView)
{
    var superview = aView._superview;

    return { autoresizingMask:aView._autoresizingMask, frame:CGRectMakeCopy(aView._frame), index:(superview ? [superview._subviews indexOfObjectIdenticalTo:aView] : 0), superview:superview };
};

var _RTViewGetTransform = function(/*RTView*/ fromView, /*RTView */ toView)
{
    var transform = CGAffineTransformMakeIdentity(),
        sameWindow = YES,
        fromWindow = nil,
        toWindow = nil;

    if (fromView)
    {
        var view = fromView;

        // FIXME: This doesn't handle the case when the outside views are equal.
        // If we have a fromView, "climb up" the view tree until
        // we hit the root node or we hit the toLayer.
        while (view && view != toView)
        {
            var frame = view._frame;

            transform.tx += CGRectGetMinX(frame);
            transform.ty += CGRectGetMinY(frame);

            if (view._boundsTransform)
            {
                CGAffineTransformConcatTo(transform, view._boundsTransform, transform);
            }

            view = view._superview;
        }

        // If we hit toView, then we're done.
        if (view === toView)
            return transform;

        else if (fromView && toView)
        {
            fromWindow = [fromView window];
            toWindow = [toView window];

            if (fromWindow && toWindow && fromWindow !== toWindow)
            {
                sameWindow = NO;

                var frame = [fromWindow frame];

                transform.tx += CGRectGetMinX(frame);
                transform.ty += CGRectGetMinY(frame);
            }
        }
    }

    // FIXME: For now we can do things this way, but eventually we need to do them the "hard" way.
    var view = toView;

    while (view)
    {
        var frame = view._frame;

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);

        if (view._boundsTransform)
        {
            CGAffineTransformConcatTo(transform, view._inverseBoundsTransform, transform);
        }

        view = view._superview;
    }

    if (!sameWindow)
    {
        var frame = [toWindow frame];

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);
    }
/*    var views = [],
        view = toView;

    while (view)
    {
        views.push(view);
        view = view._superview;
    }

    var index = views.length;

    while (index--)
    {
        var frame = views[index]._frame;

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);
    }*/

    return transform;
};


