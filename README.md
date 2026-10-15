# Who Does the Somerville Happiness Survey Hear From?

Every two years, the City of Somerville asks residents how happy they are and how they feel about life in the city. I wanted to know two things: does the survey hear from everyone fairly, and what matters most to the residents who are least happy?

This project uses all eight waves of the survey, from 2011 to 2025.

 **[Explore the interactive dashboard](https://public.tableau.com/views/SomervilleHappinessSurveybyWard/Dashboard1)** (you can filter by ward)
 **[Read the 6-page brief](brief/)**

*This is my own independent analysis of public data. It's not an official City of Somerville report.*

---

## What I found

**The survey doesn't hear enough from young adults and renters.** In every survey year, people under 35 and renters answered less often than their real share of the city. The gap was as big as 20 percentage points for young adults and 15 for renters.

**Weighting fixed most of that.** I adjusted the responses to match Census numbers by age, gender, and renting. After that, the survey matched the city within 0.1 point.

**One "decline" was mostly about who answered.** In the raw data, people seemed to like Somerville less over time. After weighting, the drop was half as big and could have been chance. The mix of people answering had changed, not just their opinions.

**For the least happy residents, five things mattered most:** the condition of their housing, worry about being priced out, work opportunities, access to groceries, and relief from summer heat. Together, they made up 77% of what the model could explain.

**Renters carry most of the weight.** 56% of renters are very worried about being priced out of Somerville, compared to 19% of homeowners.

## How I did it

I worked in R and built the analysis in eight steps, one script each:

1. **`01_load_clean.R`** cleans the raw survey: skipped answers coded as 999 become missing, under-18s are removed, and age, gender, and renting are grouped to match the Census.
2. **`02_census_targets.R`** compares each survey year to the Census to see who's missing.
3. **`03_rake_weights.R`** weights each year (by age and gender, plus renting from 2015, since it wasn't asked before that) and checks that no single answer counts too much.
4. **`04_trends.R`** tests whether trends over time still hold after weighting.
5. **`05_drivers_model.R`** uses weighted ordinal regression to rank 37 city ratings, corrects for testing so many at once, and uses Shapley analysis to fairly split credit among the top 10.
6. **`06_crosstabs.R`** builds 161 weighted tables by ward, age, renting, gender, and income. Groups with fewer than 30 responses are hidden.
7. **`07_brief_numbers.R`** pulls the key numbers for the brief.
8. **`08_tableau_data.R`** prepares the data for the Tableau dashboard.

## The data

- **Survey:** [Somerville Happiness Survey Responses](https://data.somervillema.gov/d/wmeh-zuz2) from the City's Open Data Portal (12,583 responses)
- **Census:** American Community Survey 1-year estimates for Somerville, tables B01001 (age and sex) and B25003 (renting vs. owning). For the 2025 survey, I used 2024 Census data, since that's the newest available.

The data files aren't in this repo. If you'd like to rerun the analysis, download them from the links above and save them in a `data/raw/` folder as described at the top of each script.

## What to keep in mind

- 2013 and 2015 had fewer than 200 responses each, so I'd be careful reading too much into those years.
- The survey didn't ask about renting in 2011 or 2013, so those years are only weighted by age and gender.
- The Census renting numbers count households, while the survey counts adults. That probably undercounts renters a little.
- Most city service questions were only asked in 2025, so the drivers analysis is a snapshot of one year. It shows what goes together with life satisfaction, not what causes it.
- Weighting only fixes differences I could measure. People who skip the survey may still differ in other ways.

## What I'd do next

After sharing this project, I got a great suggestion: use satisfaction with Somerville as the outcome instead of life satisfaction, since it's more directly tied to city services. That's my next step. I'd also like to test one of the model's key assumptions (proportional odds) and use a better Census benchmark for renters.

## About me

I'm Vaishnavi Gajarla, a Master's student in Data Analytics Engineering at Northeastern University. I'm interested in using data to help cities make better decisions. Feel free to reach out!

