# -------------------------------
# 06_validate_data.R
# Purpose: Validate final merged dataset before EDA and dashboard
# Input:
#   data_clean/final_merged_data.csv
# Output:
#   output/data_validation_summary.csv
#   output/missing_value_summary.csv
#   output/salary_validation_summary.csv
#   output/state_merge_coverage.csv
#   output/duplicate_job_check.csv
#   output/skill_validation_summary.csv
#   output/llm_validation_summary.csv
# -------------------------------

# -------------------------------
# Load required libraries
# -------------------------------
library(tidyverse)
library(readr)
library(stringr)

# -------------------------------
# Create folders
# -------------------------------
dir.create("output", showWarnings = FALSE)

# -------------------------------
# Check required input file
# -------------------------------
if (!file.exists("data_clean/final_merged_data.csv")) {
  stop("Missing data_clean/final_merged_data.csv. Please rerun scripts/05_merge_data.R first.")
}

# -------------------------------
# Read final merged data
# -------------------------------
final_data <- read_csv(
  "data_clean/final_merged_data.csv",
  show_col_types = FALSE
)

# -------------------------------
# Basic dataset validation
# -------------------------------
data_validation_summary <- tibble(
  metric = c(
    "total_rows",
    "total_columns",
    "unique_job_ids",
    "duplicate_job_ids",
    "rows_missing_job_id",
    "rows_missing_state",
    "rows_with_salary",
    "rows_missing_salary",
    "rows_with_census_income",
    "rows_missing_census_income",
    "rows_with_bls_unemployment",
    "rows_missing_bls_unemployment",
    "rows_with_keyword_skills",
    "rows_with_llm_role",
    "rows_with_llm_experience"
  ),
  value = c(
    nrow(final_data),
    ncol(final_data),
    n_distinct(final_data$job_id, na.rm = TRUE),
    sum(duplicated(final_data$job_id[!is.na(final_data$job_id)])),
    sum(is.na(final_data$job_id) | final_data$job_id == ""),
    sum(is.na(final_data$state) | final_data$state == ""),
    sum(!is.na(final_data$avg_salary)),
    sum(is.na(final_data$avg_salary)),
    sum(!is.na(final_data$median_household_income)),
    sum(is.na(final_data$median_household_income)),
    sum(!is.na(final_data$avg_unemployment_rate)),
    sum(is.na(final_data$avg_unemployment_rate)),
    sum(!is.na(final_data$skill_count)),
    sum(!is.na(final_data$llm_role_category_clean)),
    sum(!is.na(final_data$llm_experience_level))
  )
)

write_csv(
  data_validation_summary,
  "output/data_validation_summary.csv"
)

# -------------------------------
# Missing value summary by column
# -------------------------------
missing_value_summary <- final_data |>
  summarize(
    across(
      everything(),
      ~ {
        if (is.character(.x)) {
          sum(is.na(.x) | str_squish(.x) == "")
        } else {
          sum(is.na(.x))
        }
      }
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "column",
    values_to = "missing_count"
  ) |>
  mutate(
    total_rows = nrow(final_data),
    missing_rate = missing_count / total_rows
  ) |>
  arrange(desc(missing_count))

write_csv(
  missing_value_summary,
  "output/missing_value_summary.csv"
)

# -------------------------------
# Duplicate job check
# -------------------------------
duplicate_job_check <- final_data |>
  filter(!is.na(job_id), job_id != "") |>
  count(job_id, sort = TRUE) |>
  filter(n > 1)

write_csv(
  duplicate_job_check,
  "output/duplicate_job_check.csv"
)

# -------------------------------
# Salary validation
# -------------------------------
salary_validation_summary <- final_data |>
  summarize(
    total_rows = n(),
    rows_with_avg_salary = sum(!is.na(avg_salary)),
    rows_missing_avg_salary = sum(is.na(avg_salary)),
    min_avg_salary = min(avg_salary, na.rm = TRUE),
    q1_avg_salary = quantile(avg_salary, 0.25, na.rm = TRUE),
    median_avg_salary = median(avg_salary, na.rm = TRUE),
    mean_avg_salary = mean(avg_salary, na.rm = TRUE),
    q3_avg_salary = quantile(avg_salary, 0.75, na.rm = TRUE),
    max_avg_salary = max(avg_salary, na.rm = TRUE),
    rows_salary_below_20000 = sum(avg_salary < 20000, na.rm = TRUE),
    rows_salary_above_300000 = sum(avg_salary > 300000, na.rm = TRUE),
    rows_min_salary_greater_than_max_salary = sum(min_salary > max_salary, na.rm = TRUE)
  )

write_csv(
  salary_validation_summary,
  "output/salary_validation_summary.csv"
)

# -------------------------------
# Save potentially unusual salary rows for review
# -------------------------------
unusual_salary_rows <- final_data |>
  filter(
    avg_salary < 20000 |
      avg_salary > 300000 |
      min_salary > max_salary
  ) |>
  select(
    job_id,
    title,
    company,
    search_query,
    location,
    state,
    min_salary,
    max_salary,
    avg_salary,
    redirect_url
  )

write_csv(
  unusual_salary_rows,
  "output/unusual_salary_rows.csv"
)

# -------------------------------
# State merge coverage
# -------------------------------
state_merge_coverage <- final_data |>
  mutate(
    has_state = !is.na(state) & state != "",
    has_census = !is.na(median_household_income),
    has_bls = !is.na(avg_unemployment_rate)
  ) |>
  summarize(
    total_rows = n(),
    rows_with_state = sum(has_state),
    rows_missing_state = sum(!has_state),
    rows_with_census = sum(has_census),
    rows_missing_census = sum(!has_census),
    rows_with_bls = sum(has_bls),
    rows_missing_bls = sum(!has_bls),
    state_coverage_rate = rows_with_state / total_rows,
    census_merge_rate = rows_with_census / total_rows,
    bls_merge_rate = rows_with_bls / total_rows
  )

write_csv(
  state_merge_coverage,
  "output/state_merge_coverage.csv"
)

# -------------------------------
# State-level missing merge detail
# -------------------------------
state_merge_detail <- final_data |>
  group_by(state) |>
  summarize(
    postings = n(),
    has_census_income = any(!is.na(median_household_income)),
    has_bls_unemployment = any(!is.na(avg_unemployment_rate)),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  state_merge_detail,
  "output/state_merge_detail.csv"
)

# -------------------------------
# Skill variable validation
# -------------------------------
skill_columns <- names(final_data) |>
  str_subset("^skill_") |>
  setdiff("skill_count")

skill_validation_summary <- final_data |>
  summarize(
    across(
      all_of(skill_columns),
      ~ sum(.x == TRUE, na.rm = TRUE)
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "skill",
    values_to = "true_count"
  ) |>
  mutate(
    total_rows = nrow(final_data),
    true_rate = true_count / total_rows
  ) |>
  arrange(desc(true_count))

write_csv(
  skill_validation_summary,
  "output/skill_validation_summary.csv"
)

# -------------------------------
# Skill count validation
# -------------------------------
skill_count_validation <- final_data |>
  summarize(
    total_rows = n(),
    min_skill_count = min(skill_count, na.rm = TRUE),
    q1_skill_count = quantile(skill_count, 0.25, na.rm = TRUE),
    median_skill_count = median(skill_count, na.rm = TRUE),
    mean_skill_count = mean(skill_count, na.rm = TRUE),
    q3_skill_count = quantile(skill_count, 0.75, na.rm = TRUE),
    max_skill_count = max(skill_count, na.rm = TRUE),
    rows_with_zero_skills = sum(skill_count == 0, na.rm = TRUE)
  )

write_csv(
  skill_count_validation,
  "output/skill_count_validation.csv"
)

# -------------------------------
# LLM validation
# -------------------------------
llm_validation_summary <- final_data |>
  summarize(
    total_rows = n(),
    rows_with_llm_role = sum(!is.na(llm_role_category_clean)),
    rows_missing_llm_role = sum(is.na(llm_role_category_clean)),
    rows_with_llm_experience = sum(!is.na(llm_experience_level)),
    rows_missing_llm_experience = sum(is.na(llm_experience_level)),
    llm_role_coverage_rate = rows_with_llm_role / total_rows,
    llm_experience_coverage_rate = rows_with_llm_experience / total_rows
  )

write_csv(
  llm_validation_summary,
  "output/llm_validation_summary.csv"
)

# -------------------------------
# LLM role category distribution
# -------------------------------
llm_role_distribution <- final_data |>
  count(llm_role_category_clean, sort = TRUE) |>
  mutate(
    share = n / sum(n)
  )

write_csv(
  llm_role_distribution,
  "output/llm_role_distribution.csv"
)

# -------------------------------
# LLM experience distribution
# -------------------------------
llm_experience_distribution <- final_data |>
  count(llm_experience_level, sort = TRUE) |>
  mutate(
    share = n / sum(n)
  )

write_csv(
  llm_experience_distribution,
  "output/llm_experience_distribution.csv"
)

# -------------------------------
# Final validation status
# -------------------------------
validation_status <- tibble(
  check = c(
    "final_dataset_exists",
    "has_rows",
    "no_duplicate_job_ids",
    "salary_available",
    "state_available_for_most_rows",
    "census_merge_successful",
    "bls_merge_mostly_successful",
    "keyword_skills_available",
    "llm_roles_available"
  ),
  status = c(
    file.exists("data_clean/final_merged_data.csv"),
    nrow(final_data) > 0,
    nrow(duplicate_job_check) == 0,
    sum(!is.na(final_data$avg_salary)) == nrow(final_data),
    state_merge_coverage$state_coverage_rate >= 0.90,
    state_merge_coverage$census_merge_rate >= 0.90,
    state_merge_coverage$bls_merge_rate >= 0.90,
    length(skill_columns) > 0,
    llm_validation_summary$llm_role_coverage_rate == 1
  )
)

write_csv(
  validation_status,
  "output/validation_status.csv"
)

# -------------------------------
# Print key outputs
# -------------------------------
cat("\nDataset validation summary:\n")
print(data_validation_summary)

cat("\nSalary validation summary:\n")
print(salary_validation_summary)

cat("\nState merge coverage:\n")
print(state_merge_coverage)

cat("\nSkill count validation:\n")
print(skill_count_validation)

cat("\nLLM validation summary:\n")
print(llm_validation_summary)

cat("\nValidation status:\n")
print(validation_status)

print("Data validation completed successfully.")