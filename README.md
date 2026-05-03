# ISA 401 Final Project: U.S. Job Market Skill and Salary Analysis

## Project Overview

This project investigates how required skills and job characteristics influence job demand and salary levels in business analytics-related roles in the U.S. job market.

The goal of this project is to build a multi-source dataset from real-world data, clean and integrate the data in R, validate the final dataset, and communicate the findings through a Tableau or Power BI dashboard.

## Research Question

How do required skills and job characteristics influence salary levels and job demand in business analytics-related roles?

## Why This Topic Matters

Business analytics students and job seekers need to understand which skills are most valued in the labor market. Employers also need to understand how skill requirements vary across job titles, locations, and salary levels. This project uses current job market data to identify patterns in skill demand, salary differences, and job characteristics.

## Planned Data Sources

| Data Source | Acquisition Method | Purpose |
|---|---|---|
| USAJOBS API | API access | Collect job posting data, including job titles, agencies, locations, salary ranges, posting dates, and job links |
| U.S. Census ACS via tidycensus | API access | Collect state-level economic indicators, including median household income and poverty rate |
| U.S. Bureau of Labor Statistics (BLS) | API access | Collect labor market benchmark data, such as occupational wage or employment information |
| Job descriptions from USAJOBS postings | LLM-based structured extraction | Extract required skills, tools, experience level, and job categories from unstructured job description text |

The LLM-based structured extraction step is not counted as a separate data source. Instead, it is used as a second acquisition and transformation method to convert unstructured job description text into structured skill variables.

## Role of External Economic Data

State-level economic data from the U.S. Census is used to provide context for job market analysis.

This allows the project to examine whether salary differences across job postings are influenced not only by required skills, but also by underlying regional economic conditions such as income levels and poverty rates.

## Technical Workflow

All core data work will be completed in R.

The planned workflow includes:

1. Acquire job posting data from real-world sources
2. Use an API to collect external labor market data
3. Use an LLM to extract structured skill information from job descriptions
4. Clean and standardize job titles, locations, salaries, and descriptions
5. Merge job posting data with external labor market data
6. Validate the final merged dataset
7. Create descriptive summaries and exploratory analysis
8. Build a final dashboard in Tableau or Power BI


## API Credential Management

API credentials are not stored in the GitHub repository. Required API keys are stored locally in a `.Renviron` file and loaded in R using `Sys.getenv()`. This protects sensitive credentials while keeping the data pipeline reproducible for users who provide their own API keys.

## API Access

This project uses external APIs (e.g., USAJOBS and Census API).

To reproduce the data acquisition process, users must:

1. Obtain their own API keys
2. Store them in a `.Renviron` file:
   USAJOBS_KEY=your_key
   USAJOBS_EMAIL=your_email

API credentials are not included in this repository for security reasons.

## Repository Structure

```text
isa401-final-project/
├── README.md
├── scripts/
├── 01_acquire_usajobs.R
├── 02_acquire_census_data.R
├── 03_clean_data.R
├── 04_extract_skills.R
├── 05_merge_data.R
├── 06_validate_data.R
└── 07_eda.R
├── data_raw/
├── data_clean/
├── output/
└── dashboard/
