/*
 * RTRegion.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */


@implementation RTRegion : CPObject
{
    RTLocationCoordinate2D          _center;
    RTLocationDistance              _radius;
    CPArray                         _locations;
    CPString                        _identifier;
    BOOL                            _wasInsideLastLocation;
}

- (id)init
{
    self = [super init];
    if (self)
    {

    }
    return self;
}

// Radius is measured in meters in Cocoa
- (id)initCircularRegionWithCenter:(RTLocationCoordinate2D)center
                        radius:(RTLocationDistance)radius
                        identifier:(CPString)identifier
{
    self = [super init];
    if (self)
    {
        _wasInsideLastLocation  = NO;
        _center                 = center;
        _radius                 = radius;
        _identifier             = identifier;
    }
    return self;
}

- (id)initPolygonalRegionWithLocations:(CPArray)locations
                            identifier:(CPString)identifier
{
    self = [super init];
    if (self)
    {
        _locations  = locations;
        _identifier = identifier;
    }
    return self;
}

- (id)initPolygonalRegionWithJSObjects:(CPArray)locationObjects
                            identifier:(CPString)identifier
{
    self = [super init];
    if (self)
    {
        _locations = [CPMutableArray array];
        for (var i = 0; i < locationObjects.length; i++)
        {
            var obj = locationObjects[i],
                loc = [[RTLocation alloc] initWithLatitude:obj.latitude longitude:obj.longitude];

            [_locations addObject:loc];
        }

        _identifier = identifier;
    }
    return self;
}

- (RTLocationCoordinate2D)center
{
    return _center;
}

- (RTLocationDistance)radius
{
    return _radius;
}

- (CPArray)locations
{
    return _locations;
}

- (CPString)identifier
{
    return _identifier;
}

- (BOOL)isCoordinateInside:(RTLocationCoordinate2D)coord
{
    if (_center && _radius)
    {
        // Circle check
        var dist = distanceBetweenCoordinates(coord, _center);

        if (dist <= _radius)
            return YES;
        return NO;
    }
    else
    {
        // Polygon check (taken from here: http://pietschsoft.com/post/2008/07/Virtual-Earth-Polygon-Search-Is-Point-Within-Polygon.aspx)
        var isInPoly    = NO,
            i           = 0,
            j           = [_locations count] - 1,
            lat         = coord.latitude,
            lon         = coord.longitude;

        for (i = 0; i < [_locations count]; ++i)
        {
            if (_locations[i].longitude < lon && _locations[j].longitude >= lon ||  _locations[j].longitude < lon && _locations[i].longitude >= lon)
            {
                if (_locations[i].latitude + (lon - _locations[i].longitude) / (_locations[j].longitude - _locations[i].longitude) * (_locations[j].latitude - _locations[i].latitude) < lat)
                {
                    isInPoly =! isInPoly;
                }
            }
            j = i;
        }
        return isInPoly;
    }
}

@end
