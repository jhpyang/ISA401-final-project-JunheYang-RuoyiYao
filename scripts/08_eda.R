# -------------------------------
# 08_eda.R
# Purpose:
#   Exploratory data analysis for enhanced final dataset
#
# Important:
#   Do NOT create summary columns named avg_salary inside summarize().
#   Use avg_posting_salary and median_posting_salary instead.
#
# Input:
#   data_clean/final_merged_data_enhanced.csv
#
# Output:
#   EDA summary files for Tableau / Power BI dashboard
# -------------------------------

# -------------------------------
# Set working directory
# -------------------------------
setwd("E:/ISA401 Document/ISA401-final-project-JunheYang-RuoyiYao")

# -------------------------------
# Load required libraries
# -------------------------------
library(tidyverse)
library(readr)
library(stringr)

# -------------------------------
# Create output folder
# -------------------------------
dir.create("output", showWarnings = FALSE)

# -------------------------------
# Read enhanced final dataset
# -------------------------------
final_data <- read_csv(
  "data_clean/final_merged_data_enhanced.csv",
  show_col_types = FALSE
)

# -------------------------------
# Check required columns
# -------------------------------
required_cols <- c(
  "job_id",
  "company",
  "title",
  "job_title_clean",
  "job_title_group",
  "company_industry",
  "avg_salary",
  "state",
  "skill_count",
  "llm_role_category_clean",
  "llm_experience_level",
  "median_household_income",
  "poverty_rate",
  "avg_unemployment_rate",
  "latest_unemployment_rate"
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
# Identify skill columns
# -------------------------------
skill_columns <- names(final_data) |>
  str_subset("^skill_") |>
  setdiff("skill_count")

# -------------------------------
# Helper function for first non-missing value
# -------------------------------
first_non_missing <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA)
  } else {
    return(x[1])
  }
}

# -------------------------------
# Skill label lookup
# -------------------------------
skill_label_lookup <- tibble(
  skill = skill_columns,
  skill_label = skill_columns |>
    str_remove("^skill_") |>
    str_replace_all("_", " ") |>
    str_to_title()
)

write_csv(
  skill_label_lookup,
  "output/skill_label_lookup.csv"
)

# -------------------------------
# 1. Overall EDA overview
# -------------------------------
eda_overview_summary <- final_data |>
  summarize(
    total_postings = n(),
    unique_companies = n_distinct(company, na.rm = TRUE),
    unique_states = n_distinct(state, na.rm = TRUE),
    unique_industries = n_distinct(company_industry, na.rm = TRUE),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
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
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_posting_salary))

write_csv(
  eda_role_salary_summary,
  "output/eda_role_salary_summary.csv"
)

# -------------------------------
# 3. Salary by cleaned job title group
# -------------------------------
eda_title_group_salary_summary <- final_data |>
  group_by(job_title_group) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_posting_salary))

write_csv(
  eda_title_group_salary_summary,
  "output/eda_title_group_salary_summary.csv"
)

# -------------------------------
# 4. Skill frequency and salary summary
# -------------------------------
eda_skill_salary_summary <- final_data |>
  select(
    job_id,
    avg_salary,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  mutate(
    has_skill = as.integer(has_skill)
  ) |>
  left_join(
    skill_label_lookup,
    by = "skill"
  ) |>
  filter(has_skill == 1) |>
  group_by(skill, skill_label) |>
  summarize(
    postings = n_distinct(job_id),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_posting_salary))

write_csv(
  eda_skill_salary_summary,
  "output/eda_skill_salary_summary.csv"
)

# -------------------------------
# 5. Salary by experience level
# -------------------------------
eda_experience_salary_summary <- final_data |>
  group_by(llm_experience_level) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    experience_order = case_when(
      llm_experience_level == "entry" ~ 1,
      llm_experience_level == "mid" ~ 2,
      llm_experience_level == "senior" ~ 3,
      llm_experience_level == "manager" ~ 4,
      llm_experience_level == "unspecified" ~ 5,
      TRUE ~ 6
    )
  ) |>
  arrange(experience_order) |>
  select(-experience_order)

write_csv(
  eda_experience_salary_summary,
  "output/eda_experience_salary_summary.csv"
)

# -------------------------------
# 6. State-level salary summary
# -------------------------------
eda_state_salary_summary <- final_data |>
  filter(!is.na(state), state != "") |>
  group_by(state) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    median_household_income = first_non_missing(median_household_income),
    poverty_rate = first_non_missing(poverty_rate),
    avg_unemployment_rate = first_non_missing(avg_unemployment_rate),
    latest_unemployment_rate = first_non_missing(latest_unemployment_rate),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_state_salary_summary,
  "output/eda_state_salary_summary.csv"
)

# -------------------------------
# 7. Skill share by role category
# -------------------------------
eda_skill_by_role <- final_data |>
  select(
    job_id,
    llm_role_category_clean,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  mutate(
    has_skill = as.integer(has_skill)
  ) |>
  left_join(
    skill_label_lookup,
    by = "skill"
  ) |>
  group_by(llm_role_category_clean, skill, skill_label) |>
  summarize(
    postings_with_skill = n_distinct(job_id[has_skill == 1]),
    total_role_postings = n_distinct(job_id),
    skill_share = postings_with_skill / total_role_postings,
    skill_share_pct = skill_share * 100,
    .groups = "drop"
  ) |>
  arrange(llm_role_category_clean, desc(skill_share))

write_csv(
  eda_skill_by_role,
  "output/eda_skill_by_role.csv"
)

# -------------------------------
# 8. Role by experience level
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
    experience_share = n / role_total,
    experience_share_pct = experience_share * 100
  ) |>
  ungroup()

write_csv(
  eda_role_by_experience,
  "output/eda_role_by_experience.csv"
)

# -------------------------------
# 9. State labor and economic context
# -------------------------------
eda_state_labor_context <- final_data |>
  filter(!is.na(state), state != "") |>
  group_by(state) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    median_household_income = first_non_missing(median_household_income),
    poverty_rate = first_non_missing(poverty_rate),
    avg_unemployment_rate = first_non_missing(avg_unemployment_rate),
    latest_unemployment_rate = first_non_missing(latest_unemployment_rate),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_state_labor_context,
  "output/eda_state_labor_context.csv"
)

# -------------------------------
# 10. Correlation summary
# -------------------------------
eda_correlation_summary <- tibble(
  variable = c(
    "skill_count",
    "median_household_income",
    "poverty_rate",
    "avg_unemployment_rate"
  ),
  correlation_with_avg_salary = c(
    cor(final_data$avg_salary, final_data$skill_count, use = "complete.obs"),
    cor(final_data$avg_salary, final_data$median_household_income, use = "complete.obs"),
    cor(final_data$avg_salary, final_data$poverty_rate, use = "complete.obs"),
    cor(final_data$avg_salary, final_data$avg_unemployment_rate, use = "complete.obs")
  )
) |>
  arrange(desc(abs(correlation_with_avg_salary)))

write_csv(
  eda_correlation_summary,
  "output/eda_correlation_summary.csv"
)

# -------------------------------
# 11. Top companies by postings
# -------------------------------
eda_company_summary <- final_data |>
  filter(!is.na(company), company != "") |>
  count(company, sort = TRUE) |>
  rename(postings = n)

write_csv(
  eda_company_summary,
  "output/eda_company_summary.csv"
)

# -------------------------------
# 12. Search query summary
# -------------------------------
eda_search_query_summary <- final_data |>
  group_by(search_query) |>
  summarize(
    postings = n(),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_search_query_summary,
  "output/eda_search_query_summary.csv"
)

# -------------------------------
# 13. Industry salary summary
# -------------------------------
eda_industry_salary_summary <- final_data |>
  group_by(company_industry) |>
  summarize(
    postings = n(),
    unique_companies = n_distinct(company, na.rm = TRUE),
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    min_posting_salary = min(avg_salary, na.rm = TRUE),
    max_posting_salary = max(avg_salary, na.rm = TRUE),
    avg_skill_count = mean(skill_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(postings))

write_csv(
  eda_industry_salary_summary,
  "output/eda_industry_salary_summary.csv"
)

# -------------------------------
# 14. Skill share by industry
# -------------------------------
eda_skill_by_industry <- final_data |>
  select(
    job_id,
    company_industry,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  mutate(
    has_skill = as.integer(has_skill)
  ) |>
  left_join(
    skill_label_lookup,
    by = "skill"
  ) |>
  group_by(company_industry, skill, skill_label) |>
  summarize(
    postings_with_skill = n_distinct(job_id[has_skill == 1]),
    total_industry_postings = n_distinct(job_id),
    skill_share = postings_with_skill / total_industry_postings,
    skill_share_pct = skill_share * 100,
    .groups = "drop"
  ) |>
  arrange(company_industry, desc(skill_share))

write_csv(
  eda_skill_by_industry,
  "output/eda_skill_by_industry.csv"
)

# -------------------------------
# 14b. Skill share by industry and role category
# This table is calculated directly from job-level data.
# It supports Tableau views with both industry and role filters.
# -------------------------------

eda_skill_by_industry_role <- final_data |>
  select(
    job_id,
    company_industry,
    llm_role_category_clean,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  mutate(
    has_skill = as.integer(has_skill)
  ) |>
  left_join(
    skill_label_lookup,
    by = "skill"
  ) |>
  group_by(
    company_industry,
    llm_role_category_clean,
    skill,
    skill_label
  ) |>
  summarize(
    postings_with_skill = n_distinct(job_id[has_skill == 1]),
    total_group_postings = n_distinct(job_id),
    skill_share = postings_with_skill / total_group_postings,
    skill_share_pct = skill_share * 100,
    .groups = "drop"
  ) |>
  arrange(
    company_industry,
    llm_role_category_clean,
    desc(skill_share_pct)
  )

write_csv(
  eda_skill_by_industry_role,
  "output/eda_skill_by_industry_role.csv"
)

cat("\nSkill by industry and role preview:\n")
print(eda_skill_by_industry_role |> head(30))

# -------------------------------
# 15. Industry by role summary
# -------------------------------
eda_industry_role_summary <- final_data |>
  count(
    company_industry,
    llm_role_category_clean,
    sort = TRUE
  ) |>
  group_by(company_industry) |>
  mutate(
    industry_total = sum(n),
    role_share = n / industry_total,
    role_share_pct = role_share * 100
  ) |>
  ungroup()

write_csv(
  eda_industry_role_summary,
  "output/eda_industry_role_summary.csv"
)

# -------------------------------
# 16. Industry by experience summary
# -------------------------------
eda_industry_experience_summary <- final_data |>
  count(
    company_industry,
    llm_experience_level,
    sort = TRUE
  ) |>
  group_by(company_industry) |>
  mutate(
    industry_total = sum(n),
    experience_share = n / industry_total,
    experience_share_pct = experience_share * 100
  ) |>
  ungroup()

write_csv(
  eda_industry_experience_summary,
  "output/eda_industry_experience_summary.csv"
)

# -------------------------------
# 17. High salary skill analysis
# Define high-salary jobs as top 25% by avg_salary
# -------------------------------
salary_cutoff_75 <- quantile(
  final_data$avg_salary,
  0.75,
  na.rm = TRUE
)

eda_high_salary_skill_summary <- final_data |>
  mutate(
    high_salary_job = avg_salary >= salary_cutoff_75
  ) |>
  select(
    job_id,
    avg_salary,
    high_salary_job,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  mutate(
    has_skill = as.integer(has_skill)
  ) |>
  left_join(
    skill_label_lookup,
    by = "skill"
  ) |>
  group_by(skill, skill_label) |>
  summarize(
    total_skill_postings = n_distinct(job_id[has_skill == 1]),
    total_skill_rate = total_skill_postings / n_distinct(job_id),
    total_skill_rate_pct = total_skill_rate * 100,
    
    high_salary_skill_postings = n_distinct(job_id[has_skill == 1 & high_salary_job == TRUE]),
    high_salary_skill_rate = high_salary_skill_postings / n_distinct(job_id[high_salary_job == TRUE]),
    high_salary_skill_rate_pct = high_salary_skill_rate * 100,
    
    lift = high_salary_skill_rate - total_skill_rate,
    lift_pct_point = lift * 100,
    salary_cutoff_75 = salary_cutoff_75,
    .groups = "drop"
  ) |>
  arrange(desc(lift_pct_point))

write_csv(
  eda_high_salary_skill_summary,
  "output/eda_high_salary_skill_summary.csv"
)

# Clean Tableau version without repeated denominator columns
eda_high_salary_skill_tableau <- eda_high_salary_skill_summary |>
  filter(total_skill_postings >= 30) |>
  select(
    skill_label,
    total_skill_postings,
    total_skill_rate_pct,
    high_salary_skill_postings,
    high_salary_skill_rate_pct,
    lift_pct_point
  ) |>
  arrange(desc(lift_pct_point))

write_csv(
  eda_high_salary_skill_tableau,
  "output/eda_high_salary_skill_tableau.csv"
)

# -------------------------------
# 18. Industry high-salary summary
# -------------------------------
eda_industry_high_salary_summary <- final_data |>
  mutate(
    high_salary_job = avg_salary >= salary_cutoff_75
  ) |>
  group_by(company_industry) |>
  summarize(
    postings = n(),
    high_salary_postings = sum(high_salary_job, na.rm = TRUE),
    high_salary_share = high_salary_postings / postings,
    high_salary_share_pct = high_salary_share * 100,
    avg_posting_salary = mean(avg_salary, na.rm = TRUE),
    median_posting_salary = median(avg_salary, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(high_salary_share))

write_csv(
  eda_industry_high_salary_summary,
  "output/eda_industry_high_salary_summary.csv"
)

# -------------------------------
# 19. Title group by industry
# -------------------------------
eda_title_group_by_industry <- final_data |>
  count(
    company_industry,
    job_title_group,
    sort = TRUE
  ) |>
  group_by(company_industry) |>
  mutate(
    industry_total = sum(n),
    title_group_share = n / industry_total,
    title_group_share_pct = title_group_share * 100
  ) |>
  ungroup()

write_csv(
  eda_title_group_by_industry,
  "output/eda_title_group_by_industry.csv"
)
# -------------------------------
# Print key outputs
# -------------------------------
cat("\nEDA overview summary:\n")
print(eda_overview_summary)

cat("\nSalary by role category:\n")
print(eda_role_salary_summary, n = Inf)

cat("\nSalary by title group:\n")
print(eda_title_group_salary_summary, n = Inf)

cat("\nSalary by skill:\n")
print(eda_skill_salary_summary, n = Inf)

cat("\nSalary by experience level:\n")
print(eda_experience_salary_summary, n = Inf)

cat("\nIndustry salary summary:\n")
print(eda_industry_salary_summary, n = Inf)

cat("\nSkill by industry preview:\n")
print(eda_skill_by_industry |> head(30))

cat("\nHigh salary skill table for Tableau:\n")
print(eda_high_salary_skill_tableau, n = Inf)

cat("\nCorrelation summary:\n")
print(eda_correlation_summary)

print("Enhanced EDA completed successfully.")