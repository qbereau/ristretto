function CGPointMake(x, y) { return { x:x, y:y }; }
function CGPointMakeZero() { return { x:0.0, y:0.0 }; }
function CGPointMakeCopy(aPoint) { return { x:aPoint.x, y:aPoint.y }; }
function CGPointCreateCopy(aPoint) { return { x:aPoint.x, y:aPoint.y }; }
function CGPointEqualToPoint(lhsPoint, rhsPoint) { return (lhsPoint.x == rhsPoint.x && lhsPoint.y == rhsPoint.y); }
function CGStringFromPoint(aPoint) { return ("{" + aPoint.x + ", " + aPoint.y + "}"); }
function CGSizeMake(width, height) { return { width:width, height:height }; }
function CGSizeMakeZero() { return { width:0.0, height:0.0 }; }
function CGSizeMakeCopy(aSize) { return { width:aSize.width, height:aSize.height }; }
function CGSizeCreateCopy(aSize) { return { width:aSize.width, height:aSize.height }; }
function CGSizeEqualToSize(lhsSize, rhsSize) { return (lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height); }
function CGStringFromSize(aSize) { return ("{" + aSize.width + ", " + aSize.height + "}"); }
function CGRectMake(x, y, width, height) { return { origin: { x:x, y:y }, size: { width:width, height:height } }; }
function CGRectMakeZero() { return { origin: { x:0.0, y:0.0 }, size: { width:0.0, height:0.0 } }; }
function CGRectMakeCopy(aRect) { return { origin: { x:aRect.origin.x, y:aRect.origin.y }, size: { width:aRect.size.width, height:aRect.size.height } }; }
function CGRectCreateCopy(aRect) { return { origin: { x:aRect.origin.x, y:aRect.origin.y }, size: { width:aRect.size.width, height:aRect.size.height } }; }
function CGRectEqualToRect(lhsRect, rhsRect) { return ((lhsRect.origin.x == rhsRect.origin.x && lhsRect.origin.y == rhsRect.origin.y) && (lhsRect.size.width == rhsRect.size.width && lhsRect.size.height == rhsRect.size.height)); }
function CGStringFromRect(aRect) { return ("{" + ("{" + aRect.origin.x + ", " + aRect.origin.y + "}") + ", " + ("{" + aRect.size.width + ", " + aRect.size.height + "}") + "}"); }
function CGRectOffset(aRect, dX, dY) { return { origin: { x:aRect.origin.x + dX, y:aRect.origin.y + dY }, size: { width:aRect.size.width, height:aRect.size.height } }; }
function CGRectInset(aRect, dX, dY) { return { origin: { x:aRect.origin.x + dX, y:aRect.origin.y + dY }, size: { width:aRect.size.width - 2 * dX, height:aRect.size.height - 2 * dY } }; }
function CGRectGetHeight(aRect) { return (aRect.size.height); }
function CGRectGetMaxX(aRect) { return (aRect.origin.x + aRect.size.width); }
function CGRectGetMaxY(aRect) { return (aRect.origin.y + aRect.size.height); }
function CGRectGetMidX(aRect) { return (aRect.origin.x + (aRect.size.width) / 2.0); }
function CGRectGetMidY(aRect) { return (aRect.origin.y + (aRect.size.height) / 2.0); }
function CGRectGetMinX(aRect) { return (aRect.origin.x); }
function CGRectGetMinY(aRect) { return (aRect.origin.y); }
function CGRectGetWidth(aRect) { return (aRect.size.width); }
function CGRectIsEmpty(aRect) { return (aRect.size.width <= 0.0 || aRect.size.height <= 0.0); }
function CGRectIsNull(aRect) { return (aRect.size.width <= 0.0 || aRect.size.height <= 0.0); }
function CGRectContainsPoint(aRect, aPoint) { return (aPoint.x >= (aRect.origin.x) && aPoint.y >= (aRect.origin.y) && aPoint.x < (aRect.origin.x + aRect.size.width) && aPoint.y < (aRect.origin.y + aRect.size.height)); }
function CGInsetMake(top, right, bottom, left) { return { top:(top), right:(right), bottom:(bottom), left:(left) }; }
function CGInsetMakeZero() { return { top:(0), right:(0), bottom:(0), left:(0) }; }
function CGInsetMakeCopy(anInset) { return { top:(anInset.top), right:(anInset.right), bottom:(anInset.bottom), left:(anInset.left) }; }
function CGInsetIsEmpty(anInset) { return ((anInset).top === 0 && (anInset).right === 0 && (anInset).bottom === 0 && (anInset).left === 0); }
function CGInsetEqualToInset(lhsInset, rhsInset) { return ((lhsInset).top === (rhsInset).top && (lhsInset).right === (rhsInset).right && (lhsInset).bottom === (rhsInset).bottom && (lhsInset).left === (rhsInset).left); }
CGMinXEdge = 0;
CGMinYEdge = 1;
CGMaxXEdge = 2;
CGMaxYEdge = 3;
CGRectNull = { origin: { x:Infinity, y:Infinity }, size: { width:0.0, height:0.0 } };
function CGRectDivide(inRect, slice, rem, amount, edge)
{
    slice.origin = { x:inRect.origin.x, y:inRect.origin.y };
    slice.size = { width:inRect.size.width, height:inRect.size.height };
    rem.origin = { x:inRect.origin.x, y:inRect.origin.y };
    rem.size = { width:inRect.size.width, height:inRect.size.height };
    switch (edge)
    {
        case CGMinXEdge:
            slice.size.width = amount;
            rem.origin.x += amount;
            rem.size.width -= amount;
            break;
        case CGMaxXEdge:
            slice.origin.x = (slice.origin.x + slice.size.width) - amount;
            slice.size.width = amount;
            rem.size.width -= amount;
            break;
        case CGMinYEdge:
            slice.size.height = amount;
            rem.origin.y += amount;
            rem.size.height -= amount;
            break;
        case CGMaxYEdge:
            slice.origin.y = (slice.origin.y + slice.size.height) - amount;
            slice.size.height = amount;
            rem.size.height -= amount;
    }
}
function CGRectContainsRect(lhsRect, rhsRect)
{
    var union = CGRectUnion(lhsRect, rhsRect);
    return ((union.origin.x == lhsRect.origin.x && union.origin.y == lhsRect.origin.y) && (union.size.width == lhsRect.size.width && union.size.height == lhsRect.size.height));
}
function CGRectIntersectsRect(lhsRect, rhsRect)
{
    var intersection = CGRectIntersection(lhsRect, rhsRect);
    return !(intersection.size.width <= 0.0 || intersection.size.height <= 0.0);
}
function CGRectIntegral(aRect)
{
    aRect = CGRectStandardize(aRect);
    var x = FLOOR((aRect.origin.x)),
        y = FLOOR((aRect.origin.y));
    aRect.size.width = CEIL((aRect.origin.x + aRect.size.width)) - x;
    aRect.size.height = CEIL((aRect.origin.y + aRect.size.height)) - y;
    aRect.origin.x = x;
    aRect.origin.y = y;
    return aRect;
}
function CGRectIntersection(lhsRect, rhsRect)
{
    var intersection = { origin: { x:MAX((lhsRect.origin.x), (rhsRect.origin.x)), y:MAX((lhsRect.origin.y), (rhsRect.origin.y)) }, size: { width:0, height:0 } };
    intersection.size.width = MIN((lhsRect.origin.x + lhsRect.size.width), (rhsRect.origin.x + rhsRect.size.width)) - (intersection.origin.x);
    intersection.size.height = MIN((lhsRect.origin.y + lhsRect.size.height), (rhsRect.origin.y + rhsRect.size.height)) - (intersection.origin.y);
    return (intersection.size.width <= 0.0 || intersection.size.height <= 0.0) ? { origin: { x:0.0, y:0.0 }, size: { width:0.0, height:0.0 } } : intersection;
}
function CGRectStandardize(aRect)
{
    var width = (aRect.size.width),
        height = (aRect.size.height),
        standardized = { origin: { x:aRect.origin.x, y:aRect.origin.y }, size: { width:aRect.size.width, height:aRect.size.height } };
    if (width < 0.0)
    {
        standardized.origin.x += width;
        standardized.size.width = -width;
    }
    if (height < 0.0)
    {
        standardized.origin.y += height;
        standardized.size.height = -height;
    }
    return standardized;
}
function CGRectUnion(lhsRect, rhsRect)
{
    var lhsRectIsNull = !lhsRect || lhsRect === CGRectNull,
        rhsRectIsNull = !rhsRect || rhsRect === CGRectNull;
    if (lhsRectIsNull)
        return rhsRectIsNull ? CGRectNull : rhsRect;
    if (rhsRectIsNull)
        return lhsRectIsNull ? CGRectNull : lhsRect;
    var minX = MIN((lhsRect.origin.x), (rhsRect.origin.x)),
        minY = MIN((lhsRect.origin.y), (rhsRect.origin.y)),
        maxX = MAX((lhsRect.origin.x + lhsRect.size.width), (rhsRect.origin.x + rhsRect.size.width)),
        maxY = MAX((lhsRect.origin.y + lhsRect.size.height), (rhsRect.origin.y + rhsRect.size.height));
    return { origin: { x:minX, y:minY }, size: { width:maxX - minX, height:maxY - minY } };
}
function CGPointFromString(aString)
{
    var comma = aString.indexOf(',');
    return { x:parseFloat(aString.substr(1, comma - 1)), y:parseFloat(aString.substring(comma + 1, aString.length)) };
}
function CGSizeFromString(aString)
{
    var comma = aString.indexOf(',');
    return { width:parseFloat(aString.substr(1, comma - 1)), height:parseFloat(aString.substring(comma + 1, aString.length)) };
}
function CGRectFromString(aString)
{
    var comma = aString.indexOf(',', aString.indexOf(',') + 1);
    return { origin:CGPointFromString(aString.substr(1, comma - 1)), size:CGSizeFromString(aString.substring(comma + 2, aString.length)) };
}
function CGPointFromEvent(anEvent)
{
    return { x:anEvent.clientX, y:anEvent.clientY };
}
function CGInsetUnion(lhsInset, rhsInset)
{
    return { top:(lhsInset.top + rhsInset.top), right:(lhsInset.right + rhsInset.right), bottom:(lhsInset.bottom + rhsInset.bottom), left:(lhsInset.left + rhsInset.left) };
}
function CGInsetDifference(lhsInset, rhsInset)
{
    return { top:(lhsInset.top - rhsInset.top), right:(lhsInset.right - rhsInset.right), bottom:(lhsInset.bottom - rhsInset.bottom), left:(lhsInset.left - rhsInset.left) };
}
function CGInsetFromString(aString)
{
    var numbers = aString.substr(1, aString.length - 2).split(',');
    return { top:(parseFloat(numbers[0])), right:(parseFloat(numbers[1])), bottom:(parseFloat(numbers[2])), left:(parseFloat(numbers[3])) };
}
CGInsetFromCPString = CGInsetFromString;
function CPStringFromCGInset(anInset)
{
    return '{' + anInset.top + ", " + anInset.left + ", " + anInset.bottom + ", " + anInset.right + '}';
}
