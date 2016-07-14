/*
 * RTHMPNMEALocationManager.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTHMPNMEALocationManager : RTLocationManager
{
    SharedVariable      _nmeaGGA;
    SharedVariable      _nmeaVTG;
    UpdateListener      _ggaUpdateListener;
    UpdateListener      _vtgUpdateListener;
}

- (id)init
{
    self = [super _init];
    if (self)
    {
        RTLocationManagerAuthorizationCurrentStatus = RTLocationManagerAuthorizationStatusAuthorized;
        _ggaUpdateListener = function(data)
        {
            var lines = data.value.split('\n');
            if (lines.length > 0)
            {
                var data    = lines[1].split(','),
                    lat_d   = data[5],
                    lat_m   = data[6],
                    lat_ns  = data[7],
                    long_d  = data[8],
                    long_m  = data[9],
                    long_ew = data[10],
                    hAcc    = data[13],
                    alt     = data[14],
                    altUnit = data[15];

                // We have the data in Decimal Minutes style
                // We want to convert it to Decimal Degree
                if (lat_d.length > 0    &&
                    lat_m.length > 0    &&
                    lat_ns.length > 0   &&
                    long_d.length > 0   &&
                    long_m.length > 0   &&
                    long_ew.length > 0)
                {
                    var latD   = lat_m / 60,
                        latDD  = parseFloat(lat_d) + parseFloat(latD),
                        lngD   = long_m / 60,
                        lngDD  = parseFloat(long_d) + parseFloat(lngD);

                    if (lat_ns === 'S')
                        latDD *= -1.0;
                    if (long_ew === 'W')
                        lngDD *= -1.0;

                    var altitude = "";
                    if (altUnit === 'M' && alt.length > 0)
                        altitude = alt;


                    var oldLoc = _location;
                    _location = [[RTLocation alloc] initWithCoordinate:{latitude:latDD, longitude:lngDD}
                                                              altitude:altitude
                                                    horizontalAccuracy:hAcc
                                                      verticalAccuracy:nil
                                                                course:oldLoc ? [oldLoc course] : nil
                                                                 speed:oldLoc ? [oldLoc speed] : nil
                                                             timestamp:[CPDate date]
                                                             ];
                    //CPLog("New Location: " + latDD + " - " + lngDD);
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
                }
            }
        }

        _vtgUpdateListener = function(data)
        {
            var lines = data.value.split('\n');
            if (lines.length > 0)
            {
                var data            = lines[1].split(','),
                    trueHeading     = parseFloat(data[2]),
                    magneticHeading = parseFloat(data[4]),
                    speed           = parseFloat(data[8]);

                if (_location)
                {
                    _location._speed    = speed;
                    _location._course   = trueHeading;
                }

                _heading = [[RTHeading alloc] _init];
                _heading._trueHeading       = trueHeading;
                _heading._magneticHeading   = magneticHeading;
                _heading._timestamp         = [CPDate date];

                // Warning: Heading Filter is not taken into account
                if ([_delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
                    [_delegate locationManager:self didUpdateHeading:_heading];
            }
        }
    }
    return self;
}

+ (BOOL)locationServicesEnabled
{
    return YES;
}

+ (BOOL)significantLocationChangeMonitoringAvailable
{
    return NO;
}

+ (BOOL)headingAvailable
{
    return YES;
}

- (double)DM2D:(double)degree minutes:(double)minutes
{
    var out = degrees * 1.0 + (minutes / 60.0);
    return Math.round(out * 1000000.0) / 1000000.0;
}

- (void)startUpdatingLocation
{
    [super startUpdatingLocation];

    _nmeaGGA = createSharedVariable('gps_gga');
    _nmeaGGA.addUpdateListener(_ggaUpdateListener);

    _nmeaVTG = createSharedVariable('gps_vtg');
    _nmeaVTG.addUpdateListener(_vtgUpdateListener);
}

- (void)stopUpdatingLocation
{
    [super stopUpdatingLocation];

    _nmeaGGA.removeUpdateListener(_ggaUpdateListener);
    _nmeaVTG.removeUpdateListener(_vtgUpdateListener);
}

@end
