library(tidyverse)
library(writexl)

d <- read_rds("data/clean/survey_weighted.rds")

questions <- c("Happiness.num", "Life.Satisfaction.num", "Somerville.Satisfaction.num",
               "Housing.Condition.Satisfaction.num", "Priced.Out.Concern.num",
               "Work.Opportunities.Satisfaction.num", "Grocery.Access.Satisfaction.num",
               "Relief.Heat.Satisfaction.num", "Restaurants.Shops.Businesses.Satisfaction.num",
               "Basic.Needs.Satisfaction.num", "Health.Services.Satisfaction.num",
               "Public.Spaces.Satisfaction.num", "Enjoy.Create.Art.Satisfaction.num")
groups <- c("Ward", "age_grp", "tenure_grp", "gender_grp", "Likely.Low.Income")

make_xtab <- function(q, g) {
  concern   <- str_detect(q, "Concern")
  cutoff    <- if (concern) 3 else 4
  measure   <- if (concern) "% very concerned" else "% rating 4 or 5"
  d |>
    filter(!is.na(.data[[q]]), !is.na(.data[[g]]),
           !as.character(.data[[g]]) %in% c("Missing", "Other/Missing")) |>
    group_by(Year, group = as.character(.data[[g]])) |>
    summarise(n = n(),
              pct = round(100 * weighted.mean(.data[[q]] >= cutoff, weight), 1),
              .groups = "drop") |>
    mutate(pct = if_else(n < 30, NA_real_, pct),   # hide small groups
           question = str_remove(q, "\\.num$"), by = g, measure = measure)
}

xtabs <- expand_grid(q = questions, g = groups) |>
  pmap_dfr(function(q, g) make_xtab(q, g)) |>
  select(question, measure, by, Year, group, n, pct)

n_tables <- xtabs |> distinct(question, by, Year) |> nrow()
cat("Number of crosstabs:", n_tables, "\n")

write_xlsx(split(xtabs, xtabs$by), "output/crosstabs.xlsx")
write_csv(xtabs, "output/crosstabs_long.csv")

# Preview: 2025 by ward for the top 5 drivers
xtabs |>
  filter(Year == 2025, by == "Ward", question %in% str_remove(questions[4:8], "\\.num$")) |>
  select(question, measure, group, pct) |>
  pivot_wider(names_from = group, values_from = pct) |>
  print()