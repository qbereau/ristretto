kCGColorSpaceModelUnknown = -1;
kCGColorSpaceModelMonochrome = 0;
kCGColorSpaceModelRGB = 1;
kCGColorSpaceModelCMYK = 2;
kCGColorSpaceModelLab = 3;
kCGColorSpaceModelDeviceN = 4;
kCGColorSpaceModelIndexed = 5;
kCGColorSpaceModelPattern = 6;
kCGColorSpaceGenericGray = "CGColorSpaceGenericGray";
kCGColorSpaceGenericRGB = "CGColorSpaceGenericRGB";
kCGColorSpaceGenericCMYK = "CGColorSpaceGenericCMYK";
kCGColorSpaceGenericRGBLinear = "CGColorSpaceGenericRGBLinear";
kCGColorSpaceGenericRGBHDR = "CGColorSpaceGenericRGBHDR";
kCGColorSpaceAdobeRGB1998 = "CGColorSpaceAdobeRGB1998";
kCGColorSpaceSRGB = "CGColorSpaceSRGB";
var _CGNamedColorSpaces = {};
function CGColorSpaceCreateCalibratedGray(aWhitePoint, aBlackPoint, gamma)
{
    return { model:kCGColorSpaceModelMonochrome, count:1, base:NULL };
}
function CGColorSpaceCreateCalibratedRGB(aWhitePoint, aBlackPoint, gamma)
{
    return { model:kCGColorSpaceModelRGB, count:1, base:NULL };
}
function CGColorSpaceCreateICCBased(aComponentCount, range, profile, alternate)
{
    return NULL;
}
function CGColorSpaceCreateLab(aWhitePoint, aBlackPoint, aRange)
{
    return NULL;
}
function CGColorSpaceCreateDeviceCMYK()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
}
function CGColorSpaceCreateDeviceGray()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
}
function CGColorSpaceCreateDeviceRGB()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
}
function CGColorSpaceCreateWithPlatformColorSpace()
{
    return NULL;
}
function CGColorSpaceCreateIndexed(aBaseColorSpace, lastIndex, colorTable)
{
    return NULL;
}
function CGColorSpaceCreatePattern(aBaseColorSpace)
{
    if (aBaseColorSpace)
        return { model:kCGColorSpaceModelPattern, count:aBaseColorSpace.count, base:aBaseColorSpace };
    return { model:kCGColorSpaceModelPattern, count:0, base:NULL };
}
function CGColorSpaceCreateWithName(aName)
{
    var colorSpace = _CGNamedColorSpaces[aName];
    if (colorSpace)
        return colorSpace;
    switch (aName)
    {
        case kCGColorSpaceGenericGray: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelMonochrome, count:1, base:NULL };
        case kCGColorSpaceGenericRGB: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelRGB, count:3, base:NULL };
        case kCGColorSpaceGenericCMYK: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelCMYK, count:4, base:NULL };
        case kCGColorSpaceGenericRGBLinear: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelRGB, count:3, base:NULL };
        case kCGColorSpaceGenericRGBHDR: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelRGB, count:3, base:NULL };
        case kCGColorSpaceAdobeRGB1998: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelRGB, count:3, base:NULL };
        case kCGColorSpaceSRGB: return _CGNamedColorSpaces[aName] = { model:kCGColorSpaceModelRGB, count:3, base:NULL };
    }
    return NULL;
}
function CGColorSpaceCopyICCProfile(aColorSpace)
{
    return NULL;
}
function CGColorSpaceGetNumberOfComponents(aColorSpace)
{
    return aColorSpace.count;
}
function CGColorSpaceGetTypeID(aColorSpace)
{
}
function CGColorSpaceGetModel(aColorSpace)
{
    return aColorSpace.model;
}
function CGColorSpaceGetBaseColorSpace(aColorSpace)
{
}
function CGColorSpaceGetColorTableCount(aColorSpace)
{
}
function CGColorSpaceGetColorTable(aColorSpace)
{
}
function CGColorSpaceRelease(aColorSpace)
{
}
function CGColorSpaceRetain(aColorSpace)
{
    return aColorSpace;
}
function CGColorSpaceStandardizeComponents(aColorSpace, components)
{
    var count = aColorSpace.count;
    { if (count > components.length) { components[count] = 1; return; } var component = components[count]; if (component < 0) components[count] = 0; else if (component > 1) components[count] = 1; else components[count] = ROUND(component * 1000) / 1000; };
    if (aColorSpace.base)
        aColorSpace = aColorSpace.base;
    switch (aColorSpace.model)
    {
        case kCGColorSpaceModelMonochrome:
        case kCGColorSpaceModelRGB:
        case kCGColorSpaceModelCMYK:
        case kCGColorSpaceModelDeviceN: while (count--)
                                                { if (count > components.length) { components[count] = 1; return; } var component = components[count]; if (component < 0) components[count] = 0; else if (component > 1) components[count] = 1; else components[count] = ROUND(component * 255) / 255; };
                                            break;
        case kCGColorSpaceModelIndexed:
        case kCGColorSpaceModelLab:
        case kCGColorSpaceModelPattern: break;
    }
}
