# -------------------------------
# 05_merge_data.R
# Purpose: Merge Adzuna job data with Census ACS and BLS LAUS state-level data
# Input:
#   data_clean/adzuna_jobs_with_llm_roles.csv
#   data_clean/state_economic_data.csv
#   data_clean/bls_laus_state_avg.csv
# Output:
#   data_clean/final_merged_data.csv
#   output/merge_validation.csv
#   output/unmatched_census_states.csv
#   output/unmatched_bls_states.csv
#   output/state_summary.csv
#   output/role_summary_final.csv
#   output/skill_summary_final.csv
# -------------------------------

library(tidyverse)
library(readr)
library(stringr)

# -------------------------------
# Create folders
# -------------------------------
dir.create("data_clean", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

# -------------------------------
# Read input datasets
# -------------------------------
jobs <- read_csv(
  "data_clean/adzuna_jobs_with_llm_roles.csv",
  show_col_types = FALSE
)

census <- read_csv(
  "data_clean/state_economic_data.csv",
  show_col_types = FALSE
)

bls <- read_csv(
  "data_clean/bls_laus_state_avg.csv",
  show_col_types = FALSE
)

# -------------------------------
# Clean and standardize state columns
# -------------------------------
jobs_clean <- jobs |>
  mutate(
    state = str_squish(state)
  )

census_clean <- census |>
  rename(
    state = state_name
  ) |>
  mutate(
    state = str_squish(state)
  )

bls_clean <- bls |>
  mutate(
    state = str_squish(state)
  )

# -------------------------------
# Merge datasets by state
# -------------------------------
final_data <- jobs_clean |>
  left_join(
    census_clean,
    by = "state"
  ) |>
  left_join(
    bls_clean,
    by = "state",
    suffix = c("_census", "_bls")
  )

# -------------------------------
# Save final merged dataset
# -------------------------------
write_csv(
  final_data,
  "data_clean/final_merged_data.csv"
)

# -------------------------------
# Merge validation summary
# -------------------------------
merge_validation <- final_data |>
  summarize(
    total_rows = n(),
    
    rows_missing_state = sum(is.na(state) | state == ""),
    
    rows_with_census_income = sum(!is.na(median_household_income)),
    rows_missing_census_income = sum(is.na(median_household_income)),
    
    rows_with_poverty_rate = sum(!is.na(poverty_rate)),
    rows_missing_poverty_rate = sum(is.na(poverty_rate)),
    
    rows_with_bls_unemployment = sum(!is.na(avg_unemployment_rate)),
    rows_missing_bls_unemployment = sum(is.na(avg_unemployment_rate)),
    
    rows_with_salary = sum(!is.na(avg_salary)),
    rows_missing_salary = sum(is.na(avg_salary)),
    
    rows_with_keyword_skills = sum(!is.na(skill_count)),
    rows_missing_keyword_skills = sum(is.na(skill_count)),
    
    rows_with_llm_role = sum(!is.na(llm_role_category_clean)),
    rows_missing_llm_role = sum(is.na(llm_role_category_clean)),
    
    rows_with_llm_experience = sum(!is.na(llm_experience_level)),
    rows_missing_llm_experience = sum(is.na(llm_experience_level))
  )

write_csv(
  merge_validation,
  "output/merge_validation.csv"
)

# -------------------------------
# Identify states that did not match Census
# This excludes NA states from Adzuna because they are not real state names
# -------------------------------
unmatched_census_states <- jobs_clean |>
  distinct(state) |>
  filter(!is.na(state), state != "") |>
  anti_join(
    census_clean |> distinct(state),
    by = "state"
  ) |>
  arrange(state)

write_csv(
  unmatched_census_states,
  "output/unmatched_census_states.csv"
)

# -------------------------------
# Identify states that did not match BLS
# This may include states missing from BLS output, such as Wyoming
# -------------------------------
unmatched_bls_states <- jobs_clean |>
  distinct(state) |>
  filter(!is.na(state), state != "") |>
  anti_join(
    bls_clean |> distinct(state),
    by = "state"
  ) |>
  arrange(state)

write_csv(
  unmatched_bls_states,
  "output/unmatched_bls_states.csv"
)

# -------------------------------
# State-level summary for dashboard
# Note: postings with NA state are excluded from state-level summary
# -------------------------------
state_summary <- final_data |>
  filter(!is.na(state), state != "") |>
  group_by(state) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    
    median_household_income = first(na.omit(median_household_income)),
    poverty_rate = first(na.omit(poverty_rate)),
    
    avg_unemployment_rate = first(na.omit(avg_unemployment_rate)),
    latest_unemployment_rate = first(na.omit(latest_unemployment_rate)),
    
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  state_summary,
  "output/state_summary.csv"
)

# -------------------------------
# Role-level summary for dashboard
# Uses cleaned LLM role category
# -------------------------------
role_summary_final <- final_data |>
  group_by(llm_role_category_clean) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  role_summary_final,
  "output/role_summary_final.csv"
)

# -------------------------------
# Skill-level summary for dashboard
# Uses keyword-based skill extraction from full dataset
# -------------------------------
skill_summary_final <- final_data |>
  select(
    avg_salary,
    starts_with("skill_")
  ) |>
  select(-skill_count) |>
  pivot_longer(
    cols = starts_with("skill_"),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  filter(has_skill == TRUE) |>
  group_by(skill) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  skill_summary_final,
  "output/skill_summary_final.csv"
)

# -------------------------------
# Preview results
# -------------------------------
print(dim(final_data))
print(merge_validation)

cat("\nUnmatched Census states:\n")
print(unmatched_census_states)

cat("\nUnmatched BLS states:\n")
print(unmatched_bls_states)

cat("\nTop states by postings:\n")
print(state_summary |> head(20))

cat("\nRole summary:\n")
print(role_summary_final)

cat("\nSkill summary:\n")
print(skill_summary_final)

print("Data merge completed successfully.")