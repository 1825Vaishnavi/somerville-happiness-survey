library(tidyverse)
d <- read_rds("data/clean/survey_weighted.rds")

# Which years was each rating question asked?
asked <- d |>
  select(Year, ends_with(".num")) |>
  pivot_longer(-Year, names_to = "question", values_to = "x") |>
  filter(!is.na(x)) |>
  group_by(question) |>
  summarise(years = paste(sort(unique(Year)), collapse = ", "), n = n()) |>
  arrange(desc(n))
print(asked, n = Inf)

# Size of the low-happiness group (happiness rated 1, 2, or 3)
d |> filter(!is.na(Happiness.num)) |>
  group_by(Year) |>
  summarise(n = n(), low_happy = sum(Happiness.num <= 3),
            pct_low = round(100 * mean(Happiness.num <= 3), 1)) |>
  print()