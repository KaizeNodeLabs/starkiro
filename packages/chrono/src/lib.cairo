//! Date and time types unconcerned with timezones.
//!
//! They are primarily building blocks for other types
//! (e.g. [`TimeZone`](../offset/trait.TimeZone.html)),
//! but can be also used for the simpler date and time handling.

pub mod format {
    pub mod formatting;
}
pub mod date;
pub mod datetime;
pub mod days;
pub mod internals;
pub mod isoweek;
pub mod months;
pub mod time;
pub mod time_delta;
pub mod traits;
pub mod utils;
pub mod week;
pub mod weekday;

/// A convenience module appropriate for glob imports (`use chrono::prelude::*;`).
pub mod prelude {
    pub use crate::date::{Date, DateTrait};
    pub use crate::datetime::{DateTime, DateTimeTrait};
    pub use crate::days::{Days, DaysTrait};
    pub use crate::isoweek::{IsoWeek, IsoWeekTrait};
    pub use crate::months::{Month, MonthTrait, Months, MonthsTrait};
    pub use crate::time::{Time, TimeTrait};
    pub use crate::time_delta::{TimeDelta, TimeDeltaTrait};
    pub use crate::traits::{Datelike, Timelike};
    pub use crate::week::{Week, WeekTrait};
    pub use crate::weekday::{Weekday, WeekdayTrait};
}
