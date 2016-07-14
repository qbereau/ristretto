/*
 * RTLocationManager.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

RTLocationManagerAuthorizationStatusNotDetermined   = 0;
RTLocationManagerAuthorizationStatusRestricted      = 1;
RTLocationManagerAuthorizationStatusDenied          = 2;
RTLocationManagerAuthorizationStatusAuthorized      = 3;

RTLocationDistanceFilterNone                        = 0;

RTLocationManagerMonitoredRegions = nil;
RTLocationManagerAuthorizationCurrentStatus = 0;

@implementation RTLocationManager : CPObject
{
    id                                          _delegate;
    RTLocation                                  _location;
    RTHeading                                   _heading;
    RTLocationDistanceFilter                    _distanceFilter;
    BOOL                                        _isUpdatingLocation;
}

- (id)init
{
    if (window.navigator)
    {
        return [RTHTML5LocationManager new];
    }
    else if (CPBrowserIsOperatingSystem(CPHMP100) || CPBrowserIsOperatingSystem(CPHMP200))
    {
        return [RTHMPNMEALocationManager new];
    }
}

- (id)_init
{
    self = [super init];
    if (self)
    {
        RTLocationManagerMonitoredRegions = [CPSet set];

        _distanceFilter                                 = RTLocationDistanceFilterNone;
        RTLocationManagerAuthorizationCurrentStatus     = RTLocationManagerAuthorizationStatusNotDetermined;
    }
    return self;
}

+ (RTLocationManagerAuthorizationStatus)authorizationStatus
{
    return RTLocationManagerAuthorizationCurrentStatus;
}

+ (BOOL)locationServicesEnabled
{
    return NO;
}

+ (BOOL)significantLocationChangeMonitoringAvailable
{
    return NO;
}

+ (BOOL)headingAvailable
{
    return NO;
}

- (void)startMonitoringForRegion:(RTRegion)aRegion
{
    [self removeRegion:aRegion];

    [RTLocationManagerMonitoredRegions addObjectsFromArray:[CPArray arrayWithObject:aRegion]];

    [self startUpdatingLocation];

    if ([_delegate respondsToSelector:@selector(locationManager:didStartMonitoringForRegion:)])
        [_delegate locationManager:self didStartMonitoringForRegion:aRegion];
}

- (void)stopMonitoringForRegion:(RTRegion)aRegion
{
    [self removeRegion:aRegion];
}

- (void)removeRegion:(RTRegion)aRegion
{
    var regionEnumerator = [RTLocationManagerMonitoredRegions objectEnumerator],
        region = nil;

    while (region = [regionEnumerator nextObject])
    {
        if ([[region identifier] isEqualToString:[aRegion identifier]])
        {
            [RTLocationManagerMonitoredRegions removeObject:region];
            return;
        }
    }
}

- (CPSet)monitoredRegions
{
    return RTLocationManagerMonitoredRegions;
}

- (void)startUpdatingLocation
{
    _isUpdatingLocation = YES;
}

- (void)stopUpdatingLocation
{
    _isUpdatingLocation = NO;
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (id)delegate
{
    return _delegate;
}

- (RTLocation)location
{
    return _location;
}

- (RTHeading)heading
{
    return _heading;
}

- (void)processRegionsCheckForCurrentLocation
{
    // Check if inside regions
    var regionEnumerator = [RTLocationManagerMonitoredRegions objectEnumerator],
        region = nil;

    while (region = [regionEnumerator nextObject])
    {
        if ([region isCoordinateInside:[_location coordinate]] && !region._wasInsideLastLocation)
        {
            region._wasInsideLastLocation = YES;
            if ([_delegate respondsToSelector:@selector(locationManager:didEnterRegion:)])
                [_delegate locationManager:self didEnterRegion:region];
        }
        else if (region._wasInsideLastLocation && ![region isCoordinateInside:[_location coordinate]])
        {
            region._wasInsideLastLocation = NO;
            if ([_delegate respondsToSelector:@selector(locationManager:didExitRegion:)])
                [_delegate locationManager:self didExitRegion:region];
        }
    }
}

@end

function distanceBetweenCoordinates(coord1, coord2)
{
    var lat1 = coord1.latitude,
        lon1 = coord1.longitude,
        lat2 = coord2.latitude,
        lon2 = coord2.longitude,
        radlat1 = Math.PI * lat1 / 180,
        radlat2 = Math.PI * lat2 / 180,
        radlon1 = Math.PI * lon1 / 180,
        radlon2 = Math.PI * lon2 / 180,
        theta = lon1 - lon2,
        radtheta = Math.PI * theta / 180,
        dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);

    dist = Math.acos(dist);
    dist = dist * 180 / Math.PI;
    dist = dist * 60 * 1.1515 * 1.609344;

    // Convert to meters
    return dist * 1000;
}
