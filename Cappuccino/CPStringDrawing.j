/*
 * CPStringDrawing.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPString.j>

@import "../Renderer/Renderer.j"


var CPStringSizeWithFontInWidthCache = {};

CPStringSizeCachingEnabled = NO;

@implementation CPString (CPStringDrawing)

/*!
    Returns a dictionary with the items "ascender", "descender", "lineHeight"
*/
+ (CPDictionary)metricsOfFont:(CPFont)aFont
{
    //return [CPPlatformString metricsOfFont:aFont];
}

/*!
    Returns the string
*/
- (CPString)cssString
{
    return self;
}

- (CGSize)sizeWithFont:(CPFont)aFont
{
    return [self sizeWithFont:aFont inWidth:NULL];
}

- (CGSize)sizeWithFont:(CPFont)aFont inWidth:(float)aWidth
{
    if (!CPStringSizeCachingEnabled)
        return [[RTRenderer sharedRenderer] sizeOfString:self withFont:aFont forWidth:aWidth];

    var cacheKey = self + [aFont cssString],
        size = CPStringSizeWithFontInWidthCache[cacheKey];

    if (size === undefined)
    {
        size = [[RTRenderer sharedRenderer] sizeOfString:self withFont:aFont forWidth:aWidth];
        if (size.width != 0 && size.height != 0)
            CPStringSizeWithFontInWidthCache[cacheKey] = size;
    }

    return CGSizeMakeCopy(size);
}

- (int)fontSizeToFit:(CGSize)aSize withFont:(CPFont)aFont
{
    return [self fontSizeToFit:aSize withFont:aFont minSize:0];
}

- (int)fontSizeToFit:(CGSize)aSize withFont:(CPFont)aFont minSize:(float)aMinSize
{
    var font = aFont;
    if (!font)
        font = [CPFont systemFontOfSize:0];

    var fontSize = 0;
    while (YES)
    {
        var potentialFont = [CPFont fontWithName:[font familyName] size:++fontSize],
            computedFontSize = [self sizeWithFont:potentialFont inWidth:aSize.width];
        if (computedFontSize.height > aSize.height || (aSize.width > 0 && computedFontSize.width > aSize.width) || (aMinSize > 0 && computedFontSize >= aMinSize))
            return fontSize;
    }

    return -1;
}

@end
