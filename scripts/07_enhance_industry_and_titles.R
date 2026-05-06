# -------------------------------
# 07_enhance_industry_and_titles.R
# Purpose:
#   1. Clean job title fields
#   2. Use LLM to classify company / employer industry
#   3. Create industry-level summaries for dashboard
#
# Input:
#   data_clean/final_merged_data.csv
#
# Output:
#   data_clean/final_merged_data_enhanced.csv
#   output/company_industry_classification.csv
#   output/industry_summary.csv
#   output/skill_by_industry.csv
#   output/industry_role_summary.csv
#   output/title_group_summary.csv
#   output/industry_title_validation.csv
# -------------------------------

# -------------------------------
# Load required libraries
# -------------------------------
library(tidyverse)
library(readr)
library(stringr)
library(httr2)
library(jsonlite)

# -------------------------------
# Create folders
# -------------------------------
dir.create("data_clean", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)
dir.create("output/industry_batches", showWarnings = FALSE)

# -------------------------------
# Load OpenAI API key
# -------------------------------
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

if (OPENAI_API_KEY == "") {
  stop("Missing OPENAI_API_KEY. Please set it in your .Renviron file.")
}

# -------------------------------
# Read final merged dataset
# -------------------------------
final_data <- read_csv(
  "data_clean/final_merged_data.csv",
  show_col_types = FALSE
)

# -------------------------------
# Check required columns
# -------------------------------
required_cols <- c(
  "company",
  "title",
  "category",
  "search_query",
  "description",
  "avg_salary",
  "skill_count",
  "llm_role_category_clean",
  "llm_experience_level"
)

missing_cols <- setdiff(required_cols, names(final_data))

if (length(missing_cols) > 0) {
  stop(
    paste(
      "Missing required columns:",
      paste(missing_cols, collapse = ", ")
    )
  )
}

# -------------------------------
# Part 1: Clean job titles
# -------------------------------
final_data_title_cleaned <- final_data |>
  mutate(
    job_title_clean = title |>
      str_replace_all("\u2013|\u2014", "-") |>
      str_remove_all("\\([^)]*\\)") |>
      str_remove_all("\\[[^]]*\\]") |>
      str_remove_all("(?i)remote|hybrid|onsite|on-site") |>
      str_remove_all("(?i)urgent hiring|hiring now|immediate hire") |>
      str_remove_all("(?i)full[- ]time|part[- ]time|contract|temporary") |>
      str_remove_all("(?i)\\busa\\b|\\bunited states\\b") |>
      str_replace_all("\\s+-\\s+.*$", "") |>
      str_replace_all("\\s+\\|\\s+.*$", "") |>
      str_replace_all("\\s+/\\s+.*$", "") |>
      str_replace_all("[[:space:]]+", " ") |>
      str_squish(),
    
    job_title_clean = if_else(
      job_title_clean == "" | is.na(job_title_clean),
      title,
      job_title_clean
    ),
    
    title_lower = str_to_lower(job_title_clean),
    
    job_title_group = case_when(
      str_detect(title_lower, "data scientist|scientist") ~ "Data Scientist",
      str_detect(title_lower, "data engineer|analytics engineer|etl engineer") ~ "Data Engineer",
      str_detect(title_lower, "business intelligence|\\bbi\\b") ~ "Business Intelligence",
      str_detect(title_lower, "data analyst|analyst, data") ~ "Data Analyst",
      str_detect(title_lower, "business analyst") ~ "Business Analyst",
      str_detect(title_lower, "financial analyst|finance analyst|fp&a|fpa") ~ "Financial Analyst",
      str_detect(title_lower, "market research|marketing analyst") ~ "Market Research Analyst",
      str_detect(title_lower, "operations analyst|operational analyst") ~ "Operations Analyst",
      str_detect(title_lower, "product analyst") ~ "Product Analyst",
      str_detect(title_lower, "reporting analyst") ~ "Reporting Analyst",
      str_detect(title_lower, "database analyst|database administrator|\\bdba\\b") ~ "Database Role",
      str_detect(title_lower, "analytics manager|manager.*analytics|analytics lead|head of analytics") ~ "Analytics Manager",
      TRUE ~ llm_role_category_clean
    ),
    
    job_seniority_from_title = case_when(
      str_detect(title_lower, "\\bintern\\b|internship") ~ "intern",
      str_detect(title_lower, "entry|junior|associate|jr\\.?") ~ "entry",
      str_detect(title_lower, "senior|sr\\.?|lead|principal|staff") ~ "senior",
      str_detect(title_lower, "manager|director|head|vp|vice president") ~ "manager",
      TRUE ~ llm_experience_level
    )
  ) |>
  select(-title_lower)

# -------------------------------
# Part 2: Build unique company profile table for LLM industry classification
# Classify unique companies instead of every row for efficiency
# -------------------------------
company_profiles <- final_data_title_cleaned |>
  filter(!is.na(company), company != "") |>
  group_by(company) |>
  summarize(
    example_titles = paste(
      head(unique(job_title_clean), 4),
      collapse = "; "
    ),
    example_roles = paste(
      head(unique(llm_role_category_clean), 4),
      collapse = "; "
    ),
    example_queries = paste(
      head(unique(search_query), 4),
      collapse = "; "
    ),
    example_categories = paste(
      head(unique(category), 4),
      collapse = "; "
    ),
    example_description = str_sub(
      paste(
        head(na.omit(description), 2),
        collapse = " "
      ),
      1,
      300
    ),
    postings = n(),
    .groups = "drop"
  ) |>
  mutate(
    company_id = row_number()
  ) |>
  select(
    company_id,
    company,
    postings,
    example_titles,
    example_roles,
    example_queries,
    example_categories,
    example_description
  )

# -------------------------------
# Industry categories
# -------------------------------
industry_categories <- c(
  "Technology",
  "Finance & Insurance",
  "Healthcare",
  "Government / Public Sector",
  "Consulting / Professional Services",
  "Retail / E-commerce",
  "Manufacturing",
  "Education",
  "Transportation / Logistics",
  "Energy / Utilities",
  "Real Estate",
  "Media / Entertainment",
  "Hospitality",
  "Nonprofit",
  "Other / Unknown"
)

# -------------------------------
# Batch settings
# -------------------------------
batch_size <- 50

company_batches <- company_profiles |>
  mutate(batch_id = ceiling(company_id / batch_size)) |>
  group_by(batch_id) |>
  summarize(
    batch_companies = list(
      tibble(
        company_id = company_id,
        company = company,
        example_titles = example_titles,
        example_roles = example_roles,
        example_queries = example_queries,
        example_categories = example_categories,
        example_description = example_description
      )
    ),
    .groups = "drop"
  )

total_batches <- nrow(company_batches)

# -------------------------------
# Function to classify one batch of companies
# -------------------------------
classify_company_industry_batch <- function(batch_companies, batch_id, api_key, total_batches) {
  
  company_json <- toJSON(
    batch_companies,
    auto_unbox = TRUE,
    pretty = FALSE,
    na = "null"
  )
  
  prompt <- paste0(
    "Classify the likely employer industry for each company in the JSON array. ",
    "Use the company name and examples of job titles, roles, categories, queries, and descriptions. ",
    "Return ONLY valid JSON. No markdown. ",
    "Return this exact structure: {\"results\":[...]}. ",
    "Return exactly one object per input row and preserve company_id. ",
    "Each object must contain: company_id, industry, confidence, reason. ",
    "Industry must be one of: ",
    paste(industry_categories, collapse = ", "),
    ". ",
    "Confidence must be one of: high, medium, low. ",
    "Reason should be short, fewer than 12 words. ",
    "Input JSON: ",
    company_json
  )
  
  body <- list(
    model = "gpt-4o-mini",
    messages = list(
      list(
        role = "system",
        content = "Return only valid JSON."
      ),
      list(
        role = "user",
        content = prompt
      )
    ),
    temperature = 0,
    response_format = list(
      type = "json_object"
    )
  )
  
  message(
    "Processing industry batch ", batch_id, " of ", total_batches,
    " | companies ", min(batch_companies$company_id), "-", max(batch_companies$company_id)
  )
  
  resp <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      "Authorization" = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ) |>
    req_body_json(body) |>
    req_timeout(120) |>
    req_retry(
      max_tries = 3,
      backoff = ~ 2
    ) |>
    req_perform()
  
  result <- resp_body_json(resp)
  content <- result$choices[[1]]$message$content
  
  parsed <- fromJSON(content, simplifyDataFrame = TRUE)
  
  if (!"results" %in% names(parsed)) {
    stop("LLM response did not contain a results field.")
  }
  
  out <- as_tibble(parsed$results)
  
  expected_cols <- c(
    "company_id",
    "industry",
    "confidence",
    "reason"
  )
  
  missing_cols <- setdiff(expected_cols, names(out))
  
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "LLM output missing columns:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }
  
  if (nrow(out) != nrow(batch_companies)) {
    stop(
      paste0(
        "LLM returned ",
        nrow(out),
        " rows, but expected ",
        nrow(batch_companies),
        " rows."
      )
    )
  }
  
  out |>
    mutate(batch_id = batch_id)
}

# -------------------------------
# Run industry classification with checkpoint saving
# -------------------------------
industry_error_log <- tibble(
  batch_id = integer(),
  batch_rows = integer(),
  success = logical(),
  error_message = character()
)

for (i in seq_len(nrow(company_batches))) {
  
  batch_id <- company_batches$batch_id[i]
  batch_companies <- company_batches$batch_companies[[i]]
  
  batch_file <- sprintf(
    "output/industry_batches/industry_batch_%03d.csv",
    batch_id
  )
  
  if (file.exists(batch_file)) {
    message("Skipping completed industry batch ", batch_id)
    
    industry_error_log <- bind_rows(
      industry_error_log,
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_companies),
        success = TRUE,
        error_message = "SUCCESS_ALREADY_EXISTS"
      )
    )
    
    next
  }
  
  batch_result <- tryCatch(
    {
      result <- classify_company_industry_batch(
        batch_companies = batch_companies,
        batch_id = batch_id,
        api_key = OPENAI_API_KEY,
        total_batches = total_batches
      )
      
      write_csv(result, batch_file)
      
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_companies),
        success = TRUE,
        error_message = "SUCCESS"
      )
    },
    error = function(e) {
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_companies),
        success = FALSE,
        error_message = conditionMessage(e)
      )
    }
  )
  
  industry_error_log <- bind_rows(
    industry_error_log,
    batch_result
  )
  
  write_csv(
    industry_error_log,
    "output/industry_classification_error_check.csv"
  )
  
  Sys.sleep(0.05)
}

write_csv(
  industry_error_log,
  "output/industry_classification_error_check.csv"
)

print(
  industry_error_log |>
    count(error_message, sort = TRUE)
)

# -------------------------------
# Combine industry batch files
# -------------------------------
industry_batch_files <- list.files(
  "output/industry_batches",
  pattern = "^industry_batch_\\d+\\.csv$",
  full.names = TRUE
)

if (length(industry_batch_files) == 0) {
  stop("No completed industry batch files found.")
}

company_industry <- industry_batch_files |>
  map_dfr(~ read_csv(.x, show_col_types = FALSE)) |>
  mutate(
    company_id = as.integer(company_id),
    industry = str_squish(industry),
    confidence = str_to_lower(str_squish(confidence)),
    industry = if_else(
      industry %in% industry_categories,
      industry,
      "Other / Unknown"
    )
  ) |>
  distinct(company_id, .keep_all = TRUE) |>
  left_join(
    company_profiles,
    by = "company_id"
  ) |>
  select(
    company_id,
    company,
    industry,
    confidence,
    reason,
    postings,
    example_titles,
    example_roles,
    example_queries
  )

write_csv(
  company_industry,
  "output/company_industry_classification.csv"
)

# -------------------------------
# Merge industry classifications back to final data
# -------------------------------
final_data_enhanced <- final_data_title_cleaned |>
  left_join(
    company_industry |>
      select(company, industry, confidence, reason),
    by = "company"
  ) |>
  rename(
    company_industry = industry,
    industry_confidence = confidence,
    industry_reason = reason
  ) |>
  mutate(
    company_industry = if_else(
      is.na(company_industry),
      "Other / Unknown",
      company_industry
    )
  )

write_csv(
  final_data_enhanced,
  "data_clean/final_merged_data_enhanced.csv"
)

# -------------------------------
# Create industry summary
# Important:
# Use avg_posting_salary and median_posting_salary
# Do NOT name the summary column avg_salary,
# because that would overwrite the original avg_salary inside summarize().
# -------------------------------
industry_summary <- final_data_enhanced |>
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
  industry_summary,
  "output/industry_summary.csv"
)

# -------------------------------
# Create title group summary
# -------------------------------
title_group_summary <- final_data_enhanced |>
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
  arrange(desc(postings))

write_csv(
  title_group_summary,
  "output/title_group_summary.csv"
)

# -------------------------------
# Create skill by industry summary
# -------------------------------
skill_columns <- names(final_data_enhanced) |>
  str_subset("^skill_") |>
  setdiff("skill_count")

skill_by_industry <- final_data_enhanced |>
  select(
    company_industry,
    all_of(skill_columns)
  ) |>
  pivot_longer(
    cols = all_of(skill_columns),
    names_to = "skill",
    values_to = "has_skill"
  ) |>
  group_by(company_industry, skill) |>
  summarize(
    postings_with_skill = sum(has_skill == TRUE, na.rm = TRUE),
    total_industry_postings = n(),
    skill_share = postings_with_skill / total_industry_postings,
    .groups = "drop"
  ) |>
  arrange(company_industry, desc(skill_share))

write_csv(
  skill_by_industry,
  "output/skill_by_industry.csv"
)

# -------------------------------
# Create industry by role summary
# -------------------------------
industry_role_summary <- final_data_enhanced |>
  count(
    company_industry,
    llm_role_category_clean,
    sort = TRUE
  ) |>
  group_by(company_industry) |>
  mutate(
    industry_total = sum(n),
    role_share = n / industry_total
  ) |>
  ungroup()

write_csv(
  industry_role_summary,
  "output/industry_role_summary.csv"
)

# -------------------------------
# Create industry by experience summary
# -------------------------------
industry_experience_summary <- final_data_enhanced |>
  count(
    company_industry,
    llm_experience_level,
    sort = TRUE
  ) |>
  group_by(company_industry) |>
  mutate(
    industry_total = sum(n),
    experience_share = n / industry_total
  ) |>
  ungroup()

write_csv(
  industry_experience_summary,
  "output/industry_experience_summary.csv"
)

# -------------------------------
# Validation checks
# -------------------------------
industry_validation <- final_data_enhanced |>
  summarize(
    total_rows = n(),
    rows_with_company_industry = sum(!is.na(company_industry)),
    rows_missing_company_industry = sum(is.na(company_industry)),
    unique_industries = n_distinct(company_industry),
    rows_with_clean_title = sum(!is.na(job_title_clean) & job_title_clean != ""),
    rows_with_title_group = sum(!is.na(job_title_group) & job_title_group != "")
  )

write_csv(
  industry_validation,
  "output/industry_title_validation.csv"
)

# -------------------------------
# Print key outputs
# -------------------------------
cat("\nIndustry classification validation:\n")
print(industry_validation)

cat("\nIndustry summary:\n")
print(industry_summary, n = Inf)

cat("\nTitle group summary:\n")
print(title_group_summary, n = Inf)

cat("\nSkill by industry preview:\n")
print(skill_by_industry |> head(30))

cat("\nIndustry role summary preview:\n")
print(industry_role_summary |> head(30))

print("Industry classification and title cleaning completed successfully.")