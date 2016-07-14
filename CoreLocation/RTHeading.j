/*
 * RTHeading.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */


@implementation RTHeading : CPObject
{
    float       _magneticHeading;
    float       _trueHeading;
    float       _headingAccuracy;
    CPDate      _timestamp;
}

- (id)init
{
    [CPException raise:CPUnsupportedMethodException reason:"Can't init this class."];
    return nil;
}

- (id)_init
{
    self = [super init];
    if (self)
    {

    }
    return self;
}

- (RTLocationDirection)magneticHeading
{
    return _magneticHeading;
}

- (RTLocationDirection)trueHeading
{
    return _trueHeading;
}

- (CLLocationDirection)headingAccuracy
{
    return _headingAccuracy;
}

- (CPDate)timestamp
{
    return _timestamp;
}

- (CPString)description
{
    return _magneticHeading + " - " + _trueHeading + " - " + _headingAccuracy + " - " + [_timestamp description];
}

@end
