test_that("Simple SELECT example query #1 returns expected result on Arrow Dataset", {
  skip_if_not(exists("iris_ad"), message = "Test data not loaded")
  expect_equal(
    query(
      "SELECT Species, COUNT(*) AS n FROM iris_ad GROUP BY Species"
    ) %>% as.data.frame(),
    iris_ad %>%
      group_by(Species) %>%
      summarise(n = n()) %>%
      ungroup() %>%
      as.data.frame()
  )
})

test_that("Simple SELECT example query #1 returns expected result on arrow_dplyr_query created from Arrow Dataset", {
  skip_if_not(exists("iris_ad"), message = "Test data not loaded")
  iris_adq <- iris_ad %>%
    mutate(Species = stringr::str_to_title(as.character(Species)))
  expect_equal(
    query(
      "SELECT Species, COUNT(*) AS n FROM iris_adq GROUP BY Species"
    ) %>% as.data.frame(),
    iris_adq %>%
      group_by(Species) %>%
      summarise(n = n()) %>%
      ungroup() %>%
      as.data.frame()
  )
})

test_that("Full example #1 with join returns expected result on Arrow Dataset", {
  skip_if_not(exists("flights_ad") && exists("planes_ad"), message = "Test data not loaded")
  expect_equal(
    query(
      "SELECT origin, dest,
          COUNT(flight) AS num_flts,
          round(SUM(seats)) AS num_seats,
          round(AVG(arr_delay)) AS avg_delay
      FROM flights_ad f LEFT OUTER JOIN planes_ad p
        ON f.tailnum = p.tailnum
      WHERE distance BETWEEN 200 AND 300
      AND air_time IS NOT NULL
      GROUP BY origin, dest
      -- HAVING num_flts > 3000
      ORDER BY num_seats DESC, avg_delay ASC
      LIMIT 100;"
    ) %>% as.data.frame(),
    flights_ad %>%
      left_join(planes_ad, by = "tailnum", suffix = c(".f", ".p")) %>%
      rename(f.year = "year.f", p.year = "year.p") %>%
      filter(between(distance, 200, 300) & !is.na(air_time)) %>%
      group_by(origin, dest) %>%
      #filter(sum(!is.na(flight)) > 3000) %>%
      summarise(
        num_flts = sum(!is.na(flight), na.rm = TRUE),
        num_seats = round(sum(seats, na.rm = TRUE)),
        avg_delay = round(mean(arr_delay, na.rm = TRUE))
      ) %>%
      ungroup() %>%
      arrange(desc(num_seats), avg_delay) %>%
      head(100L) %>%
      as.data.frame()
  )
})

test_that("query() fails when input Arrow Dataset is grouped", {
  skip_if_not(exists("flights_ad"), message = "Test data not loaded")
  expect_error(
    flights_ad %>% group_by(month) %>% query("SELECT COUNT(*)"),
    "grouped"
  )
})

test_that("query() fails when input arrow_dplyr_query created from Arrow Dataset is grouped", {
  skip("currently does not fail as expected")
  skip_if_not(exists("flights"), message = "Test data not loaded")
  skip_if_not_installed("arrow")
  expect_error(
    flights %>%
      group_by(month) %>%
      InMemoryDataset$create() %>%
      query("SELECT COUNT(*)"),
    "grouped"
  )
})
