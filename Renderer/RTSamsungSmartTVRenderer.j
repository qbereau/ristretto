/*
 * RTSamsungSmartTVRenderer.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTSamsungSmartTVRenderer : RTCanvasRenderer
{

}

- (id)init
{
    if (self = [super _init])
    {

    }
    return self;
}

- (RTElement)createVideoElement:(RTView)aView
{
    return [[RTSamsungSmartTVVideoElement alloc] initWithView:aView];
}

@end
