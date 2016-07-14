/*
 * CPCompatibility.j
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

// Browser Engines
CPUnknownBrowserEngine                  = 0;
CPGeckoBrowserEngine                    = 1;
CPInternetExplorerBrowserEngine         = 2;
CPKHTMLBrowserEngine                    = 3;
CPOperaBrowserEngine                    = 4;
CPWebKitBrowserEngine                   = 5;

// Operating Systems
CPMacOperatingSystem                    = 0;
CPWindowsOperatingSystem                = 1;
CPOtherOperatingSystem                  = 2;
CPiOS                                   = 3;
CPHMP100                                = 4;
CPHMP200                                = 5;

// Browser
CPUnknownBrowser                        = 0;
CPIEBrowser                             = 1;
CPFirefoxBrowser                        = 2;
CPOperaBrowser                          = 3;
CPChromeBrowser                         = 4;
CPSafariBrowser                         = 5;

// Features
CPCSSRGBAFeature                        = 1 << 5;

CPHTMLCanvasFeature                     = 1 << 6;
CPHTMLContentEditableFeature            = 1 << 7;
CPHTMLDragAndDropFeature                = 1 << 8;

CPJavaScriptInnerTextFeature            = 1 << 9;
CPJavaScriptTextContentFeature          = 1 << 10;
CPJavaScriptClipboardEventsFeature      = 1 << 11;
CPJavaScriptClipboardAccessFeature      = 1 << 12;
CPJavaScriptCanvasDrawFeature           = 1 << 13;
CPJavaScriptCanvasTransformFeature      = 1 << 14;

CPVMLFeature                            = 1 << 15;

CPJavaScriptRemedialKeySupport          = 1 << 16;
CPJavaScriptShadowFeature               = 1 << 20;

CPJavaScriptNegativeMouseWheelValues    = 1 << 22;
CPJavaScriptMouseWheelValues_8_15       = 1 << 23;

CPOpacityRequiresFilterFeature          = 1 << 24;

//Internet explorer does not allow dynamically changing the type of an input element
CPInputTypeCanBeChangedFeature          = 1 << 25;
CPHTML5DragAndDropSourceYOffBy1         = 1 << 26;

CPSOPDisabledFromFileURLs               = 1 << 27;

CPHTMLCanvasDrawVideo                   = 1 << 28;

CPVideoSupportsMP4                      = 1 << 29;

CPGeolocationFeature                    = 1 << 30;

var USER_AGENT                          = "",
    PLATFORM_ENGINE                     = CPUnknownBrowserEngine,
    PLATFORM_FEATURES                   = 0,
    BROWSER                             = CPUnknownBrowser;

// default these features to true

PLATFORM_FEATURES |= CPInputTypeCanBeChangedFeature;

if (typeof window !== "undefined" && typeof window.navigator !== "undefined")
    USER_AGENT = window.navigator.userAgent;

// Opera
if (typeof window !== "undefined" && window.opera)
{
    PLATFORM_ENGINE = CPOperaBrowserEngine;

    BROWSER = CPOperaBrowser;

    PLATFORM_FEATURES |= CPJavaScriptCanvasDrawFeature;
    PLATFORM_FEATURES |= CPHTMLCanvasDrawVideo;
}

// Internet Explorer
else if (typeof window !== "undefined" && window.attachEvent) // Must follow Opera check.
{
    PLATFORM_ENGINE = CPInternetExplorerBrowserEngine;
    BROWSER = CPIEBrowser;

    // Features we can only be sure of with IE (no known independent tests)
    PLATFORM_FEATURES |= CPVMLFeature;
    PLATFORM_FEATURES |= CPJavaScriptRemedialKeySupport;
    PLATFORM_FEATURES |= CPJavaScriptShadowFeature;

    PLATFORM_FEATURES |= CPOpacityRequiresFilterFeature;

    PLATFORM_FEATURES &= ~CPInputTypeCanBeChangedFeature;

    PLATFORM_FEATURES |= CPHTMLCanvasDrawVideo;
}

// WebKit
else if (USER_AGENT.indexOf("AppleWebKit/") != -1)
{
    PLATFORM_ENGINE = CPWebKitBrowserEngine;

    // Features we can only be sure of with WebKit (no known independent tests)
    PLATFORM_FEATURES |= CPCSSRGBAFeature;
    PLATFORM_FEATURES |= CPHTMLContentEditableFeature;

    if (USER_AGENT.indexOf("Chrome") === -1)
        PLATFORM_FEATURES |= CPHTMLDragAndDropFeature;
    else
    {
        PLATFORM_FEATURES |= CPHTMLCanvasDrawVideo;
        BROWSER = CPChromeBrowser;
    }

    PLATFORM_FEATURES |= CPJavaScriptClipboardEventsFeature;
    PLATFORM_FEATURES |= CPJavaScriptClipboardAccessFeature;
    PLATFORM_FEATURES |= CPJavaScriptShadowFeature;

    var versionStart = USER_AGENT.indexOf("AppleWebKit/") + "AppleWebKit/".length,
        versionEnd = USER_AGENT.indexOf(" ", versionStart),
        versionString = USER_AGENT.substring(versionStart, versionEnd),
        versionDivision = versionString.indexOf('.'),
        majorVersion = parseInt(versionString.substring(0, versionDivision)),
        minorVersion = parseInt(versionString.substr(versionDivision + 1));

    if ((USER_AGENT.indexOf("Safari") !== CPNotFound && (majorVersion > 525 || (majorVersion === 525 && minorVersion > 14))) || USER_AGENT.indexOf("Chrome") !== CPNotFound)
        PLATFORM_FEATURES |= CPJavaScriptRemedialKeySupport;

    if (majorVersion < 532 || (majorVersion === 532 && minorVersion < 6))
        PLATFORM_FEATURES |= CPHTML5DragAndDropSourceYOffBy1;

    if (USER_AGENT.indexOf("Chrome") === CPNotFound)
    {
        PLATFORM_FEATURES |= CPSOPDisabledFromFileURLs;
        BROWSER = CPSafariBrowser;
    }
}

// KHTML
else if (USER_AGENT.indexOf("KHTML") != -1) // Must follow WebKit check.
{
    PLATFORM_ENGINE = CPKHTMLBrowserEngine;
}

// Gecko
else if (USER_AGENT.indexOf("Gecko") !== -1) // Must follow KHTML check.
{
    PLATFORM_ENGINE = CPGeckoBrowserEngine;

    PLATFORM_FEATURES |= CPJavaScriptCanvasDrawFeature;
    PLATFORM_FEATURES |= CPHTMLCanvasDrawVideo;

    if (USER_AGENT.indexOf("Firefox"))
        BROWSER = CPFirefoxBrowser;

    var index = USER_AGENT.indexOf("Firefox"),
        version = (index === -1) ? 2.0 : parseFloat(USER_AGENT.substring(index + "Firefox".length + 1));

    if (version >= 3.0)
        PLATFORM_FEATURES |= CPCSSRGBAFeature;

    if (version < 3.0)
        PLATFORM_FEATURES |= CPJavaScriptMouseWheelValues_8_15;
}

// Feature Specific Checks
if (typeof document != "undefined" && PLATFORM_ENGINE != CPUnknownBrowserEngine)
{
    var canvasElement = document.createElement("canvas");
    // Detect Canvas Support
    if (canvasElement && canvasElement.getContext)
    {
        PLATFORM_FEATURES |= CPHTMLCanvasFeature;

        // Detect Canvas setTransform/transform support
        var context = document.createElement("canvas").getContext("2d");

        if (context && context.setTransform && context.transform)
            PLATFORM_FEATURES |= CPJavaScriptCanvasTransformFeature;
    }

    if (navigator.geolocation)
        PLATFORM_FEATURES  |= CPGeolocationFeature;

    var DOMElement = document.createElement("div");

    // Detect whether we have innerText or textContent (or neither)
    if (DOMElement.innerText != undefined)
        PLATFORM_FEATURES |= CPJavaScriptInnerTextFeature;
    else if (DOMElement.textContent != undefined)
        PLATFORM_FEATURES |= CPJavaScriptTextContentFeature;
}

function CPFeatureIsCompatible(aFeature)
{
    return PLATFORM_FEATURES & aFeature;
}

function CPBrowserIsEngine(anEngine)
{
    return PLATFORM_ENGINE === anEngine;
}

function CPBrowserIs(aBrowser)
{
    return BROWSER === aBrowser;
}

function CPBrowserIsOperatingSystem(anOperatingSystem)
{
    return OPERATING_SYSTEM === anOperatingSystem;
}

OPERATING_SYSTEM = CPOtherOperatingSystem;

if (USER_AGENT.indexOf("iPhone") !== -1 || USER_AGENT.indexOf("iPad") !== -1)
{
    OPERATING_SYSTEM = CPiOS;
}
else if (USER_AGENT.indexOf("Mac") !== -1)
{
    OPERATING_SYSTEM = CPMacOperatingSystem;
}
else if (USER_AGENT.indexOf("Windows") !== -1)
{
    OPERATING_SYSTEM = CPWindowsOperatingSystem;
}
else if (typeof OBJJ_HMP_PLATFORM != 'undefined' && OBJJ_HMP_PLATFORM === 100)
{
    OPERATING_SYSTEM    = CPHMP100;
    PLATFORM_FEATURES  |= CPVideoSupportsMP4;
    PLATFORM_FEATURES  |= CPGeolocationFeature;
}
else if (typeof OBJJ_HMP_PLATFORM != 'undefined' && OBJJ_HMP_PLATFORM === 200)
{
    OPERATING_SYSTEM    = CPHMP200;
    PLATFORM_FEATURES  |= CPGeolocationFeature;
}
