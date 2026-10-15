library(tidyverse)
library(survey)

d <- read_rds("data/clean/survey_weighted.rds")

# All rating questions asked in at least 3 waves
outcomes <- names(d)[str_ends(names(d), "\\.num")]
n_waves  <- map_int(outcomes, ~ d |> filter(!is.na(.data[[.x]])) |> distinct(Year) |> nrow())
outcomes <- outcomes[n_waves >= 3]
cat("Testing", length(outcomes), "questions\n")

des <- svydesign(ids = ~1, weights = ~weight, data = d)

# Trend test: unweighted vs weighted (change per 10 years)
trend_test <- function(y) {
  f <- as.formula(paste(y, "~ Year"))
  u <- summary(lm(f, data = d))$coefficients["Year", ]
  w <- summary(svyglm(f, design = des))$coefficients["Year", ]
  tibble(outcome = str_remove(y, "\\.num$"),
         change_unweighted = round(u[1] * 10, 3), p_unweighted = round(u[4], 4),
         change_weighted   = round(w[1] * 10, 3), p_weighted   = round(w[4], 4))
}

results <- map_dfr(outcomes, trend_test) |>
  mutate(status = case_when(
    p_unweighted < .05 & p_weighted >= .05 ~ "Fake trend (sample mix)",
    p_unweighted < .05 & p_weighted <  .05 &
      sign(change_unweighted) != sign(change_weighted) ~ "Trend reverses",
    p_unweighted >= .05 & p_weighted < .05 ~ "Hidden trend (appears)",
    p_unweighted < .05 ~ "Real trend",
    TRUE ~ "No trend"))

write_csv(results, "output/trend_tests.csv")
cat("\n=== Summary ===\n");          print(count(results, status))
cat("\n=== Trends that changed ===\n")
results |> filter(status %in% c("Fake trend (sample mix)", "Trend reverses",
                                "Hidden trend (appears)")) |> print(n = Inf)

# Chart: yearly averages, unweighted vs weighted
means <- map_dfr(outcomes, function(y) {
  d |> filter(!is.na(.data[[y]])) |> group_by(Year) |>
    summarise(Unweighted = mean(.data[[y]]),
              Weighted   = weighted.mean(.data[[y]], weight)) |>
    mutate(outcome = str_remove(y, "\\.num$"))
})
write_csv(means, "output/yearly_means.csv")

show <- c("Happiness", "Life.Satisfaction",
          results$outcome[results$status != "No trend" & results$status != "Real trend"])

fig <- means |>
  filter(outcome %in% show) |>
  pivot_longer(c(Unweighted, Weighted), names_to = "type", values_to = "mean") |>
  ggplot(aes(Year, mean, color = type)) +
  geom_line(linewidth = 1) + geom_point(size = 2) +
  facet_wrap(~ outcome, scales = "free_y") +
  scale_color_manual(values = c("Unweighted" = "#999999", "Weighted" = "#0072B2")) +
  labs(title = "Trends before and after weighting",
       subtitle = "Gray = raw survey, blue = weighted to match the Census",
       x = NULL, y = "Average rating (1-5)", color = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "top")

ggsave("output/fig_trends_weighted.png", fig, width = 11, height = 7, dpi = 200)
fig