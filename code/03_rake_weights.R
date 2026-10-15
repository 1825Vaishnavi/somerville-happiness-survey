library(tidyverse)
library(survey)

survey  <- read_rds("data/clean/survey_clean.rds")
targets <- read_csv("data/clean/acs_targets.csv", show_col_types = FALSE)
waves   <- c(2011, 2013, 2015, 2017, 2019, 2021, 2023, 2025)

# Build the target counts for one variable
# (people who skipped the question keep their own share)
make_margin <- function(d, var, tg) {
  n          <- nrow(d)
  miss_lvls  <- setdiff(unique(d[[var]]), tg$category)
  miss_share <- mean(d[[var]] %in% miss_lvls)
  pop <- bind_rows(
    tibble(cat = tg$category, Freq = tg$acs_share * (1 - miss_share) * n),
    tibble(cat = miss_lvls,   Freq = map_dbl(miss_lvls, ~ sum(d[[var]] == .x)))
  )
  names(pop)[1] <- var
  as.data.frame(pop)
}

# Rake one wave
rake_wave <- function(w) {
  d    <- survey |> filter(Year == w) |> mutate(w0 = 1)
  vars <- if (w >= 2015) c("age_grp", "gender_grp", "tenure_grp") else c("age_grp", "gender_grp")
  tg   <- targets |> filter(Year == w)
  
  des <- svydesign(ids = ~1, weights = ~w0, data = d)
  r <- rake(des,
            sample.margins     = map(vars, ~ as.formula(paste0("~", .x))),
            population.margins = map(vars, ~ make_margin(d, .x, filter(tg, variable == .x))),
            control = list(maxit = 100))
  r <- trimWeights(r, upper = 5, lower = 0.2)   # cap extreme weights
  d$weight <- weights(r)
  d
}

weighted <- map_dfr(waves, rake_wave)
write_rds(weighted, "data/clean/survey_weighted.rds")

# Check 1: after weighting, survey should match the Census (gap near 0)
check <- weighted |>
  select(Year, weight, age_grp, gender_grp, tenure_grp) |>
  pivot_longer(c(age_grp, gender_grp, tenure_grp), names_to = "variable", values_to = "category") |>
  filter(!category %in% c("Missing", "Other/Missing")) |>
  group_by(Year, variable, category) |> summarise(w = sum(weight), .groups = "drop_last") |>
  mutate(weighted_pct = round(100 * w / sum(w), 1)) |> ungroup() |>
  inner_join(targets |> mutate(acs_pct = round(100 * acs_share, 1)),
             by = c("Year", "variable", "category")) |>
  mutate(gap_after = round(weighted_pct - acs_pct, 1))

cat("\n=== Largest gap AFTER weighting (should be close to 0) ===\n")
print(max(abs(check$gap_after)))

# Check 2: weight quality per wave
diag <- weighted |>
  group_by(Year) |>
  summarise(n = n(),
            min_w = round(min(weight), 2),
            max_w = round(max(weight), 2),
            design_effect = round(n() * sum(weight^2) / sum(weight)^2, 2),
            effective_n = round(n / design_effect))
write_csv(diag, "output/weight_diagnostics.csv")
cat("\n=== Weight diagnostics ===\n")
print(diag)