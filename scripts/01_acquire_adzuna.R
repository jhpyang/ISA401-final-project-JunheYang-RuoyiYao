# -------------------------------
# 01_acquire_data.R
# Purpose: Acquire broader U.S. job posting data from Adzuna API
# Output:
#   1. data_raw/adzuna_jobs_raw.csv
#   2. data_clean/adzuna_jobs_clean.csv
# -------------------------------

# -------------------------------
# Load required libraries
# -------------------------------
library(httr2)
library(jsonlite)
library(dplyr)
library(readr)
library(tibble)
library(purrr)
library(tidyr)
library(stringr)

# -------------------------------
# Helper function for missing values
# -------------------------------
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) {
    y
  } else {
    x
  }
}

# -------------------------------
# Create project directories
# -------------------------------
dir.create("data_raw", showWarnings = FALSE)
dir.create("data_clean", showWarnings = FALSE)

# -------------------------------
# Load Adzuna credentials from environment variables
# -------------------------------
ADZUNA_APP_ID <- Sys.getenv("ADZUNA_APP_ID")
ADZUNA_APP_KEY <- Sys.getenv("ADZUNA_APP_KEY")

# -------------------------------
# Validate API credentials
# -------------------------------
if (ADZUNA_APP_ID == "" | ADZUNA_APP_KEY == "") {
  stop("Missing ADZUNA_APP_ID or ADZUNA_APP_KEY. Please set them in your .Renviron file.")
}

# -------------------------------
# Define search keywords
# These keywords represent data, analytics, and business intelligence-related roles
# -------------------------------
queries <- c(
  "data analyst",
  "data scientist",
  "business analyst",
  "business intelligence",
  "data engineer",
  "analytics manager",
  "financial analyst",
  "market research analyst",
  "operations analyst",
  "product analyst",
  "reporting analyst",
  "database analyst"
)

# -------------------------------
# Define pagination settings
# Adzuna page number is included in the endpoint URL
# -------------------------------
results_per_page <- 50
max_pages <- 5

# -------------------------------
# Function to request one Adzuna page
# -------------------------------
get_adzuna_page <- function(query, page_number) {
  
  message("Requesting query: ", query, " | page: ", page_number)
  
  url <- paste0("https://api.adzuna.com/v1/api/jobs/us/search/", page_number)
  
  resp <- request(url) |>
    req_url_query(
      app_id = ADZUNA_APP_ID,
      app_key = ADZUNA_APP_KEY,
      what = query,
      where = "United States",
      results_per_page = results_per_page
    ) |>
    req_perform()
  
  adzuna_json <- resp_body_json(resp)
  
  results <- adzuna_json$results
  
  if (is.null(results) || length(results) == 0) {
    return(tibble())
  }
  
  map_dfr(results, function(job) {
    
    tibble(
      search_query = query,
      
      title = job$title %||% NA_character_,
      company = job$company$display_name %||% NA_character_,
      category = job$category$label %||% NA_character_,
      
      location = job$location$display_name %||% NA_character_,
      area = paste(unlist(job$location$area), collapse = "; "),
      
      min_salary = as.numeric(job$salary_min %||% NA_real_),
      max_salary = as.numeric(job$salary_max %||% NA_real_),
      salary_is_predicted = job$salary_is_predicted %||% NA,
      
      created = job$created %||% NA_character_,
      contract_time = job$contract_time %||% NA_character_,
      contract_type = job$contract_type %||% NA_character_,
      
      description = job$description %||% NA_character_,
      redirect_url = job$redirect_url %||% NA_character_,
      job_id = as.character(job$id %||% NA_character_)
    )
  })
}

# -------------------------------
# Request all queries and pages
# -------------------------------
job_df <- expand_grid(
  query = queries,
  page_number = 1:max_pages
) |>
  mutate(
    data = map2(query, page_number, get_adzuna_page)
  ) |>
  select(data) |>
  unnest(data)

# -------------------------------
# Remove duplicate postings
# Some postings may appear under multiple search keywords
# -------------------------------
job_df <- job_df |>
  distinct(job_id, .keep_all = TRUE)

# -------------------------------
# Save raw dataset
# -------------------------------
write_csv(
  job_df,
  "data_raw/adzuna_jobs_raw.csv"
)

# -------------------------------
# Create cleaned dataset
# -------------------------------
state_names <- c(
  "Alabama", "Alaska", "Arizona", "Arkansas", "California",
  "Colorado", "Connecticut", "Delaware", "District of Columbia",
  "Florida", "Georgia", "Hawaii", "Idaho", "Illinois",
  "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
  "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
  "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada",
  "New Hampshire", "New Jersey", "New Mexico", "New York",
  "North Carolina", "North Dakota", "Ohio", "Oklahoma",
  "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
  "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
  "Virginia", "Washington", "West Virginia", "Wisconsin",
  "Wyoming"
)

extract_state <- function(location_text, area_text) {
  
  combined_text <- paste(location_text, area_text, sep = " ")
  
  matched_state <- state_names[str_detect(combined_text, fixed(state_names))]
  
  if (length(matched_state) == 0) {
    return(NA_character_)
  } else {
    return(matched_state[1])
  }
}

job_clean <- job_df |>
  mutate(
    avg_salary = case_when(
      !is.na(min_salary) & !is.na(max_salary) ~ (min_salary + max_salary) / 2,
      !is.na(min_salary) & is.na(max_salary) ~ min_salary,
      is.na(min_salary) & !is.na(max_salary) ~ max_salary,
      TRUE ~ NA_real_
    ),
    
    state = map2_chr(location, area, extract_state),
    
    text_for_skills = str_to_lower(
      paste(
        title,
        category,
        description,
        sep = " "
      )
    )
  )
# -------------------------------
# Save cleaned dataset
# -------------------------------
write_csv(
  job_clean,
  "data_clean/adzuna_jobs_clean.csv"
)

# -------------------------------
# Validation checks
# -------------------------------
print(names(job_clean))
print(dim(job_clean))

job_validation <- job_clean |>
  summarize(
    n = n(),
    missing_job_id = sum(is.na(job_id) | job_id == ""),
    missing_text_for_skills = sum(is.na(text_for_skills) | text_for_skills == ""),
    missing_avg_salary = sum(is.na(avg_salary)),
    min_avg_salary = min(avg_salary, na.rm = TRUE),
    max_avg_salary = max(avg_salary, na.rm = TRUE)
  )

print(job_validation)

query_summary <- job_clean |>
  count(search_query, sort = TRUE)

print(query_summary)

# -------------------------------
# Completion message
# -------------------------------
print("Adzuna job data acquisition completed successfully.")