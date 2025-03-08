pub mod format {
    pub mod formatting;
}
pub mod date;
pub mod datetime;
pub mod internals;
pub mod month;
pub mod time_delta;
pub mod time;
pub mod utils;
pub mod weekday;

/// A duration in calendar days.
///
/// This is useful because when using `TimeDelta` it is possible that adding `TimeDelta::days(1)`
/// doesn't increment the day value as expected due to it being a fixed number of seconds. This
/// difference applies only when dealing with `DateTime<TimeZone>` data types and in other cases
/// `TimeDelta::days(n)` and `Days::new(n)` are equivalent.
#[derive(Clone, Copy, PartialEq, Drop, Debug)]
pub struct Days {
    num: u64,
}

#[generate_trait]
pub impl DaysImpl of DaysTrait {
    /// Construct a new `Days` from a number of days
    fn new(num: u64) -> Days {
        Days { num }
    }
}
