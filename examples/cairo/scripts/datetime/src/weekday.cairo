use core::fmt::{Debug, Display, Error, Formatter};

/// The day of week.
///
/// The order of the days of week depends on the context.
/// (This is why this type does *not* implement `PartialOrd` or `Ord` traits.)
/// One should prefer `*_from_monday` or `*_from_sunday` methods to get the correct result.
///
/// # Example
/// ```
/// use chrono::Weekday;
///
/// let monday = "Monday".parse::<Weekday>().unwrap();
/// assert_eq!(monday, Weekday::Mon);
///
/// let sunday = Weekday::try_from(6).unwrap();
/// assert_eq!(sunday, Weekday::Sun);
///
/// assert_eq!(sunday.num_days_from_monday(), 6); // starts counting with Monday = 0
/// assert_eq!(sunday.number_from_monday(), 7); // starts counting with Monday = 1
/// assert_eq!(sunday.num_days_from_sunday(), 0); // starts counting with Sunday = 0
/// assert_eq!(sunday.number_from_sunday(), 1); // starts counting with Sunday = 1
///
/// assert_eq!(sunday.succ(), monday);
/// assert_eq!(sunday.pred(), Weekday::Sat);
/// ```
#[derive(PartialEq, Copy, Drop)]
pub enum Weekday {
    /// Monday.
    Mon,
    /// Tuesday.
    Tue,
    /// Wednesday.
    Wed,
    /// Thursday.
    Thu,
    /// Friday.
    Fri,
    /// Saturday.
    Sat,
    /// Sunday.
    Sun,
}

#[generate_trait]
pub impl WeekdayImpl of WeekdayTrait {
    /// The next day in the week.
    ///
    /// `w`:        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ----------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.succ()`: | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun` | `Mon`
    fn succ(self: @Weekday) -> Weekday {
        match self {
            Weekday::Mon => Weekday::Tue,
            Weekday::Tue => Weekday::Wed,
            Weekday::Wed => Weekday::Thu,
            Weekday::Thu => Weekday::Fri,
            Weekday::Fri => Weekday::Sat,
            Weekday::Sat => Weekday::Sun,
            Weekday::Sun => Weekday::Mon,
        }
    }

    /// The previous day in the week.
    ///
    /// `w`:        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ----------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.pred()`: | `Sun` | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat`
    fn pred(self: @Weekday) -> Weekday {
        match self {
            Weekday::Mon => Weekday::Sun,
            Weekday::Tue => Weekday::Mon,
            Weekday::Wed => Weekday::Tue,
            Weekday::Thu => Weekday::Wed,
            Weekday::Fri => Weekday::Thu,
            Weekday::Sat => Weekday::Fri,
            Weekday::Sun => Weekday::Sat,
        }
    }

    /// Returns a day-of-week number starting from Monday = 1. (ISO 8601 weekday number)
    ///
    /// `w`:                      | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.number_from_monday()`: | 1     | 2     | 3     | 4     | 5     | 6     | 7
    fn number_from_monday(self: @Weekday) -> u32 {
        self.days_since(Weekday::Mon) + 1
    }

    /// Returns a day-of-week number starting from Sunday = 1.
    ///
    /// `w`:                      | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.number_from_sunday()`: | 2     | 3     | 4     | 5     | 6     | 7     | 1
    fn number_from_sunday(self: @Weekday) -> u32 {
        self.days_since(Weekday::Sun) + 1
    }

    /// Returns a day-of-week number starting from Monday = 0.
    ///
    /// `w`:                        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// --------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.num_days_from_monday()`: | 0     | 1     | 2     | 3     | 4     | 5     | 6
    ///
    /// # Example
    ///
    /// ```
    /// # #[cfg(feature = "clock")] {
    /// # use chrono::{Local, Datelike};
    /// // MTWRFSU is occasionally used as a single-letter abbreviation of the weekdays.
    /// // Use `num_days_from_monday` to index into the array.
    /// const MTWRFSU: [char; 7] = ['M', 'T', 'W', 'R', 'F', 'S', 'U'];
    ///
    /// let today = Local::now().weekday();
    /// println!("{}", MTWRFSU[today.num_days_from_monday() as usize]);
    /// # }
    /// ```
    fn num_days_from_monday(self: @Weekday) -> u32 {
        self.days_since(Weekday::Mon)
    }

    /// Returns a day-of-week number starting from Sunday = 0.
    ///
    /// `w`:                        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// --------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.num_days_from_sunday()`: | 1     | 2     | 3     | 4     | 5     | 6     | 0
    fn num_days_from_sunday(self: @Weekday) -> u32 {
        self.days_since(Weekday::Sun)
    }

    /// The number of days since the given day.
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::Weekday::*;
    /// assert_eq!(Mon.days_since(Mon), 0);
    /// assert_eq!(Sun.days_since(Tue), 5);
    /// assert_eq!(Wed.days_since(Sun), 3);
    /// ```
    fn days_since(self: @Weekday, other: Weekday) -> u32 {
        let lhs: u32 = (*self).into();
        let rhs: u32 = other.into();
        if lhs < rhs {
            7 + lhs - rhs
        } else {
            lhs - rhs
        }
    }
}

impl WeekdayInto of Into<Weekday, u32> {
    fn into(self: Weekday) -> u32 {
        match self {
            Weekday::Mon => 0,
            Weekday::Tue => 1,
            Weekday::Wed => 2,
            Weekday::Thu => 3,
            Weekday::Fri => 4,
            Weekday::Sat => 5,
            Weekday::Sun => 6,
        }
    }
}

impl WeekdayDebug of Debug<Weekday> {
    fn fmt(self: @Weekday, ref f: Formatter) -> Result<(), Error> {
        match self {
            Weekday::Mon => write!(f, "Mon"),
            Weekday::Tue => write!(f, "Tue"),
            Weekday::Wed => write!(f, "Wed"),
            Weekday::Thu => write!(f, "Thu"),
            Weekday::Fri => write!(f, "Fri"),
            Weekday::Sat => write!(f, "Sat"),
            Weekday::Sun => write!(f, "Sun"),
        }
    }
}

impl WeekdayDisplay of Display<Weekday> {
    fn fmt(self: @Weekday, ref f: Formatter) -> Result<(), Error> {
        Debug::fmt(self, ref f)
    }
}

/// Any weekday can be represented as an integer from 0 to 6, which equals to
/// [`Weekday::num_days_from_monday`](#method.num_days_from_monday) in this implementation.
/// Do not heavily depend on this though; use explicit methods whenever possible.
impl WeekdayTryInto of TryInto<u8, Weekday> {
    fn try_into(self: u8) -> Option<Weekday> {
        match self {
            0 => Some(Weekday::Mon),
            1 => Some(Weekday::Tue),
            2 => Some(Weekday::Wed),
            3 => Some(Weekday::Thu),
            4 => Some(Weekday::Fri),
            5 => Some(Weekday::Sat),
            6 => Some(Weekday::Sun),
            _ => None,
        }
    }
}
