# 02_acquire_census_data.R
# Purpose: Acquire state-level economic data from Census ACS API

library(tidycensus)
library(tidyverse)
library(readr)
# -------------------------------
# Load required libraries
# -------------------------------
library(tidycensus)
library(tidyverse)

# -------------------------------
# Create project directories
# -------------------------------
dir.create("data_clean", showWarnings = FALSE)

# -------------------------------
# Load Census API key
# -------------------------------
census_api_key(Sys.getenv("CENSUS_API_KEY"), install = FALSE)

# -------------------------------
# Acquire state-level median household income
# -------------------------------
income_state <- get_acs(
  geography = "state",
  variables = "B19013_001",
  year = 2023,
  survey = "acs5"
)

# -------------------------------
# Clean income data
# -------------------------------
income_state_clean <- income_state %>%
  select(GEOID, NAME, estimate, moe) %>%
  rename(
    state_fips = GEOID,
    state_name = NAME,
    median_household_income = estimate,
    income_moe = moe
  )

# -------------------------------
# Acquire state-level poverty data
# -------------------------------
poverty <- get_acs(
  geography = "state",
  variables = c(
    below_poverty = "B17001_002",
    total_population = "B17001_001"
  ),
  year = 2023,
  survey = "acs5"
)

# -------------------------------
# Clean poverty data
# -------------------------------
poverty_clean <- poverty %>%
  select(NAME, variable, estimate) %>%
  pivot_wider(
    names_from = variable,
    values_from = estimate
  ) %>%
  mutate(
    poverty_rate = below_poverty / total_population
  ) %>%
  select(NAME, poverty_rate) %>%
  rename(state_name = NAME)

# -------------------------------
# Merge Census datasets
# -------------------------------
state_economic_data <- income_state_clean %>%
  left_join(poverty_clean, by = "state_name")

# -------------------------------
# Save cleaned Census dataset
# -------------------------------
write_csv(income_state_clean, "data_clean/income_state_clean.csv")
write_csv(poverty_clean, "data_clean/poverty_clean.csv")
write_csv(state_economic_data, "data_clean/state_economic_data.csv")

# -------------------------------
# Completion message
# -------------------------------
print("Census ACS data acquisition completed successfully.")
