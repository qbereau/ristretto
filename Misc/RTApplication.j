/*
 * RTApplication.j - Ported from Cappuccino's CPApplication
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPBundle.j>
@import "../Cappuccino/CPResponder.j"
@import "../Renderer/Renderer.j"
@import "../Views/RTView.j"

RTApp = nil;

RTApplicationWillFinishLaunchingNotification    = @"RTApplicationWillFinishLaunchingNotification";
RTApplicationDidFinishLaunchingNotification     = @"RTApplicationDidFinishLaunchingNotification";

@implementation RTApplication : CPResponder
{
    RTView                  _rootView;

    id                      _delegate;
    BOOL                    _finishedLaunching;

    CPDictionary            _namedArgs;
    CPArray                 _args;
    CPString                _fullArgsString;
}

+ (RTApplication)sharedApplication
{
    if (!RTApp)
        RTApp = [[RTApplication alloc] init];

    return RTApp;
}

- (id)init
{
    if (self = [super init])
    {
        RTApp = self;

        // Force Renderer
        //[[RTRenderer alloc] initWithSVGRenderer];

        _rootView = [[RTView alloc] initWithFrame:CGRectMake(0, 0, window.innerWidth, window.innerHeight)];
        [_rootView setBackgroundColor:[CPColor whiteColor]];
        [[RTRenderer sharedRenderer] appendView:_rootView];

        if (window.navigator)
        {
            window.onresize = function()
            {
                [_rootView setFrameSize:CGSizeMake(window.innerWidth, window.innerHeight)];
            }
        }

    }
    return self;
}

/*!
    Sets the delegate for this application. The delegate will receive various notifications
    caused by user interactions during the application's run. The delegate can choose to
    react to these events.
    @param aDelegate the delegate object
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter],
        delegateNotifications =
        [
            RTApplicationWillFinishLaunchingNotification, @selector(applicationWillFinishLaunching:),
            RTApplicationDidFinishLaunchingNotification, @selector(applicationDidFinishLaunching:),
        ],
        count = [delegateNotifications count];

    if (_delegate)
    {
        var index = 0;

        for (; index < count; index += 2)
        {
            var notificationName = delegateNotifications[index],
                selector = delegateNotifications[index + 1];

            if ([_delegate respondsToSelector:selector])
                [defaultCenter removeObserver:_delegate name:notificationName object:self];
        }
    }

    _delegate = aDelegate;

    var index = 0;

    for (; index < count; index += 2)
    {
        var notificationName = delegateNotifications[index],
            selector = delegateNotifications[index + 1];

        if ([_delegate respondsToSelector:selector])
            [defaultCenter addObserver:_delegate selector:selector name:notificationName object:self];
    }
}

/*!
    Returns the application's delegate. The app can only have one delegate at a time.
*/
- (id)delegate
{
    return _delegate;
}

- (void)finishLaunching
{
    // At this point we clear the window.status to eliminate Safari's "Cancelled" error message
    // The message shouldn't be displayed, because only an XHR is cancelled, but it is a usability issue.
    // We do it here so that applications can change it in willFinish or didFinishLaunching
    window.status = " ";

    var bundle = [CPBundle mainBundle],
        delegateClassName = [bundle objectForInfoDictionaryKey:@"CPApplicationDelegateClass"];

    if (delegateClassName)
    {
        var delegateClass = objj_getClass(delegateClassName);

        if (delegateClass)
            [self setDelegate:[[delegateClass alloc] init]];
    }

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter
        postNotificationName:RTApplicationWillFinishLaunchingNotification
        object:self];

    [defaultCenter
        postNotificationName:RTApplicationDidFinishLaunchingNotification
        object:self];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    _finishedLaunching = YES;
}

- (RTView)rootView
{
    return _rootView;
}

- (void)setRootView:(RTView)aView
{
    _rootView = aView;

    CPLog("delete old content view - add new content view");
}

/*!
    Returns and array of slash seperated arugments to your application.
    These values are pulled from your window location hash.

    For exampled if your application loaded:
    <pre>
    index.html#280north/cappuccino/issues
    </pre>
    The follow array would be returned:
    <pre>
    ["280north", "cappuccino", "issues"]
    </pre>

    @return CPArray - The array of arguments.
*/
- (CPArray)arguments
{
    if (_fullArgsString !== window.location.hash)
        [self _reloadArguments];

    return _args;
}

/*!
    Sets the arguments of your application.
    That is, set the slash seperated values of an array as the window location hash.

    For example if you pass an array:
    <pre>
    ["280north", "cappuccino", "issues"]
    </pre>

    The new window location would be
    <pre>
    index.html#280north/cappuccino/issues
    </pre>

    @param args - An array of arguments.
*/
- (void)setArguments:(CPArray)args
{
    if (!args || args.length == 0)
    {
        _args = [];
        window.location.hash = @"#";

        return;
    }

    if (![args isKindOfClass:CPArray])
        args = [CPArray arrayWithObject:args];

    _args = args;

    var toEncode = [_args copy];
    for (var i = 0, count = toEncode.length; i < count; i++)
        toEncode[i] = encodeURIComponent(toEncode[i]);

    var hash = [toEncode componentsJoinedByString:@"/"];

    window.location.hash = @"#" + hash;
}

- (void)_reloadArguments
{
    _fullArgsString = window.location.hash;

    if (_fullArgsString.length)
    {
        var args = _fullArgsString.substring(1).split("/");

        for (var i = 0, count = args.length; i < count; i++)
            args[i] = decodeURIComponent(args[i]);

        _args = args;
    }
    else
        _args = [];
}

/*!
    Returns a dictionary of the window location named arguments.
    For example if your location was:
    <pre>
    index.html?owner=280north&repo=cappuccino&type=issues
    </pre>

    a CPDictionary with the keys:
    <pre>
    owner, repo, type
    </pre>
    and respective values:
    <pre>
    280north, cappuccino, issues
    </pre>
    Will be returned.
*/
- (CPDictionary)namedArguments
{
    return _namedArgs;
}

@end

/*!
    Starts the GUI and Cappuccino frameworks. This function should be
    called from the \c main() function of your program.
    @class RTApplication
    @return void
*/

function RTApplicationMain(args, namedArgs)
{
    var mainBundle = [CPBundle mainBundle],
        principalClass = [mainBundle principalClass];

    if (!principalClass)
        principalClass = [RTApplication class];

    [principalClass sharedApplication];

    if ([args containsObject:"debug"])
        CPLogRegister(CPLogPopup);

    RTApp._args = args;
    RTApp._namedArgs = namedArgs;

    [RTApp finishLaunching];
}
