# -------------------------------
# 04_extract_skills.R
# Purpose: Extract structured skill variables from Adzuna job descriptions
# Input:
#   data_clean/adzuna_jobs_clean.csv
# Output:
#   data_clean/adzuna_jobs_with_skills.csv
#   output/skill_summary.csv
#   output/role_summary.csv
# -------------------------------

library(tidyverse)
library(stringr)

# -------------------------------
# Create folders
# -------------------------------
dir.create("data_clean", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

# -------------------------------
# Read cleaned Adzuna job data
# -------------------------------
jobs <- read_csv("data_clean/adzuna_jobs_clean.csv", show_col_types = FALSE)

# -------------------------------
# Check required columns
# -------------------------------
if (!"text_for_skills" %in% names(jobs)) {
  stop("Missing text_for_skills column. Please rerun scripts/01_acquire_adzuna.R first.")
}

if (!"title" %in% names(jobs)) {
  stop("Missing title column. Please rerun scripts/01_acquire_adzuna.R first.")
}

# -------------------------------
# Extract skill variables from job text
# -------------------------------
jobs_with_skills <- jobs |>
  mutate(
    text_for_skills = str_to_lower(text_for_skills),
    
    skill_sql = str_detect(text_for_skills, "\\bsql\\b"),
    skill_python = str_detect(text_for_skills, "\\bpython\\b"),
    skill_r = str_detect(text_for_skills, "\\br\\b|\\br programming\\b|\\brstudio\\b"),
    skill_excel = str_detect(text_for_skills, "\\bexcel\\b|\\bspreadsheet\\b|\\bspreadsheets\\b"),
    skill_tableau = str_detect(text_for_skills, "\\btableau\\b"),
    skill_powerbi = str_detect(text_for_skills, "\\bpower bi\\b|\\bpowerbi\\b|\\bpower-bi\\b"),
    skill_sas = str_detect(text_for_skills, "\\bsas\\b"),
    skill_statistics = str_detect(text_for_skills, "\\bstatistics\\b|\\bstatistical\\b|\\bstats\\b"),
    skill_machine_learning = str_detect(text_for_skills, "\\bmachine learning\\b|\\bml\\b"),
    skill_data_visualization = str_detect(text_for_skills, "\\bdata visualization\\b|\\bvisualization\\b|\\bvisualisation\\b|\\bdashboard\\b|\\bdashboards\\b"),
    skill_database = str_detect(text_for_skills, "\\bdatabase\\b|\\bdatabases\\b|\\bdata warehouse\\b|\\bdata warehousing\\b"),
    skill_data_analysis = str_detect(text_for_skills, "\\bdata analysis\\b|\\banalytics\\b|\\banalytical\\b|\\banalysis\\b"),
    skill_reporting = str_detect(text_for_skills, "\\breporting\\b|\\breports\\b|\\breport\\b"),
    skill_communication = str_detect(text_for_skills, "\\bcommunication\\b|\\bcommunicate\\b|\\bpresentation\\b|\\bpresentations\\b"),
    skill_cloud = str_detect(text_for_skills, "\\baws\\b|\\bazure\\b|\\bgoogle cloud\\b|\\bgcp\\b|\\bcloud\\b"),
    skill_etl = str_detect(text_for_skills, "\\betl\\b|\\bdata pipeline\\b|\\bdata pipelines\\b"),
    
    skill_count = rowSums(
      across(
        starts_with("skill_") & !matches("^skill_count$"),
        ~ as.integer(.x)
      ),
      na.rm = TRUE
    )
  )

# -------------------------------
# Create role categories from title and search query
# -------------------------------
jobs_with_skills <- jobs_with_skills |>
  mutate(
    title_clean = str_to_lower(title),
    query_clean = str_to_lower(search_query),
    
    role_category = case_when(
      str_detect(title_clean, "data scientist|scientist") ~ "Data Scientist",
      str_detect(title_clean, "data engineer|analytics engineer|etl engineer") ~ "Data Engineer",
      str_detect(title_clean, "business intelligence|\\bbi\\b") ~ "Business Intelligence",
      str_detect(title_clean, "data analyst|analyst, data") ~ "Data Analyst",
      str_detect(title_clean, "business analyst") ~ "Business Analyst",
      str_detect(title_clean, "financial analyst|finance analyst") ~ "Financial Analyst",
      str_detect(title_clean, "market research|marketing analyst") ~ "Market Research Analyst",
      str_detect(title_clean, "operations analyst|operational analyst") ~ "Operations Analyst",
      str_detect(title_clean, "product analyst") ~ "Product Analyst",
      str_detect(title_clean, "reporting analyst") ~ "Reporting Analyst",
      str_detect(title_clean, "database analyst|database administrator|dba") ~ "Database Role",
      str_detect(title_clean, "analytics manager|manager.*analytics|analytics lead|head of analytics") ~ "Analytics Manager",
      
      str_detect(query_clean, "data scientist") ~ "Data Scientist",
      str_detect(query_clean, "data engineer") ~ "Data Engineer",
      str_detect(query_clean, "business intelligence") ~ "Business Intelligence",
      str_detect(query_clean, "data analyst") ~ "Data Analyst",
      str_detect(query_clean, "business analyst") ~ "Business Analyst",
      str_detect(query_clean, "financial analyst") ~ "Financial Analyst",
      str_detect(query_clean, "market research analyst") ~ "Market Research Analyst",
      str_detect(query_clean, "operations analyst") ~ "Operations Analyst",
      str_detect(query_clean, "product analyst") ~ "Product Analyst",
      str_detect(query_clean, "reporting analyst") ~ "Reporting Analyst",
      str_detect(query_clean, "database analyst") ~ "Database Role",
      str_detect(query_clean, "analytics manager") ~ "Analytics Manager",
      
      TRUE ~ "Other Data/Analytics Role"
    )
  )

# -------------------------------
# Save job-level skill dataset
# -------------------------------
write_csv(
  jobs_with_skills,
  "data_clean/adzuna_jobs_with_skills.csv"
)

# -------------------------------
# Create skill summary table
# -------------------------------
skill_summary <- jobs_with_skills |>
  summarize(
    across(
      starts_with("skill_") & !matches("^skill_count$"),
      ~ sum(.x, na.rm = TRUE)
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "skill",
    values_to = "count"
  ) |>
  arrange(desc(count))

write_csv(
  skill_summary,
  "output/skill_summary.csv"
)

# -------------------------------
# Create role summary table
# -------------------------------
role_summary <- jobs_with_skills |>
  count(role_category, sort = TRUE)

write_csv(
  role_summary,
  "output/role_summary.csv"
)

# -------------------------------
# Create salary by role summary
# -------------------------------
salary_by_role <- jobs_with_skills |>
  group_by(role_category) |>
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
  salary_by_role,
  "output/salary_by_role.csv"
)

# -------------------------------
# Create salary by skill summary
# -------------------------------
salary_by_skill <- jobs_with_skills |>
  select(avg_salary, starts_with("skill_")) |>
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
    avg_salary = mean(avg_salary, na.rm = TRUE),
    median_salary = median(avg_salary, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_salary))

write_csv(
  salary_by_skill,
  "output/salary_by_skill.csv"
)

# -------------------------------
# Validation checks
# -------------------------------
print(dim(jobs_with_skills))
print(skill_summary)
print(role_summary)
print(salary_by_role)
print(salary_by_skill)

print("Skill extraction completed successfully.")