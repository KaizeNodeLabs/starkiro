# Chrono: Date and Time for Cairo

Chrono aims to provide all functionality needed to do correct operations on dates and times in the [proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar).
This library is a Cairo port of a subset of the [Rust library with the same name](https://docs.rs/chrono/latest/chrono/), without timezone support.

## Installation

In your project directory, run the following command to add the library as a dependency:

```sh
scarb add chrono@0.1.0
```

Alternatively, you can manually add the dependency. In your Scarb.toml file, include:

```toml
[dependencies]
chrono = "0.1.0"
```

## Overview

### [Time Delta](./src/time_delta.cairo)

Chrono has a `TimeDelta` type to represent the magnitude of a time span. This is an “accurate” duration represented as seconds, and does not represent “nominal” components such as days or months.

### [Date and Time](./src/datetime.cairo)

Chrono provides a `DateTime` type to represent an ISO 8601 combined date and time without timezone.

You can create your own date and time using a rich combination of initialization methods.

```cairo
use chrono::prelude::*;

let ymdhms = |y, m, d, h, n, s| {
    DateTrait::from_ymd_opt(y, m, d).unwrap().and_hms_opt(h, n, s).unwrap()
};

let dt = ymdhms(2014, 7, 8, 9, 10, 11); // `2014-07-08T09:10:11`
assert_eq!(format!("{}", dt), "2014-07-08 09:10:11");
// July 8 is 188th day of the year 2014 (`o` for "ordinal")
assert_eq!(dt, DateTrait::from_yo_opt(2014, 189).unwrap().and_hms_opt(9, 10, 11).unwrap());
// July 8 is Tuesday in ISO week 28 of the year 2014.
assert_eq!(
    dt,
    DateTrait::from_isoywd_opt(2014, 28, Weekday::Tue).unwrap().and_hms_opt(9, 10, 11).unwrap(),
);
```

Various properties are available to the date and time, and can be altered individually. Most of them are defined in the traits `Datelike` and `Timelike` which you should `use` before. Addition and subtraction is also supported. The following illustrates most supported operations to the date and time:

```cairo
use chrono::prelude::*;

let ymdhms = |y, m, d, h, n, s| {
    DateTrait::from_ymd_opt(y, m, d).unwrap().and_hms_opt(h, n, s).unwrap()
};

// assume this returned `2014-11-28T21:45:59`:
let dt = ymdhms(2014, 11, 28, 21, 45, 59);
// property accessors
assert_eq!((dt.year(), dt.month(), dt.day()), (2014, 11, 28));
assert_eq!((dt.month0(), dt.day0()), (10, 27)); // for unfortunate souls
assert_eq!((dt.hour(), dt.minute(), dt.second()), (21, 45, 59));
assert_eq!(dt.weekday(), Weekday::Fri);
assert_eq!(dt.weekday().number_from_monday(), 5); // Mon=1, ..., Sun=7
assert_eq!(dt.ordinal(), 332); // the day of year
assert_eq!(dt.num_days_from_ce(), 735565); // the number of days from and including Jan 1, 1

// a sample of property manipulations (validates dynamically)
assert_eq!(dt.with_day(29).unwrap().weekday(), Weekday::Sat); // 2014-11-29 is Saturday
assert_eq!(dt.with_day(32), None);

// arithmetic operations
let dt1 = ymdhms(2014, 11, 14, 8, 9, 10);
let dt2 = ymdhms(2014, 11, 14, 10, 9, 8);
assert_eq!(dt1.signed_duration_since(dt2), TimeDeltaTrait::seconds(-2 * 3600 + 2));
assert_eq!(dt2.signed_duration_since(dt1), TimeDeltaTrait::seconds(2 * 3600 - 2));
assert_eq!(
    ymdhms(1970, 1, 1, 0, 0, 0)
        .checked_add_signed(TimeDeltaTrait::seconds(1_000_000_000))
        .unwrap(),
    ymdhms(2001, 9, 9, 1, 46, 40),
);
assert_eq!(
    ymdhms(1970, 1, 1, 0, 0, 0)
        .checked_sub_signed(TimeDeltaTrait::seconds(1_000_000_000))
        .unwrap(),
    ymdhms(1938, 4, 24, 22, 13, 20),
);
```

### Formatting

At the moment we only support simple formatting through the `Display` trait to format the date and time to a `ByteArray` using this format: `yyyy-MM-dd HH:mm:ss`.

```cairo
use chrono::prelude::*;

let dt: DateTime = Default::default();
assert_eq!(format!("{}", dt), "1970-01-01 00:00:00");
```

### Conversion from and to EPOCH timestamps

Use `DateTimeTrait::from_timestamp(i64: secs)` to construct a `DateTime` from a UNIX timestamp (seconds that passed since January 1st 1970).

Use `DateTimeTrait.timestamp` to get the timestamp (in seconds) from a `DateTime`.

```cairo
use chrono::prelude::*;

let ymdhms = |y, m, d, h, n, s| {
    DateTrait::from_ymd_opt(y, m, d).unwrap().and_hms_opt(h, n, s).unwrap()
};

// Construct a datetime from epoch:
let dt = DateTimeTrait::from_timestamp(1_500_000_000).unwrap();
assert_eq!(format!("{}", dt), "2017-07-14 02:40:00");

// Get epoch value from a datetime:
let dt = ymdhms(2017, 7, 14, 2, 40, 0);
assert_eq!(dt.timestamp(), 1_500_000_000);
```

Alternatively, you can use `DateTimeTrait::from_block_timestamp(u64: block_timestamp)` to construct a `DateTime` from a Starknet block timestamp.

```cairo
start_cheat_block_timestamp_global(1707868800);
assert_eq!(
    format!("{}", DateTimeTrait::from_block_timestamp(get_block_timestamp()).unwrap()),
    "2024-02-14 00:00:00",
);
```

### Limitations

- Only the proleptic Gregorian calendar (i.e. extended to support older dates) is supported.
- Date types are limited to about + 262,000 years from the common epoch.
- At the moment negative years are not supported.

### Cairo version requirements

The Minimum Supported Cairo Version is currently Cairo 2.11.0.
