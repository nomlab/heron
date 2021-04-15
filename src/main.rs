#[macro_use]
extern crate polars;

mod forecast;
mod google;

use self::forecast::forecaster;
use self::google::google_auth;

use chrono::prelude::*;
use chrono::{NaiveDate, Utc};
use std::env;
use std::thread::sleep;
use std::time::{Duration, Instant};

#[test]
fn example() -> Result<()> {
    let weekday = Utc.ymd(2020, 4, 1).weekday();
    print!("{}", weekday);
    Ok(())
}

#[test]
fn print_typename<T>(_: T) {
    println!("{}", std::any::type_name::<T>());
}

fn fiscal_year_first_date(date: Date<Utc>) -> Date<Utc> {
    let mut y = date.year();
    let m = date.month();
    if m == 1 || m == 2 || m == 3 {
        y = y - 1;
    }
    return Utc.ymd(y, 4, 1);
}

fn main() {
    let start = Instant::now();
    let args: Vec<String> = env::args().collect();

    let command = &args[1];
    match command.as_str() {
        "forecast" => {
            // let events = vec![
            //     Utc.ymd(2013, 1, 11),
            //     Utc.ymd(2014, 1, 11),
            //     Utc.ymd(2015, 1, 11),
            // ];
            let events_list = google::google_calendar::get_today_schedule("".to_string());
            let mut events: Vec<Date<Utc>> = events_list
                .items
                .iter()
                .map(|i| match &i.start {
                    Some(dt) => match &dt.date_time {
                        Some(d) => d.parse::<DateTime<Utc>>().unwrap().date(),
                        None => Date::from_utc(
                            NaiveDate::parse_from_str(&dt.date.as_ref().unwrap(), "%Y-%m-%d")
                                .unwrap(),
                            Utc,
                        ),
                    },
                    None => Utc.ymd(2000, 1, 1),
                })
                .collect();
            let first = fiscal_year_first_date(events[0]);
            let last = events.last().unwrap().clone();
            // loop {
            let range_candidates: Vec<i64> = (-3..4).collect();
            let range_recurrence = vec![first, last];
            let middle = start.elapsed();
            let forecasted = forecaster::forecast(range_recurrence, &range_candidates, &events);
            // let fdate = Date::from_utc(
            //     NaiveDate::parse_from_str(forecasted, "%Y-%m-%d").unwrap(),
            //     Utc,
            // );
            // events.push(forecasted);
            println!("forecast: {:?}", forecasted);
            // if forecasted > Utc.ymd(2022, 4, 1) {
            //     break;
            // }
            // }
            let end = start.elapsed();
            println!(
                "{}.{:0.3}秒経過",
                middle.as_secs(),
                middle.subsec_nanos() / 1_000_000
            );
            println!(
                "{}.{:0.3}秒経過",
                end.as_secs(),
                end.subsec_nanos() / 1_000_000
            );
        }
        "show" => {
            let event_list = google::google_calendar::get_today_schedule("".to_string());

            for item in event_list.items {
                println!(
                    "summary:{}, start:{}\nExtended property:{}",
                    item.summary.unwrap(),
                    match item.start {
                        Some(dt) => match dt.date_time {
                            Some(d) => d,
                            None => dt.date.unwrap(),
                        },
                        None => "No time".to_string(),
                    },
                    item.extended_properties
                        .unwrap()
                        .shared
                        .unwrap()
                        .get(&"recurrence_name".to_string())
                        .unwrap()
                );
            }
        }
        _ => println!("No matching command"),
    }
}
