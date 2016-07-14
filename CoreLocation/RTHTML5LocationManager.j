/*
 * RTHTML5LocationManager.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

var locObj = nil;

@implementation RTHTML5LocationManager : RTLocationManager
{
    int             _watchID;
}

- (id)init
{
    if (CPFeatureIsCompatible(CPGeolocationFeature))
    {
        self = [super _init];
        if (self)
        {

        }
        return self;
    }
    return nil;
}

+ (BOOL)locationServicesEnabled
{
    return RTLocationManagerAuthorizationCurrentStatus === RTLocationManagerAuthorizationStatusAuthorized;
}

+ (BOOL)significantLocationChangeMonitoringAvailable
{
    return NO;
}

+ (BOOL)headingAvailable
{
    return locObj ? locObj.course : NO;
}

- (void)_receivedNewLocation:(JSObject)locationObject
{
    locObj = locationObject.coords;
    _location = [[RTLocation alloc] initWithCoordinate:{latitude:locObj.latitude, longitude:locObj.longitude}
                                              altitude:locObj.altitude
                                    horizontalAccuracy:locObj.accuracy
                                      verticalAccuracy:locObj.altitudeAccuracy
                                                course:locObj.heading
                                                 speed:locObj.speed
                                             timestamp:[CPDate dateWithTimeIntervalSince1970:locationObject.timestamp] ];
}

- (void)startUpdatingLocation
{
    [super startUpdatingLocation];

    if (RTLocationManagerAuthorizationCurrentStatus !== RTLocationManagerAuthorizationStatusAuthorized && RTLocationManagerAuthorizationCurrentStatus !== RTLocationManagerAuthorizationStatusNotDetermined)
    {
        _isUpdatingLocation = NO;

        if ([_delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
            [_delegate locationManager:self didFailWithError:RTLocationManagerAuthorizationCurrentStatus];

        return;
    }

    navigator.geolocation.getCurrentPosition(
        function(location)
        {
            RTLocationManagerAuthorizationCurrentStatus = RTLocationManagerAuthorizationStatusAuthorized;
            if ([_delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)])
                [_delegate locationManager:self didChangeAuthorizationStatus:RTLocationManagerAuthorizationCurrentStatus];

            _watchID =  navigator.geolocation.watchPosition(
                function(location)
                {
                    var oldLoc = _location;
                    [self _receivedNewLocation:location];

                    var distance = 0;
                    if (oldLoc)
                    {
                        distance = distanceBetweenCoordinates([_location coordinate], [oldLoc coordinate]);
                    }

                    if (!oldLoc || _distanceFilter == RTLocationDistanceFilterNone || _distanceFilter >= distance)
                    {
                        if ([_delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
                            [_delegate locationManager:self didUpdateToLocation:_location fromLocation:oldLoc];
                    }

                    [self processRegionsCheckForCurrentLocation];
                },
                function(error)
                {
                    switch (error.code)
                    {
                        case error.PERMISSION_DENIED:
                            RTLocationManagerAuthorizationCurrentStatus = RTLocationManagerAuthorizationStatusDenied;
                            if ([_delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)])
                                [_delegate locationManager:self didChangeAuthorizationStatus:RTLocationManagerAuthorizationCurrentStatus];
                          break;
                    }

                    if ([_delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
                        [_delegate locationManager:self didFailWithError:error];
                },
                {
                    'enableHighAccuracy':true,
                    'timeout':10000,
                    'maximumAge':20000
                });
        },
        function(error)
        {
            switch (error.code)
            {
                case error.PERMISSION_DENIED:
                    RTLocationManagerAuthorizationCurrentStatus = RTLocationManagerAuthorizationStatusDenied;
                    if ([_delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)])
                        [_delegate locationManager:self didChangeAuthorizationStatus:RTLocationManagerAuthorizationCurrentStatus];
                  break;
            }

            if ([_delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
                [_delegate locationManager:self didFailWithError:error];
        });
}

- (void)stopUpdatingLocation
{
    [super stopUpdatingLocation];

    navigator.geolocation.clearWatch(_watchID);
}

@end
