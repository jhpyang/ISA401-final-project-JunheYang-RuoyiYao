# 01_acquire_data.R
# Purpose: Acquire job posting data from USAJOBS API and store raw and cleaned datasets

# -------------------------------
# Load required libraries
# -------------------------------
library(httr2)
library(jsonlite)
library(dplyr)
library(readr)
library(tibble)
library(purrr)

# -------------------------------
# Create project directories
# -------------------------------
dir.create("data_raw", showWarnings = FALSE)
dir.create("data_clean", showWarnings = FALSE)

# -------------------------------
# Load API credentials from environment variables
# -------------------------------
USER_AGENT <- Sys.getenv("USAJOBS_EMAIL")
API_KEY <- Sys.getenv("USAJOBS_KEY")

# -------------------------------
# Validate API credentials
# -------------------------------
if (USER_AGENT == "" | API_KEY == "") {
  stop("Missing USAJOBS_EMAIL or USAJOBS_KEY. Please set them in your .Renviron file.")
}

# -------------------------------
# Define query parameters
# -------------------------------
query <- "data analyst"

# -------------------------------
# Send API request
# -------------------------------
resp <- request("https://data.usajobs.gov/api/search") |>
  req_url_query(
    Keyword = query,
    ResultsPerPage = 50
  ) |>
  req_headers(
    "User-Agent" = USER_AGENT,
    "Authorization-Key" = API_KEY
  ) |>
  req_perform()

# -------------------------------
# Parse JSON response
# -------------------------------
data_json <- resp_body_json(resp)

results <- data_json$SearchResult$SearchResultItems

# -------------------------------
# Convert API results to dataframe
# -------------------------------
job_df <- map_dfr(results, function(x) {
  job <- x$MatchedObjectDescriptor
  
  tibble(
    title = job$PositionTitle,
    organization = job$OrganizationName,
    location = paste(job$PositionLocationDisplay, collapse = ", "),
    min_salary = as.numeric(job$PositionRemuneration[[1]]$MinimumRange),
    max_salary = as.numeric(job$PositionRemuneration[[1]]$MaximumRange),
    start_date = job$PositionStartDate,
    end_date = job$PositionEndDate,
    job_uri = job$PositionURI
  )
})

# -------------------------------
# Save raw dataset
# -------------------------------
write_csv(job_df, "data_raw/usajobs_raw.csv")

# -------------------------------
# Create cleaned dataset
# -------------------------------
job_clean <- job_df %>%
  mutate(
    avg_salary = (min_salary + max_salary) / 2
  )

# -------------------------------
# Save cleaned dataset
# -------------------------------
write_csv(job_clean, "data_clean/usajobs_clean.csv")

# -------------------------------
# Completion message
# -------------------------------
print("USAJOBS data acquisition completed successfully.")