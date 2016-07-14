/*
 * RTCanvasTextElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTCanvasTextElement : RTCanvasElement
{

}

- (id)initWithView:(RTView)aView
{
    if (self = [super initWithView:aView])
    {

    }
    return self;
}

- (void)renderRect:(CGRect)aRect
{
    [super renderRect:aRect];

    if (![_view text])
        return;

    var ctx         = _canvas.getContext("2d");
    ctx.font        = [[_view font] cssString];
    ctx.fillStyle   = [[_view textColor] cssString];

    if ([_view shadowOffset] && [_view shadowColor])
    {
        ctx.shadowColor     = [[_view shadowColor] cssString];
        ctx.shadowOffsetX   = [_view shadowOffset].width;
        ctx.shadowOffsetY   = [_view shadowOffset].height;
    }

    var txtSize = [[_view text] sizeWithFont:[_view font]];

    if ([_view numberOfLines] === 1)
    {
        switch ([_view baselineAdjustment])
        {
            case RTBaselineAdjustmentNone:
                ctx.textBaseline = "top";
                break;
            case RTBaselineAdjustmentAlignCenters:
                ctx.textBaseline = "middle";
                break;
            case RTBaselineAdjustmentAlignBaselines:
                ctx.textBaseline = "alphabetic";
                break;
        }

        if ([_view adjustsFontSizeToFitWidth])
        {
            if (txtSize.width > [_view frameSize].width)
            {
                var fontSizeToFit = [[_view text] fontSizeToFit:[_view frameSize] withFont:[_view font] minSize:[_view minimumFontSize]],
                    newFont = [CPFont fontWithName:[[_view font] familyName] size:fontSizeToFit bold:[[_view font] isBold] italic:[[_view font] isItalic]];
                ctx.font = [newFont cssString];
            }
        }
    }

    var pos = CGPointMake(0, [_view frameSize].height / 2 - txtSize.height / 2);
    switch ([_view textAlignment])
    {
        case RTTextAlignmentLeft:
            ctx.textAlign   = "left";
            break;
        case RTTextAlignmentCenter:
            ctx.textAlign   = "center";
            pos = CGPointMake([_view frameSize].width / 2, pos.y);
            break;
        case RTTextAlignmentRight:
            ctx.textAlign   = "right";
            pos = CGPointMake([_view frameSize].width, pos.y);
            break;
    }

    CGContextShowTextAtPoint(ctx, [_view text], pos);
}

@end
