@import "CGColor.j"
@import "CGColorSpace.j"
kCGGradientDrawsBeforeStartLocation = 1 << 0;
kCGGradientDrawsAfterEndLocation = 1 << 1;
function CGGradientCreateWithColorComponents(aColorSpace, components, locations, count)
{
    if (locations === undefined || locations === NULL)
    {
        var num_of_colors = components.length / 4,
            locations = [];
        for (var idx = 0; idx < num_of_colors; idx++)
            locations.push( idx / (num_of_colors - 1) );
    }
    if (count === undefined || count === NULL)
        count = locations.length;
    var colors = [];
    while (count--)
    {
        var offset = count * 4;
        colors[count] = CGColorCreate(aColorSpace, components.slice(offset, offset + 4));
    }
    return CGGradientCreateWithColors(aColorSpace, colors, locations);
}
function CGGradientCreateWithColors(aColorSpace, colors, locations)
{
    return { colorspace:aColorSpace, colors:colors, locations:locations };
}
function CGGradientRelease()
{
}
function CGGradientRetain(aGradient)
{
    return aGradient;
}
