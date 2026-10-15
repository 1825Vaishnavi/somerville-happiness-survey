# Somerville Happiness Survey: Nonresponse Correction & Wellbeing Drivers

An independent analysis of the City of Somerville's Happiness Survey (2011–2025): checking who the survey hears from, correcting for nonresponse, and identifying what matters most to the city's least-happy residents.

** [Interactive Tableau dashboard (filterable by ward)](https://public.tableau.com/views/SomervilleHappinessSurveybyWard/Dashboard1)**
**📄 [6-page policy brief (PDF)](brief/)**

*This is an independent analysis of public data, not an official City of Somerville report.*

---

## Key findings

- **The survey under-represents young adults and renters.** In every wave, adults under 35 were under-represented by up to 20 percentage points and renters by up to 15.
- **Weighting closed the gaps.** After raking to Census benchmarks, the survey matched the population within 0.1 point, with design effects of 1.09–1.28.
- **One reported trend was mostly sample mix.** The decline in satisfaction with Somerville was significant unweighted (p = 0.0002) but not after weighting (p = 0.085), and the slope was cut in half.
- **Five drivers matter most for the least-happy residents (2025):** housing condition, worry about being priced out, work opportunities, grocery access, and relief from summer heat, together 77% of modeled importance.
- **Renters face these problems most.** 56% of renters are very worried about being priced out, vs. 19% of owners.

## Data

- **Survey:** [Somerville Happiness Survey Responses](https://data.somervillema.gov/d/wmeh-zuz2), City of Somerville Open Data Portal (12,583 responses, 8 waves)
- **Benchmarks:** U.S. Census Bureau, American Community Survey 1-year estimates for Somerville city, MA: B01001 (sex by age) and B25003 (tenure). The 2025 wave uses 2024 ACS, the newest available.

Data files are not included in this repo. Download them from the links above and save them as:
- `data/raw/survey/happiness_survey_2011_2025.csv`
- `data/raw/census/B01001_[year].csv` and `B25003_[year].csv`

## Methods

| Step | Script | What it does |
|---|---|---|
| 1 | `01_load_clean.R` | Recodes 999 (skipped) to missing, removes under-18s, groups age, gender, and tenure |
| 2 | `02_census_targets.R` | Builds Census targets and measures representation gaps per wave |
| 3 | `03_rake_weights.R` | Rakes each wave (age, gender; tenure from 2015), trims weights, checks design effects |
| 4 | `04_trends.R` | Tests long-running questions for trends, unweighted vs. weighted |
| 5 | `05_drivers_model.R` | Weighted ordinal regression on 37 ratings (Benjamini-Hochberg correction), then Shapley analysis on the top 10 |
| 6 | `06_crosstabs.R` | 161 weighted crosstabs by ward, age, tenure, gender, and income; groups under 30 suppressed |
| 7 | `07_brief_numbers.R` | Key figures for the brief |
| 8 | `08_tableau_data.R` | Prepares the ward-level file for Tableau |

**Tools:** R (tidyverse, survey, MASS, writexl), Tableau Public

## Limitations

- 2013 and 2015 had fewer than 200 responses each, so results for those years are less certain.
- Tenure was not asked in 2011 or 2013, so those waves are weighted on age and gender only.
- The tenure benchmark uses households, while the survey counts adults, which slightly understates renters' share of adults.
- Most service questions were asked only in 2025, so the drivers analysis is a one-year, cross-sectional snapshot. Results show associations, not causes.
- Weighting corrects for age, gender, and tenure only; other differences between respondents and nonrespondents may remain.

## Next steps

- Rerun the drivers model with satisfaction with Somerville as the outcome
- Test the proportional-odds assumption
- Use a population-based tenure benchmark (ACS B25008)

## Author

**Vaishnavi Gajarla**, M.S. Data Analytics Engineering, Northeastern University
