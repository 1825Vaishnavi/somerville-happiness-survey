library(tidyverse)
d  <- read_rds("data/clean/survey_weighted.rds")
xt <- read_csv("output/crosstabs_long.csv", show_col_types = FALSE)

labels <- tribble(
  ~question,                                   ~Question,
  "Happiness",                                 "Happy (rated 4 or 5)",
  "Life.Satisfaction",                         "Satisfied with life",
  "Somerville.Satisfaction",                   "Satisfied with Somerville",
  "Housing.Condition.Satisfaction",            "Happy with housing condition",
  "Priced.Out.Concern",                        "Very worried about being priced out",
  "Work.Opportunities.Satisfaction",           "Happy with work opportunities",
  "Grocery.Access.Satisfaction",               "Happy with grocery access",
  "Relief.Heat.Satisfaction",                  "Happy with relief from heat",
  "Restaurants.Shops.Businesses.Satisfaction", "Happy with restaurants and shops",
  "Basic.Needs.Satisfaction",                  "Able to meet basic needs",
  "Health.Services.Satisfaction",              "Happy with health services",
  "Public.Spaces.Satisfaction",                "Happy with public spaces",
  "Enjoy.Create.Art.Satisfaction",             "Happy with arts and culture")

ward <- xt |> filter(by == "Ward") |>
  transmute(question, Year, Ward = paste("Ward", group), n, Pct = pct)

city <- map_dfr(labels$question, function(q) {
  cutoff <- if (str_detect(q, "Concern")) 3 else 4
  d |> filter(!is.na(.data[[paste0(q, ".num")]])) |>
    group_by(Year) |>
    summarise(n = n(),
              Pct = round(100 * weighted.mean(.data[[paste0(q, ".num")]] >= cutoff, weight), 1)) |>
    mutate(question = q, Ward = "Citywide")
})

tableau <- bind_rows(ward, city) |>
  left_join(labels, by = "question") |>
  select(Question, Ward, Year, Pct, n)

write_csv(tableau, "output/tableau_ward.csv")
count(tableau, Ward)