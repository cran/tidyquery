test_that("Simple SELECT example query #1 returns expected result on dtplyr_step", {
  skip_if_not(exists("iris_dt"), message = "Test data not loaded")
  expect_equal(
    query(
      "SELECT Species, COUNT(*) AS n FROM iris_dt GROUP BY Species"
    ) %>% as.data.frame(),
    iris_dt %>%
      group_by(Species) %>%
      summarise(n = n()) %>%
      ungroup() %>%
      as.data.frame()
  )
})

test_that("Full example #1 with join returns expected result on dtplyr_step", {
  skip_if_not(exists("flights_dt") && exists("planes_dt"), message = "Test data not loaded")
  expect_equal(
    query(
      "SELECT origin, dest,
          COUNT(flight) AS num_flts,
          round(SUM(seats)) AS num_seats,
          round(AVG(arr_delay)) AS avg_delay
      FROM flights_dt f LEFT OUTER JOIN planes_dt p
        ON f.tailnum = p.tailnum
      WHERE distance BETWEEN 200 AND 300
      AND air_time IS NOT NULL
      GROUP BY origin, dest
      HAVING num_flts > 3000
      ORDER BY num_seats DESC, avg_delay ASC
      LIMIT 100;"
    ) %>% as.data.frame(),
    flights_dt %>%
      left_join(planes_dt, by = "tailnum", suffix = c(".f", ".p")) %>%
      rename(f.year = "year.f", p.year = "year.p") %>%
      filter(between(distance, 200, 300) & !is.na(air_time)) %>%
      group_by(origin, dest) %>%
      filter(sum(!is.na(flight)) > 3000) %>%
      summarise(
        num_flts = sum(!is.na(flight)),
        num_seats = round(sum(seats, na.rm = TRUE)),
        avg_delay = round(mean(arr_delay, na.rm = TRUE))
      ) %>%
      ungroup() %>%
      arrange(desc(num_seats), avg_delay) %>%
      head(100L) %>%
      as.data.frame()
  )
})

test_that("query() fails when input dtplyr_step is grouped", {
  skip_if_not(exists("flights_dt"), message = "Test data not loaded")
  expect_error(
    flights_dt %>% group_by(month) %>% query("SELECT COUNT(*)"),
    "grouped"
  )
})
