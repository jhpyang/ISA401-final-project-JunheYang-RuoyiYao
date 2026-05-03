# ISA 401 Final Project: U.S. Data and Analytics Job Market Skill and Salary Analysis

## Project Overview

This project investigates how required skills, role categories, experience levels, and state-level economic conditions relate to salary levels in data, analytics, and business intelligence-related roles in the U.S. job market.

The goal of this project is to build a multi-source dataset from real-world data, clean and integrate the data in R, validate the final dataset, and communicate the findings through a Tableau or Power BI dashboard.

The final dataset combines job posting data from Adzuna, state-level economic indicators from the U.S. Census ACS, and labor market benchmark data from the U.S. Bureau of Labor Statistics. The project also uses both keyword-based extraction and LLM-based classification to transform unstructured job descriptions into structured variables.

## Research Question

How do required skills, job characteristics, role categories, and experience levels relate to salary levels in data, analytics, and business intelligence-related roles in the U.S. job market?

## Why This Topic Matters

Business analytics students and job seekers need to understand which skills and role types are most valued in the labor market. Employers also need to understand how skill requirements vary across job titles, locations, experience levels, and salary levels.

This project uses current job posting data to identify patterns in skill demand, salary differences, role categories, and regional job market conditions. These insights can help students, job seekers, and analysts better understand how technical skills, business skills, and labor market context relate to salary outcomes.

## Data Sources

| Data Source | Acquisition Method | Purpose |
|---|---|---|
| Adzuna Jobs API | API access | Collect U.S. job posting data, including job titles, companies, locations, salary estimates, descriptions, posting dates, and job links |
| U.S. Census ACS via tidycensus | API access | Collect state-level economic indicators, including median household income and poverty rate |
| U.S. Bureau of Labor Statistics LAUS | API access | Collect state-level labor market benchmark data, including unemployment rate |
| Job descriptions from Adzuna postings | Keyword-based extraction and LLM-based classification | Convert unstructured job description text into structured skill, role, and experience variables |

The job descriptions are not counted as a separate external data source because they are part of the Adzuna job posting dataset. They are used as unstructured text inputs for additional transformation.

## Data Acquisition and Transformation Methods

This project uses three primary external data sources:

1. Adzuna job postings
2. U.S. Census ACS state-level economic data
3. BLS LAUS state-level labor market data

The project also uses two major data acquisition and transformation methods:

1. API-based data acquisition for Adzuna, Census ACS, and BLS LAUS
2. Text-based transformation of job descriptions using keyword extraction and LLM-based classification

Keyword-based extraction is applied to the full job posting dataset to identify skill indicators such as SQL, Python, R, Excel, Tableau, Power BI, SAS, statistics, machine learning, data visualization, database, data analysis, reporting, communication, cloud, and ETL skills.

LLM-based classification is applied to the full job posting dataset to classify role categories and experience levels from unstructured job text.

## Role of External Economic and Labor Market Data

State-level economic data from the U.S. Census is used to provide regional context for job market analysis. The Census variables include median household income and poverty rate.

BLS LAUS unemployment data is used as a state-level labor market benchmark. This allows the project to compare job posting salary patterns with broader labor market conditions across states.

Because some job postings do not include a clear state-level location, those postings are retained for job-level salary and skill analysis but may not be included in state-level economic comparisons.

## Technical Workflow

All core data work is completed in R.

The workflow includes:

1. Acquire job posting data from the Adzuna Jobs API
2. Acquire state-level economic data from the U.S. Census ACS
3. Acquire state-level unemployment benchmark data from BLS LAUS
4. Clean and standardize job titles, companies, locations, salaries, descriptions, and state names
5. Use keyword-based extraction to create structured skill variables from job descriptions
6. Use LLM-based classification to identify role categories and experience levels
7. Merge job posting data with Census and BLS state-level data
8. Validate the final merged dataset
9. Create descriptive summaries and exploratory analysis outputs
10. Build a final dashboard in Tableau or Power BI

## Final Dataset

The final merged dataset contains:

- 2,983 job postings
- 54 columns
- 1,156 unique companies
- 49 states represented in the job posting data
- 13 cleaned LLM-based role categories
- 5 LLM-based experience levels
- Keyword-based skill indicators
- State-level Census and BLS variables

The final dataset is saved as:

```text
data_clean/final_merged_data.csv
```

## Key Validation Results

The final dataset passed the main validation checks.

| Validation Check | Result |
|---|---:|
| Total rows | 2,983 |
| Total columns | 54 |
| Unique job IDs | 2,983 |
| Duplicate job IDs | 0 |
| Missing job IDs | 0 |
| Missing salary rows | 0 |
| Rows with keyword skill variables | 2,983 |
| Rows with LLM role classification | 2,983 |
| Rows with LLM experience classification | 2,983 |
| Rows missing state | 164 |
| Rows matched with Census data | 2,819 |
| Rows matched with BLS data | 2,808 |

Some postings did not include a clear state-level location. These rows are still used for job-level skill and salary analysis, but they may not be used in state-level Census or BLS comparisons.

## Key EDA Outputs

The project creates several EDA summary files in the `output/` folder:

```text
output/eda_overview_summary.csv
output/eda_role_salary_summary.csv
output/eda_skill_salary_summary.csv
output/eda_experience_salary_summary.csv
output/eda_state_salary_summary.csv
output/eda_skill_by_role.csv
output/eda_role_by_experience.csv
output/eda_state_labor_context.csv
output/eda_correlation_summary.csv
output/eda_company_summary.csv
output/eda_search_query_summary.csv
```

These files are used to support the final dashboard and project interpretation.

## Preliminary Findings

The EDA results show several useful patterns:

- Data Scientist, Data Engineer, and Analytics Manager roles have the highest average salary levels among the classified role categories.
- Machine learning, ETL, cloud, database, statistics, and Python skills are associated with higher average salary levels.
- Manager and senior experience levels have higher average salaries than mid-level and entry-level roles.
- California, Virginia, Texas, New York, and Maryland have the largest numbers of postings in the collected dataset.
- State-level economic and labor market variables provide useful regional context, although their correlations with posting salary are relatively weak in this dataset.

Salary values from Adzuna are treated as approximate market salary indicators rather than exact employer-reported compensation.

## API Credential Management

API credentials are not stored in the GitHub repository. Required API keys are stored locally in a `.Renviron` file and loaded in R using `Sys.getenv()`.

This protects sensitive credentials while keeping the data pipeline reproducible for users who provide their own API keys.

Required credentials include:

```text
ADZUNA_APP_ID=your_adzuna_app_id
ADZUNA_APP_KEY=your_adzuna_app_key
CENSUS_API_KEY=your_census_api_key
BLS_API_KEY=your_bls_api_key
OPENAI_API_KEY=your_openai_api_key
```

API credentials are not included in this repository for security reasons.

## How to Reproduce the Project

To reproduce the project:

1. Clone or download the repository.
2. Create a `.Renviron` file with the required API credentials.
3. Restart the R session.
4. Run the scripts in order:

```r
source("scripts/01_acquire_adzuna.R")
source("scripts/02_acquire_census_data.R")
source("scripts/03_acquire_bls_data.R")
source("scripts/04_extract_skills.R")
source("scripts/04_extract_skills_llm.R")
source("scripts/05_merge_data.R")
source("scripts/06_validate_data.R")
source("scripts/07_eda.R")
```

The final merged dataset will be saved in:

```text
data_clean/final_merged_data.csv
```

## Repository Structure

```text
isa401-final-project/
├── README.md
├── scripts/
│   ├── 01_acquire_adzuna.R
│   ├── 02_acquire_census_data.R
│   ├── 03_acquire_bls_data.R
│   ├── 04_extract_skills.R
│   ├── 04_extract_skills_llm.R
│   ├── 05_merge_data.R
│   ├── 06_validate_data.R
│   └── 07_eda.R
├── data_raw/
│   └── adzuna_jobs_raw.csv
├── data_clean/
│   ├── adzuna_jobs_clean.csv
│   ├── adzuna_jobs_with_skills.csv
│   ├── adzuna_jobs_with_llm_roles.csv
│   ├── state_economic_data.csv
│   ├── bls_laus_state_avg.csv
│   └── final_merged_data.csv
├── output/
│   ├── validation_status.csv
│   ├── merge_validation.csv
│   ├── eda_overview_summary.csv
│   ├── eda_role_salary_summary.csv
│   ├── eda_skill_salary_summary.csv
│   ├── eda_experience_salary_summary.csv
│   └── eda_state_salary_summary.csv
└── dashboard/
```

## Dashboard Plan

The final dashboard will communicate the main findings through several views:

### 1. Job Market Overview

- Total postings
- Average salary
- Role distribution
- Top states and companies

### 2. Skill Demand Analysis

- Most common skills
- Skill frequency by role category
- Salary patterns by skill

### 3. Salary by Role and Experience

- Average salary by LLM-classified role category
- Average salary by experience level
- Skill count by role and experience level

### 4. State-Level Market Context

- Postings by state
- Average salary by state
- Census median household income
- Census poverty rate
- BLS unemployment rate

### 5. Data Quality and Methodology

- Data sources
- Merge validation
- Missing state count
- LLM classification coverage

## Limitations

This project uses job postings collected from Adzuna rather than all job postings in the U.S. labor market. Therefore, the results should be interpreted as patterns in the collected Adzuna job posting sample rather than a complete census of all U.S. data and analytics jobs.

Some salary values from Adzuna may be estimated or standardized by the platform. As a result, salary findings should be interpreted as approximate market indicators rather than exact employer-reported compensation.

Some job postings do not include a clear state-level location, especially remote or multi-location postings. These rows are retained for job-level analysis but may be excluded from state-level Census and BLS comparisons.

The BLS state-level unemployment data did not fully match every state represented in the job posting data. In the final validation output, Wyoming appears as an unmatched BLS state.

The keyword-based skill extraction method depends on selected search terms and may miss skills that are described indirectly. The LLM-based classification step improves role and experience classification, but it may still require standardization and validation.

## Tools and Packages

This project uses R for data acquisition, cleaning, validation, and exploratory analysis.

Main R packages include:

```text
tidyverse
readr
dplyr
tidyr
stringr
purrr
httr2
jsonlite
tidycensus
```

The final dashboard will be created using Tableau or Power BI.
