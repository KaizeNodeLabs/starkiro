use core::fmt::{Debug, Display, Error, Formatter};
use super::date::DateTrait;

/// The month of the year.
///
/// This enum is just a convenience implementation.
/// The month in dates created by DateLike objects does not return this enum.
///
/// It is possible to convert from a date to a month independently
/// ```
/// use chrono::prelude::*;
/// let date = Utc.with_ymd_and_hms(2019, 10, 28, 9, 10, 11).unwrap();
/// // `2019-10-28T09:10:11Z`
/// let month = Month::try_from(u8::try_from(date.month()).unwrap()).ok();
/// assert_eq!(month, Some(Month::October))
/// ```
/// Or from a Month to an integer usable by dates
/// ```
/// # use chrono::prelude::*;
/// let month = Month::January;
/// let dt = Utc.with_ymd_and_hms(2019, month.number_from_month(), 28, 9, 10, 11).unwrap();
/// assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
/// ```
/// Allows mapping from and to month, from 1-January to 12-December.
/// Can be Serialized/Deserialized with serde
// Actual implementation is zero-indexed, API intended as 1-indexed for more intuitive behavior.
#[derive(PartialEq, Copy, Drop)]
pub enum Month {
    /// January
    January,
    /// February
    February,
    /// March
    March,
    /// April
    April,
    /// May
    May,
    /// June
    June,
    /// July
    July,
    /// August
    August,
    /// September
    September,
    /// October
    October,
    /// November
    November,
    /// December
    December,
}

#[generate_trait]
pub impl MonthImpl of MonthTrait {
    /// The next month.
    ///
    /// `m`:        | `January`  | `February` | `...` | `December`
    /// ----------- | ---------  | ---------- | --- | ---------
    /// `m.succ()`: | `February` | `March`    | `...` | `January`
    #[inline]
    const fn succ(self: @Month) -> Month {
        match self {
            Month::January => Month::February,
            Month::February => Month::March,
            Month::March => Month::April,
            Month::April => Month::May,
            Month::May => Month::June,
            Month::June => Month::July,
            Month::July => Month::August,
            Month::August => Month::September,
            Month::September => Month::October,
            Month::October => Month::November,
            Month::November => Month::December,
            Month::December => Month::January,
        }
    }

    /// The previous month.
    ///
    /// `m`:        | `January`  | `February` | `...` | `December`
    /// ----------- | ---------  | ---------- | --- | ---------
    /// `m.pred()`: | `December` | `January`  | `...` | `November`
    #[inline]
    const fn pred(self: @Month) -> Month {
        match self {
            Month::January => Month::December,
            Month::February => Month::January,
            Month::March => Month::February,
            Month::April => Month::March,
            Month::May => Month::April,
            Month::June => Month::May,
            Month::July => Month::June,
            Month::August => Month::July,
            Month::September => Month::August,
            Month::October => Month::September,
            Month::November => Month::October,
            Month::December => Month::November,
        }
    }

    /// Returns a month-of-year number starting from January = 1.
    ///
    /// `m`:                     | `January` | `February` | `...` | `December`
    /// -------------------------| --------- | ---------- | --- | -----
    /// `m.number_from_month()`: | 1         | 2          | `...` | 12
    #[inline]
    const fn number_from_month(self: @Month) -> u32 {
        match self {
            Month::January => 1,
            Month::February => 2,
            Month::March => 3,
            Month::April => 4,
            Month::May => 5,
            Month::June => 6,
            Month::July => 7,
            Month::August => 8,
            Month::September => 9,
            Month::October => 10,
            Month::November => 11,
            Month::December => 12,
        }
    }

    /// Get the name of the month
    ///
    /// ```
    /// use chrono::Month;
    ///
    /// assert_eq!(Month::January.name(), "January")
    /// ```
    const fn name(self: @Month) -> felt252 {
        match *self {
            Month::January => 'January',
            Month::February => 'February',
            Month::March => 'March',
            Month::April => 'April',
            Month::May => 'May',
            Month::June => 'June',
            Month::July => 'July',
            Month::August => 'August',
            Month::September => 'September',
            Month::October => 'October',
            Month::November => 'November',
            Month::December => 'December',
        }
    }

    /// Get the length in days of the month
    ///
    /// Yields `None` if `year` is out of range for `NaiveDate`.
    fn num_days(self: @Month, year: u32) -> Option<u8> {
        Some(
            match self {
                Month::January => 31,
                Month::February => match DateTrait::from_ymd_opt(year, 2, 1)?.leap_year() {
                    true => 29,
                    false => 28,
                },
                Month::March => 31,
                Month::April => 30,
                Month::May => 31,
                Month::June => 30,
                Month::July => 31,
                Month::August => 31,
                Month::September => 30,
                Month::October => 31,
                Month::November => 30,
                Month::December => 31,
            },
        )
    }

    #[inline]
    fn from_u64(n: u64) -> Option<Month> {
        Self::from_u32(n.try_into().unwrap())
    }

    #[inline]
    fn from_i64(n: i64) -> Option<Month> {
        Self::from_u32(n.try_into().unwrap())
    }

    #[inline]
    fn from_u32(n: u32) -> Option<Month> {
        match n {
            0 => None,
            1 => Some(Month::January),
            2 => Some(Month::February),
            3 => Some(Month::March),
            4 => Some(Month::April),
            5 => Some(Month::May),
            6 => Some(Month::June),
            7 => Some(Month::July),
            8 => Some(Month::August),
            9 => Some(Month::September),
            10 => Some(Month::October),
            11 => Some(Month::November),
            12 => Some(Month::December),
            _ => None,
        }
    }
}

impl MonthPartialOrd of PartialOrd<Month> {
    #[inline]
    fn lt(lhs: Month, rhs: Month) -> bool {
        lhs.number_from_month() < rhs.number_from_month()
    }
    #[inline]
    fn ge(lhs: Month, rhs: Month) -> bool {
        lhs.number_from_month() >= rhs.number_from_month()
    }
}

impl MonthTryInto of TryInto<u8, Month> {
    fn try_into(self: u8) -> Option<Month> {
        MonthTrait::from_u32(self.into())
    }
}

impl MonthDebug of Debug<Month> {
    fn fmt(self: @Month, ref f: Formatter) -> Result<(), Error> {
        match self {
            Month::January => write!(f, "January"),
            Month::February => write!(f, "February"),
            Month::March => write!(f, "March"),
            Month::April => write!(f, "April"),
            Month::May => write!(f, "May"),
            Month::June => write!(f, "June"),
            Month::July => write!(f, "July"),
            Month::August => write!(f, "August"),
            Month::September => write!(f, "September"),
            Month::October => write!(f, "October"),
            Month::November => write!(f, "November"),
            Month::December => write!(f, "December"),
        }
    }
}

impl MonthDisplay of Display<Month> {
    fn fmt(self: @Month, ref f: Formatter) -> Result<(), Error> {
        Debug::fmt(self, ref f)
    }
}

/// A duration in calendar months
#[derive(Clone, Copy, PartialEq, Drop, Debug)]
pub struct Months {
    months: u32,
}

#[generate_trait]
pub impl MonthsImpl of MonthsTrait {
    /// Construct a new `Months` from a number of months
    const fn new(months: u32) -> Months {
        Months { months }
    }

    /// Returns the total number of months in the `Months` instance.
    #[inline]
    const fn as_u32(self: @Months) -> u32 {
        *self.months
    }
}

impl MonthsPartialOrd of PartialOrd<Months> {
    #[inline]
    fn lt(lhs: Months, rhs: Months) -> bool {
        lhs.months < rhs.months
    }
    #[inline]
    fn ge(lhs: Months, rhs: Months) -> bool {
        lhs.months >= rhs.months
    }
}
