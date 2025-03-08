use datetime::weekday::{Weekday, WeekdayTrait};

#[test]
fn test_days_since() {
    for i in 0_u8..7 {
        let base_day: Weekday = i.try_into().unwrap();

        assert_eq!(base_day.num_days_from_monday(), base_day.days_since(Weekday::Mon));
        assert_eq!(base_day.num_days_from_sunday(), base_day.days_since(Weekday::Sun));

        assert_eq!(base_day.days_since(base_day), 0);

        assert_eq!(base_day.days_since(base_day.pred()), 1);
        assert_eq!(base_day.days_since(base_day.pred().pred()), 2);
        assert_eq!(base_day.days_since(base_day.pred().pred().pred()), 3);
        assert_eq!(base_day.days_since(base_day.pred().pred().pred().pred()), 4);
        assert_eq!(base_day.days_since(base_day.pred().pred().pred().pred().pred()), 5);
        assert_eq!(base_day.days_since(base_day.pred().pred().pred().pred().pred().pred()), 6);

        assert_eq!(base_day.days_since(base_day.succ()), 6);
        assert_eq!(base_day.days_since(base_day.succ().succ()), 5);
        assert_eq!(base_day.days_since(base_day.succ().succ().succ()), 4);
        assert_eq!(base_day.days_since(base_day.succ().succ().succ().succ()), 3);
        assert_eq!(base_day.days_since(base_day.succ().succ().succ().succ().succ()), 2);
        assert_eq!(base_day.days_since(base_day.succ().succ().succ().succ().succ().succ()), 1);
    }
}
