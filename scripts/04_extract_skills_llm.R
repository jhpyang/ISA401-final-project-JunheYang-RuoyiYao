# -------------------------------
# 04_extract_skills_llm.R
# Purpose: Use LLM to classify role category and experience level for all Adzuna jobs
# Input:
#   data_clean/adzuna_jobs_with_skills.csv
# Output:
#   data_clean/adzuna_jobs_with_llm_roles.csv
#   output/llm_role_summary.csv
#   output/llm_experience_summary.csv
#   output/llm_error_check.csv
# -------------------------------

library(tidyverse)
library(httr2)
library(jsonlite)
library(stringr)

# -------------------------------
# Create folders
# -------------------------------
dir.create("data_clean", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)
dir.create("output/llm_role_batches", showWarnings = FALSE)

# -------------------------------
# Load OpenAI API key
# -------------------------------
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

if (OPENAI_API_KEY == "") {
  stop("Missing OPENAI_API_KEY. Please set it in your .Renviron file.")
}

# -------------------------------
# Read full keyword-extracted dataset
# -------------------------------
jobs <- read_csv("data_clean/adzuna_jobs_with_skills.csv", show_col_types = FALSE)

if (!"text_for_skills" %in% names(jobs)) {
  stop("Missing text_for_skills column. Please rerun earlier scripts first.")
}

# -------------------------------
# Prepare full dataset
# Keep text short for speed
# -------------------------------
jobs_for_llm <- jobs |>
  mutate(
    row_id = row_number(),
    text_short = str_sub(
      paste(title, search_query, description, sep = " "),
      1,
      350
    )
  ) |>
  select(row_id, title, search_query, text_short)

# -------------------------------
# Batch settings
# 100 rows per request reduces API calls sharply
# -------------------------------
batch_size <- 100

jobs_batches <- jobs_for_llm |>
  mutate(batch_id = ceiling(row_id / batch_size)) |>
  group_by(batch_id) |>
  summarize(
    batch_jobs = list(
      tibble(
        row_id = row_id,
        title = title,
        query = search_query,
        text = text_short
      )
    ),
    .groups = "drop"
  )

total_batches <- nrow(jobs_batches)

# -------------------------------
# Function to classify one batch
# -------------------------------
classify_batch_llm <- function(batch_jobs, batch_id, api_key, total_batches) {
  
  job_json <- toJSON(batch_jobs, auto_unbox = TRUE, pretty = FALSE, na = "null")
  
  prompt <- paste0(
    "Classify each job posting in this JSON array. ",
    "Return ONLY valid JSON. No markdown. ",
    "Return this structure: {\"results\":[...]}. ",
    "Return exactly one object per input row and preserve row_id. ",
    "Each object must contain: row_id, role_category, experience_level. ",
    "role_category must be one of: Data Analyst, Data Scientist, Data Engineer, Business Analyst, ",
    "Business Intelligence, Financial Analyst, Market Research Analyst, Operations Analyst, ",
    "Product Analyst, Reporting Analyst, Database Role, Analytics Manager, Other Data/Analytics Role. ",
    "experience_level must be one of: entry, mid, senior, manager, unspecified. ",
    "Input JSON: ",
    job_json
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
    "Processing batch ", batch_id, " of ", total_batches,
    " | rows ", min(batch_jobs$row_id), "-", max(batch_jobs$row_id)
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
  
  expected_cols <- c("row_id", "role_category", "experience_level")
  missing_cols <- setdiff(expected_cols, names(out))
  
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "LLM output missing columns:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }
  
  if (nrow(out) != nrow(batch_jobs)) {
    stop(
      paste0(
        "LLM returned ", nrow(out),
        " rows, but expected ", nrow(batch_jobs), " rows."
      )
    )
  }
  
  out |>
    mutate(batch_id = batch_id)
}

# -------------------------------
# Run batches with checkpoint saving
# -------------------------------
error_log <- tibble(
  batch_id = integer(),
  batch_rows = integer(),
  success = logical(),
  error_message = character()
)

for (i in seq_len(nrow(jobs_batches))) {
  
  batch_id <- jobs_batches$batch_id[i]
  batch_jobs <- jobs_batches$batch_jobs[[i]]
  
  batch_file <- sprintf("output/llm_role_batches/batch_%03d.csv", batch_id)
  
  if (file.exists(batch_file)) {
    message("Skipping completed batch ", batch_id)
    
    error_log <- bind_rows(
      error_log,
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_jobs),
        success = TRUE,
        error_message = "SUCCESS_ALREADY_EXISTS"
      )
    )
    
    next
  }
  
  batch_result <- tryCatch(
    {
      result <- classify_batch_llm(
        batch_jobs = batch_jobs,
        batch_id = batch_id,
        api_key = OPENAI_API_KEY,
        total_batches = total_batches
      )
      
      write_csv(result, batch_file)
      
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_jobs),
        success = TRUE,
        error_message = "SUCCESS"
      )
    },
    error = function(e) {
      tibble(
        batch_id = batch_id,
        batch_rows = nrow(batch_jobs),
        success = FALSE,
        error_message = conditionMessage(e)
      )
    }
  )
  
  error_log <- bind_rows(error_log, batch_result)
  write_csv(error_log, "output/llm_error_check.csv")
}

write_csv(error_log, "output/llm_error_check.csv")

print(
  error_log |>
    count(error_message, sort = TRUE)
)

# -------------------------------
# Combine completed batch files
# -------------------------------
batch_files <- list.files(
  "output/llm_role_batches",
  pattern = "^batch_\\d+\\.csv$",
  full.names = TRUE
)

if (length(batch_files) == 0) {
  stop("No completed LLM role batch files found.")
}

llm_roles <- batch_files |>
  map_dfr(~ read_csv(.x, show_col_types = FALSE)) |>
  mutate(
    row_id = as.integer(row_id),
    llm_role_category = role_category,
    llm_experience_level = experience_level
  ) |>
  select(row_id, batch_id, llm_role_category, llm_experience_level) |>
  distinct(row_id, .keep_all = TRUE)

# -------------------------------
# Merge LLM role classifications back to full skill dataset
# Clean LLM role labels into standardized categories
# -------------------------------
final_llm_data <- jobs |>
  mutate(row_id = row_number()) |>
  left_join(llm_roles, by = "row_id") |>
  mutate(
    llm_success = !is.na(llm_role_category),
    
    llm_role_category_clean = case_when(
      str_detect(llm_role_category, regex("data scientist", ignore_case = TRUE)) ~ "Data Scientist",
      str_detect(llm_role_category, regex("data engineer", ignore_case = TRUE)) ~ "Data Engineer",
      str_detect(llm_role_category, regex("business intelligence|\\bbi\\b", ignore_case = TRUE)) ~ "Business Intelligence",
      
      str_detect(llm_role_category, regex("financial|finance", ignore_case = TRUE)) ~ "Financial Analyst",
      str_detect(llm_role_category, regex("market research|marketing analyst", ignore_case = TRUE)) ~ "Market Research Analyst",
      str_detect(llm_role_category, regex("operations|logistics|facilities", ignore_case = TRUE)) ~ "Operations Analyst",
      str_detect(llm_role_category, regex("product", ignore_case = TRUE)) ~ "Product Analyst",
      str_detect(llm_role_category, regex("reporting", ignore_case = TRUE)) ~ "Reporting Analyst",
      str_detect(llm_role_category, regex("database", ignore_case = TRUE)) ~ "Database Role",
      str_detect(llm_role_category, regex("analytics manager|data analytics manager|manager", ignore_case = TRUE)) ~ "Analytics Manager",
      
      str_detect(llm_role_category, regex("business.*data analyst|business/data analyst|business analyst", ignore_case = TRUE)) ~ "Business Analyst",
      str_detect(llm_role_category, regex("data analyst|sr data analyst|sr\\. data analyst|senior data analyst|lead data analyst|research data analyst|web data analyst|clinical data analyst|healthcare data analyst|it data analyst|client data analyst|enterprise data analyst", ignore_case = TRUE)) ~ "Data Analyst",
      
      str_detect(llm_role_category, regex("other", ignore_case = TRUE)) ~ "Other Data/Analytics Role",
      TRUE ~ "Other Data/Analytics Role"
    )
  )
# -------------------------------
# Save output
# -------------------------------
write_csv(
  final_llm_data,
  "data_clean/adzuna_jobs_with_llm_roles.csv"
)

# -------------------------------
# Summaries
# -------------------------------
llm_role_raw_summary <- final_llm_data |>
  count(llm_role_category, sort = TRUE)

llm_role_summary <- final_llm_data |>
  count(llm_role_category_clean, sort = TRUE)

llm_experience_summary <- final_llm_data |>
  count(llm_experience_level, sort = TRUE)

success_summary <- final_llm_data |>
  summarize(
    n = n(),
    successful_llm_rows = sum(llm_success, na.rm = TRUE),
    failed_llm_rows = sum(!llm_success, na.rm = TRUE),
    success_rate = successful_llm_rows / n
  )

write_csv(llm_role_raw_summary, "output/llm_role_raw_summary.csv")
write_csv(llm_role_summary, "output/llm_role_summary.csv")
write_csv(llm_experience_summary, "output/llm_experience_summary.csv")
print(dim(final_llm_data))
print(success_summary)
print(llm_role_summary)
print(llm_experience_summary)

print("LLM role and experience classification completed successfully.")