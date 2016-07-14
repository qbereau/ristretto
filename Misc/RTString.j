@import <Foundation/CPString.j>

@implementation CPString (Ristretto)

- (CPString)camelizedString
{
    return [self camelizedString:YES];
}

- (CPString)camelizedString:(BOOL)uppercaseFirstLetter
{
    var regex = uppercaseFirstLetter ? /(?:^|[-_])(\w)/g : /[-_](\w)/g;

    return self.replace(regex, function(_, c)
    {
        return c ? c.toUpperCase() : '';
    });
}

- (CPString)underscoreString
{
    return self.replace(/(.)(\W)/g, '$1_$2').toLowerCase();
}

@end
