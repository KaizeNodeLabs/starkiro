/// A duration in calendar months
#[derive(Clone, Copy, PartialEq, Drop, Debug)]
pub struct Months {
    months: u32,
}

#[generate_trait]
pub impl MonthsImpl of MonthsTrait {
    /// Construct a new `Months` from a number of months
    fn new(months: u32) -> Months {
        Months { months }
    }

    /// Returns the total number of months in the `Months` instance.
    fn as_u32(self: @Months) -> u32 {
        *self.months
    }
}
