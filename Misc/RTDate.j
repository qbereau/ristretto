
@import <Foundation/CPDate.j>

@implementation CPDate (Ristretto)

+ (id)dateWithISO8601String:(CPString)aString
{
    return [CPDate dateWithTimeIntervalSince1970:Date.parseISO8601(aString) / 1000];
}

- (id)initWithISO8601String:(CPString)aString
{
    return [self initWithTimeIntervalSince1970:Date.parseISO8601(aString) / 1000];
}


@end

var cultures = [
    {
        name: "fr-FR",
        englishName: "French (France)",
        nativeName: "français (France)",

        /* Day Name Strings */
        dayNames: ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"],
        abbreviatedDayNames: ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."],
        shortestDayNames: ["di", "lu", "ma", "me", "je", "ve", "sa"],
        firstLetterDayNames: ["d", "l", "m", "m", "j", "v", "s"],

        /* Month Name Strings */
        monthNames: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
        abbreviatedMonthNames: ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."],

        /* AM/PM Designators */
        amDesignator: "",
        pmDesignator: "",

        firstDayOfWeek: 1,
        twoDigitYearMax: 2029,

        dateElementOrder: "dmy",

        /* Standard date and time format patterns */
        formatPatterns:
        {
            shortDate: "dd/MM/yyyy",
            longDate: "dddd d MMMM yyyy",
            shortTime: "HH:mm",
            longTime: "HH:mm:ss",
            fullDateTime: "dddd d MMMM yyyy HH:mm:ss",
            sortableDateTime: "yyyy-MM-ddTHH:mm:ss",
            universalSortableDateTime: "yyyy-MM-dd HH:mm:ssZ",
            rfc1123: "ddd, dd MMM yyyy HH:mm:ss GMT",
            monthDay: "d MMMM",
            yearMonth: "MMMM yyyy"
        }
    }];

@implementation CPDate (Extension)

+ (CPDate)today
{
    return [CPDate date];
}

+ (CPInteger)getDaysInMonth:(CPInteger)month forYear:(CPInteger)year
{
    return [31, ([CPDate isLeapYear:year] ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
}

+ (BOOL)isLeapYear:(CPInteger)year
{
    return ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0);
}

/////////////////////////////////
// Accessors

- (CPInteger)year
{
    return self.getFullYear();
}

- (CPInteger)month
{
    return self.getMonth() + 1;
}

- (CPInteger)day
{
    return self.getDate();
}

- (CPInteger)dayOfWeek
{
    return self.getDay();
}

- (CPInteger)dayOfYear
{
    var first = new Date([self year],0,1);
    return ROUND(([[self copy] clearTime] - first) / 86400000) + 1;
}

- (CPInteger)hours
{
    return self.getHours();
}

- (CPInteger)minutes
{
    return self.getMinutes();
}

- (CPIntger)seconds
{
    return self.getSeconds();
}

- (CPInteger)milliseconds
{
    return self.getMilliseconds();
}

- (void)setYear:(CPInteger)year
{
    self.setFullYear();
}

- (void)setMonth:(CPInteger)month
{
    self.setMonth(month - 1);
}

- (void)setDay:(CPInteger)day
{
    self.setDate(day);
}

- (void)setHours:(CPInteger)hours
{
    self.setHours(hours);
}

- (void)setMinutes:(CPInteger)minutes
{
    self.setMinutes(minutes);
}

- (void)setSeconds:(CPInteger)seconds
{
    self.setSeconds(seconds);
}

- (void)setMilliseconds:(CPInteger)milliseconds
{
    self.setMilliseconds(milliseconds);
}

/////////////////////////////////
// Operations

- (CPDate)addYears:(CPInteger)value
{
    [self addMonths:(value * 12)];
    return self;
}

- (CPDate)addMonths:(CPInteger)value
{
    var day = [self day];
    [self setDay:1];
    [self setMonth:([self month] + value)];
    [self setDay:MIN(day, [CPDate getDaysInMonth:[self month] forYear:[self year]])];
    return self;
}

- (CPDate)addWeeks:(CPInteger)value
{
    return [self addDays:(value * 7)];
}

- (CPDate)addDays:(CPInteger)value
{
    [self addHours:(value * 24)];
    return self;
}

- (CPDate)addHours:(CPInteger)value
{
    [self addMinutes:(value * 60)];
    return self;
}

- (CPDate)addMinutes:(CPInteger)value
{
    [self addSeconds:(value * 60)];
    return self;
}

- (CPDate)addSeconds:(CPInteger)value
{
    [self addMilliseconds:(value * 1000)];
    return self;
}

- (CPDate)addMilliseconds:(CPInteger)value
{
    [self setMilliseconds:([self milliseconds] + value)];
    return self;
}

/////////////////////////////////
// Comparison

- (BOOL)isEqual:(CPDate)date
{
     return ([self compare:date] == CPOrderedSame) ? YES : NO;
}

- (BOOL)isAfter:(CPDate)date
{
    return ([self compare:date] == CPOrderedDescending) ? YES : NO;
}

- (BOOL)isBefore:(CPDate)date
{
    return ([self compare:date] == CPOrderedAscending) ? YES : NO;
}

- (BOOL)isToday
{
    return [[[self clone] clearTime] isEqual:[CPDate today]];
}

/////////////////////////////////
// Utils

- (CPDate)clearTime
{
    [self setHours:0];
    [self setMinutes:0];
    [self setSeconds:0];
    [self setMilliseconds:0];
    return self;
}

- (void)setTimeToNow
{
    var now = [Date date];
    [self setHours:[now hours]];
    [self setMinutes:[now minutes]];
    [self setSeconds:[now seconds]];
    [self setMilliseconds:[now milliseconds]];
}

- (CPDate)moveToFirstDayOfMonth
{
    [self setDay:1];
    return self;
}

- (CPDate)moveToLastDayOfMonth
{
    [self setDay:[self getDaysInMonth:[self month] forYear:[self year]]];
    return self;
}

/////////////////////////////////
// Format

- (CPString)stringWithFormat:(CPString)format
{
    if (format && format.length == 1)
    {
        var c = cultures[0].formatPatterns;
        switch (format)
        {
            case "d":
                return [self stringWithFormat:c.shortDate];
            case "D":
                return [self stringWithFormat:c.longDate];
            case "F":
                return [self stringWithFormat:c.fullDateTime];
            case "m":
                return [self stringWithFormat:c.monthDay];
            case "r":
                return [self stringWithFormat:c.rfc1123];
            case "s":
                return [self stringWithFormat:c.sortableDateTime];
            case "t":
                return [self stringWithFormat:c.shortTime];
            case "T":
                return [self stringWithFormat:c.longTime];
            case "u":
                return [self stringWithFormat:c.universalSortableDateTime];
            case "y":
                return [self stringWithFormat:c.yearMonth];
        }
    }

    var ord = function (n)
    {
        switch (n * 1)
        {
            case 1:
            case 21:
            case 31:
                return "st";
            case 2:
            case 22:
                return "nd";
            case 3:
            case 23:
                return "rd";
            default:
                return "th";
        }
    };

    return format ? format.replace(/(\\)?(dd?d?d?|MM?M?M?|yy?y?y?|hh?|HH?|mm?|ss?|tt?|S)/g,
    function (m)
    {
        if (m.charAt(0) === "\\")
        {
            return m.replace("\\", "");
        }

        switch (m)
        {
            case "hh":
                return [CPString stringWithFormat:@"%02d", [self hours] < 13 ? ([self hours] === 0 ? 12 : [self hours]) : ([self hours] - 12)];
            case "h":
                return [self hours] < 13 ? ([self hours] === 0 ? 12 : [self hours]) : ([self hours] - 12);
            case "HH":
                return [CPString stringWithFormat:@"%02d", [self hours]];
            case "H":
                return [self hours];
            case "mm":
                return [CPString stringWithFormat:@"%02d", [self minutes]];
            case "m":
                return [self minutes];
            case "ss":
                return [CPString stringWithFormat:@"%02d", [self seconds]];
            case "s":
                return [self seconds];
            case "yyyy":
                return [CPString stringWithFormat:@"%04d", [self year]];
            case "yy":
                return [CPString stringWithFormat:@"%02d", [self year]];
            case "dddd":
                return cultures[0].dayNames[[self dayOfWeek]];
            case "ddd":
                return cultures[0].abbreviatedDayNames[[self dayOfWeek]];
            case "dd":
                return [CPString stringWithFormat:@"%02d", [self day]];
            case "d":
                return [self day];
            case "MMMM":
                return cultures[0].monthNames[[self month] - 1];
            case "MMM":
                return cultures[0].abbreviatedMonthNames[[self month] - 1];
            case "MM":
                return [CPString stringWithFormat:@"%02d", [self month]];
            case "M":
                return [self month];
            case "t":
                return [self hours] < 12 ? cultures[0].amDesignator.substring(0, 1) : cultures[0].pmDesignator.substring(0, 1);
            case "tt":
                return [self hours] < 12 ? cultures[0].amDesignator : cultures[0].pmDesignator;
            case "S":
                return ord([self day]);
            default:
                return m;
        }
    }
    ) : self.toString();
}

@end
