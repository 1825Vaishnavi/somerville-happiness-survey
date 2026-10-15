library(tidyverse)
library(survey)

d25 <- read_rds("data/clean/survey_weighted.rds") |>
  filter(Year == 2025, !is.na(Happiness.num), !is.na(Life.Satisfaction.num))

# Pick the service ratings
exclude <- c("Happiness.num", "Life.Satisfaction.num", "Somerville.Satisfaction.num",
             "Repurpose.Street.Parking.num", "Encourage.Commercial.Development.num")
items <- d25 |> select(ends_with(".num")) |> select(-any_of(exclude)) |> names()
items <- items[map_lgl(items, ~ mean(!is.na(d25[[.x]])) >= 0.6)]   # answered by 60%+

# Flip "Concern" questions so higher = better
concern <- str_subset(items, "Concern")
d25 <- d25 |> mutate(across(all_of(concern), ~ 6 - .x))

# Low-happiness group
low <- d25 |> filter(Happiness.num <= 3) |>
  mutate(life = factor(Life.Satisfaction.num), weight = weight / mean(weight))
cat("Low-happiness group:", nrow(low), "people |", length(items), "ratings tested\n")

# ---- PART A: rank every rating (weighted ordinal regression) ----
rank_one <- function(x) {
  dd  <- low |> filter(!is.na(.data[[x]])) |> mutate(life = droplevels(life))
  des <- svydesign(ids = ~1, weights = ~weight, data = dd)
  m   <- svyolr(as.formula(paste("life ~", x, "+ age_grp + gender_grp + tenure_grp")), design = des)
  b <- coef(m)[x]; se <- sqrt(diag(vcov(m)))[x]
  tibble(item = x, odds_ratio = round(exp(b), 2), p = 2 * pnorm(-abs(b / se)), n = nrow(dd))
}

ranking <- map_dfr(items, rank_one) |>
  mutate(p_adj = round(p.adjust(p, "BH"), 4), p = round(p, 4)) |>
  arrange(desc(odds_ratio)) |>
  mutate(rank = row_number(), item = str_remove(item, "\\.num$"))
write_csv(ranking, "output/driver_ranking_all.csv")
cat("\n=== PART A: all ratings ranked ===\n"); print(ranking, n = Inf)

# ---- PART B: Shapley analysis on the top 10 ----
top <- paste0(head(ranking$item, 10), ".num")
cc  <- low |> select(life, weight, all_of(top)) |> drop_na() |>
  mutate(life = droplevels(life), weight = weight / mean(weight))
cat("\nShapley sample (answered all 10):", nrow(cc), "people\n")

null_dev <- MASS::polr(life ~ 1, data = cc, weights = weight)$deviance
fit_r2 <- function(vars) {
  if (length(vars) == 0) return(0)
  m <- suppressWarnings(MASS::polr(as.formula(paste("life ~", paste(vars, collapse = "+"))),
                                   data = cc, weights = weight))
  1 - m$deviance / null_dev
}

k <- length(top); bits <- 2^(0:(k - 1)); masks <- 0:(2^k - 1)
cat("Fitting", length(masks), "models (takes 1-2 minutes)...\n")
r2   <- map_dbl(masks, function(m) fit_r2(top[bitwAnd(m, bits) > 0]))
size <- map_int(masks, ~ sum(bitwAnd(.x, bits) > 0))

shap <- map_dbl(1:k, function(j) {
  without <- masks[bitwAnd(masks, bits[j]) == 0]
  s <- size[without + 1]
  sum(factorial(s) * factorial(k - s - 1) / factorial(k) *
        (r2[without + bits[j] + 1] - r2[without + 1]))
})

shapley <- tibble(item = str_remove(top, "\\.num$"), shapley = shap) |>
  mutate(share_pct = round(100 * shapley / sum(shapley), 1)) |>
  arrange(desc(shapley))
write_csv(shapley, "output/driver_shapley.csv")
cat("\nTotal pseudo R-squared (all 10):", round(r2[length(r2)], 3), "\n")
cat("\n=== PART B: Shapley importance ===\n"); print(shapley)

# Chart
fig <- shapley |>
  mutate(item = str_replace_all(item, "\\.", " "),
         top5 = if_else(row_number() <= 5, "Top 5 driver", "Other")) |>
  ggplot(aes(share_pct, reorder(item, share_pct), fill = top5)) +
  geom_col() +
  geom_text(aes(label = paste0(share_pct, "%")), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("Top 5 driver" = "#0072B2", "Other" = "#BBBBBB")) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "What drives life satisfaction for Somerville's least-happy residents",
       subtitle = "Share of explained life satisfaction, 2025 (Shapley analysis)",
       x = "Share of importance (%)", y = NULL, fill = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "top")
ggsave("output/fig_drivers_shapley.png", fig, width = 9, height = 6, dpi = 200)
fig