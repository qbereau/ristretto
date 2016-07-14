/*
 * RTSVGTextElement.j
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTSVGTextElement : RTSVGElement
{
    DOMObject       _txtNode;
}

- (id)initWithView:(RTView)aView
{
    if (self = [super initWithView:aView])
    {
        if (_contentNode)
        {
            _domObject.removeChild(_contentNode);
        }

        _contentNode = document.createElementNS(SVG_NS, "text");
        _contentNode.setAttribute("id", "content_"+[_view UID]);
        _domObject.appendChild(_contentNode);
    }
    return self;
}

- (void)_updateContentNode
{
    [super _updateContentNode];

    if (![_view text])
        return;

    var tSize       = [[_view text] sizeWithFont:[_view font]],
        fontSize    = [[_view font] size];


    if ([_view numberOfLines] === 1)
    {
        if ([_view adjustsFontSizeToFitWidth])
        {
            if (tSize.width > [_view frameSize].width)
            {
                fontSize = [[_view text] fontSizeToFit:[_view frameSize] withFont:[_view font] minSize:[_view minimumFontSize]];
            }
        }
    }

    var pos = CGPointMake(0, [_view frameSize].height / 2 - tSize.height / 2);
    switch ([_view textAlignment])
    {
        case RTTextAlignmentLeft:
            _contentNode.setAttribute('text-anchor', 'left');
            break;
        case RTTextAlignmentCenter:
            _contentNode.setAttribute('text-anchor', 'middle');
            pos = CGPointMake([_view frameSize].width / 2, pos.y);
            break;
        case RTTextAlignmentRight:
            _contentNode.setAttribute('text-anchor', 'end');
            pos = CGPointMake([_view frameSize].width, pos.y);
            break;
    }

    _contentNode.setAttribute("style", "fill-opacity: 1");
    _contentNode.setAttribute('x', pos.x);
    _contentNode.setAttribute('y', pos.y);
    if ([[RTRenderer sharedRenderer] isTiny])
        _contentNode.setAttribute('y', fontSize * 0.90);
    else
        _contentNode.setAttribute('dominant-baseline', 'text-before-edge');

    _contentNode.setAttribute('font-family', [[_view font] familyName]);
    _contentNode.setAttribute('font-style', [[_view font] isItalic] ? 'italic' : 'normal');
    _contentNode.setAttribute('font-weight', [[_view font] isBold] ? 'bold' : 'normal');
    _contentNode.setAttribute('font-size', fontSize);
    _contentNode.setAttribute('fill', [[_view textColor] cssString]);
    _contentNode.textContent = [_view text];
}

@end
