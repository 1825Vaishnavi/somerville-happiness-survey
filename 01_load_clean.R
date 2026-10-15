
library(tidyverse)

survey <- read_csv("data/raw/survey/happiness_survey_2011_2025.csv",
                   show_col_types = FALSE)

# 1. Turn 999 codes into missing (NA)
survey <- survey |>
  mutate(across(where(is.numeric) & !any_of(c("ID", "Year")),
                ~ na_if(.x, 999)))

# 2. Remove people under 18
survey <- survey |>
  filter(is.na(Age) | Age != "17 or under")

# 3. Create groups that match the Census
survey <- survey |>
  mutate(
    age_grp = case_when(
      Age %in% c("18 to 24", "25 to 34")               ~ "18-34",
      Age %in% c("35 to 44", "45 to 54")               ~ "35-54",
      Age %in% c("55 to 64", "65 to 74", "75 or over") ~ "55+",
      TRUE                                             ~ "Missing"),
    gender_grp = case_when(
      Gender == "Man"   ~ "Man",
      Gender == "Woman" ~ "Woman",
      TRUE              ~ "Other/Missing"),
    tenure_grp = case_when(
      Housing.Status == "Rent" ~ "Rent",
      Housing.Status == "Own"  ~ "Own",
      TRUE                     ~ "Other/Missing"),
    Ward = factor(Ward)
  )

# 4. Save
dir.create("data/clean", showWarnings = FALSE)
write_rds(survey, "data/clean/survey_clean.rds")
cat("\nSaved data/clean/survey_clean.rds with", nrow(survey), "rows\n")