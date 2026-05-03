# -------------------------------
# 07_eda.R
# Purpose: Exploratory data analysis for final merged dataset
# Input:
#   data_clean/final_merged_data.csv
# Output:
#   output/eda_overview_summary.csv
#   output/eda_role_salary_summary.csv
#   output/eda_skill_salary_summary.csv
#   output/eda_experience_salary_summary.csv
#   output/eda_state_salary_summary.csv
#   output/eda_skill_by_role.csv
#   output/eda_role_by_experience.csv
#   output/eda_state_labor_context.csv
#   output/eda_correlation_summary.csv
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
# Read final merged data
# -------------------------------
final_data <- read_csv(
  "data_clean/final_merged_data.csv",
  show_col_types = FALSE
)

# -------------------------------
# Check required input
# -------------------------------
required_cols <- c(
  "avg_salary",
  "state",
  "skill_count",
  "llm_role_category_clean",
  "llm_experience_level",
  "median_household_income",
  "poverty_rate",
  "avg_unemployment_rate"
)

missing_required_cols <- setdiff(required_cols, names(final_data))

if (length(missing_required_cols) > 0) {
  stop(
    paste(
      "Missing required columns:",
      paste(missing_required_cols, collapse = ", ")
    )
  )
}

# -------------------------------
# 1. Overall EDA overview
# -------------------------------
eda_overview_summary <- final_data |>
  summarize(
    total_postings = n(),
    unique_companies = n_distinct(company, na.rm = TRUE),
    unique_states = n_distinct(state, na.rm = TRUE),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    min_salary = min(avg_salary, na.rm = TRUE),
    max_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    median_skill_count = median(skill_count, na.rm = TRUE),
    rows_with_state = sum(!is.na(state) & state != ""),
    rows_missing_state = sum(is.na(state) | state == ""),
    rows_with_census = sum(!is.na(median_household_income)),
    rows_with_bls = sum(!is.na(avg_unemployment_rate))
  )

write_csv(
  eda_overview_summary,
  "output/eda_overview_summary.csv"
)

# -------------------------------
# 2. Salary by LLM role category
# -------------------------------
eda_role_salary_summary <- final_data |>
  group_by(llm_role_category_clean) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    min_salary = min(avg_salary, na.rm = TRUE),
    max_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_salary))

write_csv(
  eda_role_salary_summary,
  "output/eda_role_salary_summary.csv"
)

# -------------------------------
# 3. Salary by skill
# -------------------------------
skill_columns <- names(final_data) |>
  str_subset("^skill_") |>
  setdiff("skill_count")

eda_skill_salary_summary <- final_data |>
  select(avg_salary, all_of(skill_columns)) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  filter(has_skill == TRUE) |>
  group_by(skill) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    min_salary = min(avg_salary, na.rm = TRUE),
    max_salary = max(avg_salary, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_salary))

write_csv(
  eda_skill_salary_summary,
  "output/eda_skill_salary_summary.csv"
)

# -------------------------------
# 4. Salary by LLM experience level
# -------------------------------
eda_experience_salary_summary <- final_data |>
  group_by(llm_experience_level) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    min_salary = min(avg_salary, na.rm = TRUE),
    max_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_salary))

write_csv(
  eda_experience_salary_summary,
  "output/eda_experience_salary_summary.csv"
)

# -------------------------------
# 5. State-level salary and posting summary
# -------------------------------
eda_state_salary_summary <- final_data |>
  filter(!is.na(state), state != "") |>
  group_by(state) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    median_household_income = first(na.omit(median_household_income)),
    poverty_rate = first(na.omit(poverty_rate)),
    avg_unemployment_rate = first(na.omit(avg_unemployment_rate)),
    latest_unemployment_rate = first(na.omit(latest_unemployment_rate)),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_state_salary_summary,
  "output/eda_state_salary_summary.csv"
)

# -------------------------------
# 6. Skill frequency by role category
# -------------------------------
eda_skill_by_role <- final_data |>
  select(
    llm_role_category_clean,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  group_by(llm_role_category_clean, skill) |>
  summarize(
    postings_with_skill = sum(has_skill == TRUE, na.rm = TRUE),
    total_role_postings = n(),
    skill_share = postings_with_skill / total_role_postings,
    .groups = "drop"
  ) |>
  arrange(llm_role_category_clean, desc(postings_with_skill))

write_csv(
  eda_skill_by_role,
  "output/eda_skill_by_role.csv"
)

# -------------------------------
# 7. Role by experience level
# -------------------------------
eda_role_by_experience <- final_data |>
  count(
    llm_role_category_clean,
    llm_experience_level,
    sort = TRUE
  ) |>
  group_by(llm_role_category_clean) |>
  mutate(
    role_total = sum(n),
    experience_share = n / role_total
  ) |>
  ungroup()

write_csv(
  eda_role_by_experience,
  "output/eda_role_by_experience.csv"
)

# -------------------------------
# 8. State labor and economic context
# -------------------------------
eda_state_labor_context <- final_data |>
  filter(!is.na(state), state != "") |>
  group_by(state) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    median_household_income = first(na.omit(median_household_income)),
    poverty_rate = first(na.omit(poverty_rate)),
    avg_unemployment_rate = first(na.omit(avg_unemployment_rate)),
    latest_unemployment_rate = first(na.omit(latest_unemployment_rate)),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_state_labor_context,
  "output/eda_state_labor_context.csv"
)

# -------------------------------
# 9. Correlation summary
# Only uses rows with complete numeric context variables
# -------------------------------
correlation_data <- final_data |>
  select(
    avg_salary,
    skill_count,
    median_household_income,
    poverty_rate,
    avg_unemployment_rate
  )

eda_correlation_summary <- tibble(
  variable = c(
    "skill_count",
    "median_household_income",
    "poverty_rate",
    "avg_unemployment_rate"
  ),
  correlation_with_avg_salary = c(
    cor(correlation_data$avg_salary, correlation_data$skill_count, use = "complete.obs"),
    cor(correlation_data$avg_salary, correlation_data$median_household_income, use = "complete.obs"),
    cor(correlation_data$avg_salary, correlation_data$poverty_rate, use = "complete.obs"),
    cor(correlation_data$avg_salary, correlation_data$avg_unemployment_rate, use = "complete.obs")
  )
) |>
  arrange(desc(abs(correlation_with_avg_salary)))

write_csv(
  eda_correlation_summary,
  "output/eda_correlation_summary.csv"
)

# -------------------------------
# 10. Top companies by postings
# -------------------------------
eda_company_summary <- final_data |>
  count(company, sort = TRUE) |>
  filter(!is.na(company), company != "") |>
  rename(postings = n)

write_csv(
  eda_company_summary,
  "output/eda_company_summary.csv"
)

# -------------------------------
# 11. Search query summary
# -------------------------------
eda_search_query_summary <- final_data |>
  group_by(search_query) |>
  summarize(
    postings = n(),
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_search_query_summary,
  "output/eda_search_query_summary.csv"
)

# -------------------------------
# Print key EDA outputs
# -------------------------------
cat("\nEDA overview summary:\n")
print(eda_overview_summary)

cat("\nSalary by role category:\n")
print(eda_role_salary_summary)

cat("\nSalary by skill:\n")
print(eda_skill_salary_summary)

cat("\nSalary by experience level:\n")
print(eda_experience_salary_summary)

cat("\nTop states by postings:\n")
print(eda_state_salary_summary |> head(20))

cat("\nCorrelation summary:\n")
print(eda_correlation_summary)

cat("\nSearch query summary:\n")
print(eda_search_query_summary)

print("EDA completed successfully.")