/*
 * RTScreen.j - Ported from Cappuccino's CPScreen
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation RTScreen : CPObject
{

}

/*!
    @return the size of the browser's window
*/
+ (CGSize)browserSize
{
    var myWidth,
        myHeight;

    if (typeof( window.innerWidth ) == 'number')
    {
        //Non-IE
        myWidth = window.innerWidth;
        myHeight = window.innerHeight;

    }
    else if (document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ))
    {
        //IE 6+ in 'standards compliant mode'
        myWidth = document.documentElement.clientWidth;
        myHeight = document.documentElement.clientHeight;
    }
    else if (document.body && ( document.body.clientWidth || document.body.clientHeight ))
    {
        //IE 4 compatible
        myWidth = document.body.clientWidth;
        myHeight = document.body.clientHeight;
    }

    return CGSizeMake(myWidth, myHeight);
}

/*!
    Returns the position and size of the visible area of the receiving screen.
    This will normally be smaller than the full size of the screen to account
    for system UI elements. For example, on a Mac the top of the visible frame
    is placed below the bottom of the menu bar.

    @return the visible screen rectangle
*/
- (CGRect)visibleFrame
{
    if (window.screen)
        return CGRectMake(window.screen.availLeft, window.screen.availTop, window.screen.availWidth, window.screen.availHeight);
    else
        return CGRectMakeZero();
}

@end
