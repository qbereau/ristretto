/*
 * RTLocation.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */


@implementation RTLocation : CPObject
{
    float       _latitude;
    float       _longitude;
    float       _altitude;
    float       _horizontalAccuracy;
    float       _verticalAccuracy;
    CPDate      _timestamp;
    float       _speed;
    float       _course;
}

- (id)initWithLatitude:(RTLocationDegrees)lat
             longitude:(RTLocationDegrees)lng
{
    self = [super init];
    if (self)
    {
        _latitude   = lat;
        _longitude  = lng;
    }
    return self;
}

- (id)initWithCoordinate:(RTLocationCoordinate2D)coordinate
                altitude:(RTLocationDistance)altitude
      horizontalAccuracy:(RTLocationAccuracy)hAccuracy
        verticalAccuracy:(RTLocationAccuracy)vAccuracy
               timestamp:(CPDate)timestamp
{
    self = [super init];
    if (self)
    {
        _latitude           = coordinate.latitude;
        _longitude          = coordinate.longitude;
        _altitude           = altitude;
        _horizontalAccuracy = hAccuracy;
        _verticalAccuracy   = vAccuracy;
        _timestamp          = timestamp;
    }
    return self;
}

- (id)initWithCoordinate:(RTLocationCoordinate2D)coordinate
                altitude:(RTLocationDistance)altitude
      horizontalAccuracy:(RTLocationAccuracy)hAccuracy
        verticalAccuracy:(RTLocationAccuracy)vAccuracy
                  course:(RTLocationDirection)course
                   speed:(RTLocationSpeed)speed
               timestamp:(CPDate)timestamp
{
    self =  [self initWithCoordinate:coordinate
                            altitude:altitude
                  horizontalAccuracy:hAccuracy
                    verticalAccuracy:vAccuracy
                           timestamp:timestamp];
    if (self)
    {
        _speed  = speed;
        _course = course;
    }
    return self;
}

- (RTLocationCoordinate2D)coordinate
{
    return {latitude:_latitude, longitude:_longitude};
}

- (RTLocationDistance)altitude
{
    return _altitude;
}

- (RTLocationAccuracy)horizontalAccuracy
{
    return _horizontalAccuracy;
}

- (RTLocationAccuracy)verticalAccuracy
{
    return _verticalAccuracy;
}

- (CPDate)timestamp
{
    return _timestamp;
}

- (RTLocationSpeed)speed
{
    return _speed;
}

- (RTLocationDirection)course
{
    return _course;
}

- (CPString)description
{
    return _latitude + ", " + _longitude + " - " + _altitude + " - " + _horizontalAccuracy + " - " + _verticalAccuracy + " - " + _speed + " - " + _course + " - " + [_timestamp description];
}

@end
