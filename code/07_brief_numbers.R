library(tidyverse)
d  <- read_rds("data/clean/survey_weighted.rds")
xt <- read_csv("output/crosstabs_long.csv", show_col_types = FALSE)

# Citywide 2025 numbers (weighted)
d |> filter(Year == 2025) |>
  summarise(pct_happy      = round(100 * weighted.mean(Happiness.num >= 4, weight, na.rm = TRUE), 1),
            pct_satisfied  = round(100 * weighted.mean(Life.Satisfaction.num >= 4, weight, na.rm = TRUE), 1),
            pct_priced_out = round(100 * weighted.mean(Priced.Out.Concern.num == 3, weight, na.rm = TRUE), 1)) |>
  print()

# 2025 by renting, age, and income
xt |> filter(Year == 2025, by %in% c("tenure_grp", "age_grp", "Likely.Low.Income")) |>
  select(question, by, group, pct) |>
  print(n = Inf)