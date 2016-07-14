/*
 * RTTextStorage.j - Ported from FrappKit's FPTextStorage
 * Ristretto
 *
 * Created by Quentin Bereau on May 8, 2012.
 * 
 */

@implementation RTTextStorage : CPObject
{
	//CPMutableArray 		layoutManagers;
	CPMutableArray			blocks 			@accessors;
	CPFont					font 			@accessors;
	CPColor					foregroundColor @accessors;
	id						delegate 		@accessors;
	CPString 				string 			@accessors;
}

- (id)initWithString:(CPString)aString attributes:(CPDictionary)attributes
{
	if (self = [super init])
	{
		string = aString;
		layoutManagers = [[CPMutableArray alloc] init];
	}
	return self;
}

+ (id)textStorageWithString:(CPString)aString attributes:(CPDictionary)attributes
{
	return [[[self alloc] initWithString:aString attributes:attributes] autorelease];
}

/*- (CPMutableArray)layoutManagers
{
	return layoutManagers;
}

- (void)addLayoutManager:(JTLayoutManager)aLayoutManager
{
	[layoutManagers addObject:aLayoutManager];
}

- (void)removeLayoutManager:(JTLayoutManager)aLayoutManager
{
	[layoutManagers removeObject:aLayoutManager];
}*/

- (CPArray)breakContents
{
	var breakStrings = [string componentsSeparatedByString:@"\n"];
	var breakContents = [[CPMutableArray alloc] init];
	for (var i=0;i<[breakStrings count];i++)
	{
		var breakString = [breakStrings objectAtIndex:i];
		var arr = [breakString componentsSeparatedByString:@" "];

		// this part is to support cases where there are multiple whitespaces
		for (var idx = 0; idx < [arr count]; ++idx)
		{
			if (arr[idx].length == 0)
				arr[idx] = " ";
		}
		[breakContents addObject:arr];
	}
	return breakContents;
}

- (CPArray)paragraphs
{
	var paragraphArray = [CPMutableArray array];
	var paragraphStrings = [string componentsSeparatedByString:@"\n\n"];
	for (var i=0;i<[paragraphStrings count];i++)
	{
		var paragraphString = [paragraphStrings objectAtIndex:i];
		[paragraphArray addObject:[RTTextStorage textStorageWithString:paragraphString attributes:nil]];
	}
	return paragraphArray;
}

- (void)setParagraphs:(CPArray)paragraphs
{
	self.string = [paragraphs componentsJoinedByString:@"\n\n"];
}

- (CPArray)words
{
	return [string componentsSeparatedByString:@" "];
}

- (void)setWords:(CPArray)words
{
	self.string = [words componentsJoinedByString:@" "];
}

- (void)processEditing
{
	if (delegate)
		[delegate textStorageWillProcessEditing:self];
	
	// Do edit processing here
	for (var i=0;i<[layoutManagers count];i++)
	{
		var layoutManager = [layoutManagers objectAtIndex:i];
		[layoutManager textStorage:self edited:RTTextStorageEditedCharactersMask range:CPMakeRange(0,0) changeInLength:0 invalidatedRange:CPMakeRange(0,0)];
	}
	
	if (delegate)
		[delegate textStorageDidProcessEditing:self];
}

@end