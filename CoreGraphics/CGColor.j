@import "CGColorSpace.j"
var CFTypeGlobalCount = 0;
function CFHashCode(aCFObject)
{
    if (!aCFObject.hash)
        aCFObject.hash = ++CFTypeGlobalCount;
    return aCFObject;
}
kCGColorWhite = "kCGColorWhite";
kCGColorBlack = "kCGColorBlack";
kCGColorClear = "kCGColorClear";
var _CGColorMap = { };
function CGColorGetConstantColor(aColorName)
{
    alert("FIX ME");
}
function CGColorRetain(aColor)
{
    return aColor;
}
function CGColorRelease()
{
}
function CGColorCreate(aColorSpace, components)
{
    if (!aColorSpace || !components)
        return NULL;
    var components = components.slice();
    CGColorSpaceStandardizeComponents(aColorSpace, components);
    var UID = CFHashCode(aColorSpace) + components.join("");
    if (_CGColorMap[UID])
        return _CGColorMap[UID];
    return _CGColorMap[UID] = { colorspace:aColorSpace, pattern:NULL, components:components };
}
function CGColorCreateCopy(aColor)
{
    return aColor;
}
function CGColorCreateGenericGray(gray, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceRGB(), [gray, gray, gray, alpha]);
}
function CGColorCreateGenericRGB(red, green, blue, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceRGB(), [red, green, blue, alpha]);
}
function CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceCMYK(),
                         [cyan, magenta, yellow, black, alpha]);
}
function CGColorCreateCopyWithAlpha(aColor, anAlpha)
{
    if (!aColor)
        return aColor;
    var components = aColor.components.slice();
    if (anAlpha == components[components.length - 1])
        return aColor;
    components[components.length - 1] = anAlpha;
    if (aColor.pattern)
        return CGColorCreateWithPattern(aColor.colorspace, aColor.pattern, components);
    else
        return CGColorCreate(aColor.colorspace, components);
}
function CGColorCreateWithPattern(aColorSpace, aPattern, components)
{
    if (!aColorSpace || !aPattern || !components)
        return NULL;
    return { colorspace:aColorSpace, pattern:aPattern, components:components.slice() };
}
function CGColorEqualToColor(lhs, rhs)
{
    if (lhs == rhs)
        return true;
    if (!lhs || !rhs)
        return false;
    var lhsComponents = lhs.components,
        rhsComponents = rhs.components,
        lhsComponentCount = lhsComponents.length;
    if (lhsComponentCount != rhsComponents.length)
        return false;
    while (lhsComponentCount--)
        if (lhsComponents[lhsComponentCount] != rhsComponents[lhsComponentCount])
            return false;
    if (lhs.pattern != rhs.pattern)
        return false;
    if (CGColorSpaceEqualToColorSpace(lhs.colorspace, rhs.colorspace))
        return false;
    return true;
}
function CGColorGetAlpha(aColor)
{
    var components = aColor.components;
    return components[components.length - 1];
}
function CGColorGetColorSpace(aColor)
{
    return aColor.colorspace;
}
function CGColorGetComponents(aColor)
{
    return aColor.components;
}
function CGColorGetNumberOfComponents(aColor)
{
    return aColor.components.length;
}
function CGColorGetPattern(aColor)
{
    return aColor.pattern;
}
