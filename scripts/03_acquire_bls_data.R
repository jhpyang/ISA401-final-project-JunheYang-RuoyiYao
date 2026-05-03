# -------------------------------
# 03_acquire_bls_laus.R
# Purpose: Collect BLS LAUS state-level labor market benchmark data
# Output:
#   1. data_clean/bls_laus_unemployment_rate.csv
#   2. data_clean/bls_laus_state_avg.csv
# -------------------------------

library(tidyverse)
library(httr2)
library(jsonlite)
library(readr)

# -------------------------------
# Create folders
# -------------------------------
dir.create("data_raw", showWarnings = FALSE)
dir.create("data_clean", showWarnings = FALSE)

# -------------------------------
# Load BLS API key
# -------------------------------
BLS_KEY <- Sys.getenv("BLS_API_KEY")

if (BLS_KEY == "") {
  stop("Missing BLS_API_KEY in .Renviron")
}

# -------------------------------
# State FIPS lookup
# BLS LAUS state unemployment rate series format:
# LAUST + state FIPS + 0000000000003
#
# LAUST = not seasonally adjusted
# 03 = unemployment rate
# -------------------------------
state_lookup <- tibble(
  state = c(
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
  ),
  state_fips = c(
    "01", "02", "04", "05", "06",
    "08", "09", "10", "11",
    "12", "13", "15", "16", "17",
    "18", "19", "20", "21", "22",
    "23", "24", "25", "26", "27",
    "28", "29", "30", "31", "32",
    "33", "34", "35", "36",
    "37", "38", "39", "40",
    "41", "42", "44", "45",
    "46", "47", "48", "49", "50",
    "51", "53", "54", "55",
    "56"
  )
) |>
  mutate(
    series_id = paste0("LAUST", state_fips, "0000000000003")
  )

# -------------------------------
# Split series IDs into batches
# BLS API allows up to 25 series per request with a key
# -------------------------------
series_batches <- split(
  state_lookup$series_id,
  ceiling(seq_along(state_lookup$series_id) / 25)
)

# -------------------------------
# Function to request one batch from BLS API
# -------------------------------
get_bls_batch <- function(series_ids) {
  
  payload <- list(
    seriesid = series_ids,
    startyear = "2024",
    endyear = "2025",
    registrationkey = BLS_KEY
  )
  
  resp <- request("https://api.bls.gov/publicAPI/v2/timeseries/data/") |>
    req_body_json(payload) |>
    req_perform()
  
  bls_json <- resp_body_json(resp)
  
  bls_json$Results$series |>
    map_dfr(function(s) {
      tibble(
        series_id = s$seriesID,
        data = s$data
      ) |>
        unnest_wider(data)
    })
}

# -------------------------------
# Request all state data
# -------------------------------
bls_laus <- map_dfr(series_batches, get_bls_batch)

# -------------------------------
# Clean monthly unemployment data
# -------------------------------
bls_laus_clean <- bls_laus |>
  left_join(
    state_lookup |> select(state, state_fips, series_id),
    by = "series_id"
  ) |>
  mutate(
    unemployment_rate = parse_number(value),
    month_num = as.integer(str_remove(period, "M")),
    year_num = as.integer(year),
    date = as.Date(paste(year_num, month_num, "01", sep = "-"))
  ) |>
  filter(
    !is.na(state),
    !is.na(unemployment_rate),
    !is.na(year_num),
    !is.na(month_num),
    month_num >= 1,
    month_num <= 12
  ) |>
  select(
    state,
    state_fips,
    series_id,
    year = year_num,
    period,
    periodName,
    month_num,
    date,
    unemployment_rate
  ) |>
  arrange(state, desc(date))

# -------------------------------
# Save monthly BLS data
# -------------------------------
write_csv(
  bls_laus_clean,
  "data_clean/bls_laus_unemployment_rate.csv"
)

# -------------------------------
# Create state-level average unemployment rate
# -------------------------------
bls_laus_state_avg <- bls_laus_clean |>
  group_by(state, state_fips) |>
  summarize(
    avg_unemployment_rate = mean(unemployment_rate, na.rm = TRUE),
    observations = n(),
    .groups = "drop"
  )

# -------------------------------
# Create latest unemployment rate table
# -------------------------------
bls_laus_latest <- bls_laus_clean |>
  group_by(state, state_fips) |>
  slice_max(
    order_by = date,
    n = 1,
    with_ties = FALSE
  ) |>
  ungroup() |>
  select(
    state,
    state_fips,
    latest_year = year,
    latest_period = periodName,
    latest_unemployment_rate = unemployment_rate
  )

# -------------------------------
# Merge average and latest tables
# -------------------------------
bls_laus_state_avg <- bls_laus_state_avg |>
  left_join(
    bls_laus_latest,
    by = c("state", "state_fips")
  ) |>
  arrange(state)

# -------------------------------
# Save state-level BLS benchmark table
# -------------------------------
write_csv(
  bls_laus_state_avg,
  "data_clean/bls_laus_state_avg.csv"
)

# -------------------------------
# Check missing states
# -------------------------------
missing_states <- state_lookup |>
  anti_join(
    bls_laus_state_avg |> select(state),
    by = "state"
  )

# -------------------------------
# Preview results
# -------------------------------
print(bls_laus_clean)
print(bls_laus_state_avg)

cat("\nNumber of states/areas in final table:", nrow(bls_laus_state_avg), "\n")
cat("\nMissing states/areas:\n")
print(missing_states)