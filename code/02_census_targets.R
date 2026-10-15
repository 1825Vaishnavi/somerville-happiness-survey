library(tidyverse)

survey <- read_rds("data/clean/survey_clean.rds")
waves  <- c(2011, 2013, 2015, 2017, 2019, 2021, 2023, 2025)

# Read one Census file
read_acs <- function(table, wave) {
  d <- read_csv(paste0("data/raw/census/", table, "_", wave, ".csv"),
                col_types = cols(.default = "c"))
  names(d)[1:2] <- c("label", "estimate")
  d |> transmute(label    = str_squish(str_replace_all(label, "\u00a0", " ")),
                 estimate = parse_number(estimate))
}

# 1. Census targets for each wave
get_targets <- function(w) {
  age_sex <- read_acs("B01001", w) |>
    mutate(sex = case_when(label == "Male:" ~ "Man", label == "Female:" ~ "Woman")) |>
    fill(sex) |>
    filter(!is.na(sex), !label %in% c("Male:", "Female:")) |>
    mutate(start = parse_number(label)) |>
    filter(start >= 18) |>
    mutate(age_grp = case_when(start < 35 ~ "18-34", start < 55 ~ "35-54", TRUE ~ "55+"))
  
  age    <- age_sex |> count(category = age_grp, wt = estimate) |> mutate(variable = "age_grp")
  gender <- age_sex |> count(category = sex, wt = estimate)     |> mutate(variable = "gender_grp")
  
  tenure <- read_acs("B25003", w) |>
    mutate(category = case_when(str_detect(label, "Owner") ~ "Own",
                                str_detect(label, "Renter") ~ "Rent")) |>
    filter(!is.na(category)) |>
    count(category, wt = estimate) |>
    mutate(variable = "tenure_grp")
  
  bind_rows(age, gender, tenure) |>
    group_by(variable) |> mutate(acs_share = n / sum(n)) |> ungroup() |>
    transmute(Year = w, variable, category, acs_share)
}

targets <- map_dfr(waves, get_targets)
write_csv(targets, "data/clean/acs_targets.csv")

# 2. Survey shares
sample_shares <- survey |>
  select(Year, age_grp, gender_grp, tenure_grp) |>
  pivot_longer(-Year, names_to = "variable", values_to = "category") |>
  filter(!category %in% c("Missing", "Other/Missing")) |>
  count(Year, variable, category) |>
  group_by(Year, variable) |> mutate(sample_share = n / sum(n)) |> ungroup()

# 3. Gaps (negative = under-represented)
gaps <- targets |>
  inner_join(sample_shares, by = c("Year", "variable", "category")) |>
  mutate(acs_pct    = round(100 * acs_share, 1),
         sample_pct = round(100 * sample_share, 1),
         gap_pts    = round(sample_pct - acs_pct, 1)) |>
  select(Year, variable, category, acs_pct, sample_pct, gap_pts, n)

write_csv(gaps, "output/representation_gaps.csv")
cat("\n=== Most under-represented groups ===\n")
gaps |> arrange(gap_pts) |> head(8) |> print()

# 4. Chart
fig <- gaps |>
  filter((variable == "age_grp" & category == "18-34") |
           (variable == "tenure_grp" & category == "Rent")) |>
  mutate(group = if_else(category == "Rent", "Renters", "Ages 18-34")) |>
  ggplot(aes(Year, gap_pts, color = group)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_line(linewidth = 1) + geom_point(size = 2.5) +
  scale_color_manual(values = c("Renters" = "#0072B2", "Ages 18-34" = "#D55E00")) +
  scale_x_continuous(breaks = waves) +
  labs(title = "How far the survey is from the Census",
       subtitle = "Below zero = fewer survey responses than the real population",
       x = NULL, y = "Gap (percentage points)", color = NULL) +
  theme_minimal(base_size = 13) + theme(legend.position = "top")

ggsave("output/fig_representation_gaps.png", fig, width = 8, height = 5, dpi = 200)
fig

