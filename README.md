# ISA 401 Final Project: U.S. Data and Analytics Job Market Skill and Salary Analysis

## Project Overview

This project builds a data pipeline to analyze U.S. job postings related to data, analytics, and business intelligence roles.

The main goal is to study how job skills, role categories, experience levels, employer industries, and state-level economic conditions relate to salary patterns in the collected job posting data.

All core data work is completed in R. This includes data acquisition, cleaning, transformation, merging, validation, and exploratory summaries. The final dashboard is created in Tableau or Power BI.

## Research Question

How do required skills, role categories, experience levels, employer industries, and state-level context relate to salary levels in data and analytics-related job postings?

## Project Motivation

This project focuses on job market information that is relevant to business analytics students and job seekers.

The analysis is designed to address the following questions:

- Which skills appear most often in analytics-related job postings?
- Which roles and experience levels are associated with higher salary levels?
- How do skill requirements vary across employer industries?
- How do job posting patterns vary across states?
- How can unstructured job descriptions be transformed into structured variables for analysis?

## Data Sources

The project uses three external real-world data sources.

### 1. Adzuna Jobs API

The Adzuna Jobs API is used to collect U.S. job posting data.

Collected fields include:

- Job title
- Company
- Job category
- Location
- Salary estimates
- Posting date
- Job description
- Job link
- Job ID

This is the main job-level dataset.

### 2. U.S. Census ACS

U.S. Census ACS data is collected through the `tidycensus` package in R.

Collected state-level variables include:

- Median household income
- Poverty rate

These variables are used to add regional economic context.

### 3. BLS LAUS

BLS LAUS data is used to collect state-level unemployment information.

Collected variables include:

- Average unemployment rate
- Latest unemployment rate

These variables are used as state-level labor market indicators.

## Text Transformation Sources

The project also uses job description text from the Adzuna postings.

The job descriptions are not counted as a separate external data source because they are part of the Adzuna job posting data. However, they are used as unstructured text inputs for transformation.

Two text transformation methods are used:

1. Keyword-based skill extraction
2. LLM-based classification

## Acquisition and Transformation Methods

The project uses multiple acquisition and transformation methods.

### API-Based Acquisition

API access is used to collect data from:

- Adzuna Jobs API
- U.S. Census ACS through `tidycensus`
- BLS LAUS

### Keyword-Based Extraction

Keyword-based extraction is applied to the full job posting dataset to create binary skill indicators.

The skill variables include:

- SQL
- Python
- R
- Excel
- Tableau
- Power BI
- SAS
- Statistics
- Machine learning
- Data visualization
- Database
- Data analysis
- Reporting
- Communication
- Cloud
- ETL

A `skill_count` variable is also created to count the number of detected skill indicators for each posting.

### LLM-Based Classification

An LLM-based classification step is applied to the full job posting dataset.

The LLM is used to classify:

- Role category
- Experience level
- Employer industry

The role categories are standardized into 13 cleaned categories. The experience levels are standardized into five categories.

The employer industry classification is created from company names and related job posting context.

## Employer Industry Enhancement

After the final merged dataset is created, an additional enhancement step classifies companies into employer industries.

The industry categories include:

- Technology
- Finance & Insurance
- Healthcare
- Government / Public Sector
- Consulting / Professional Services
- Retail / E-commerce
- Manufacturing
- Education
- Transportation / Logistics
- Energy / Utilities
- Real Estate
- Media / Entertainment
- Hospitality
- Nonprofit
- Other / Unknown

The industry classification is used to support analysis of how skill requirements and salary patterns differ by employer industry.

## Job Title Cleaning

The original job title field is retained.

Additional cleaned title variables are created:

- `job_title_clean`
- `job_title_group`
- `job_seniority_from_title`

These variables are used to reduce noise in job title analysis. For example, remote labels, contract labels, and formatting details are removed from the cleaned title field when possible.

The cleaned title group is used as an additional role-level variable for analysis and dashboard development.

## Technical Workflow

The core workflow is organized into numbered R scripts.

1. `01_acquire_adzuna.R`
   - Collects job postings from the Adzuna Jobs API
   - Saves raw and cleaned job posting files

2. `02_acquire_census_data.R`
   - Collects Census ACS state-level economic data
   - Saves cleaned state-level income and poverty data

3. `03_acquire_bls_data.R`
   - Collects BLS LAUS unemployment data
   - Saves cleaned state-level labor market data

4. `04_extract_skills.R`
   - Applies keyword-based skill extraction to job descriptions
   - Creates skill indicator variables and skill summaries

5. `04_extract_skills_llm.R`
   - Applies LLM-based role and experience classification
   - Uses batch processing and checkpoint files
   - Saves cleaned LLM role and experience variables

6. `05_merge_data.R`
   - Merges job-level data with Census and BLS state-level data
   - Creates the final merged dataset

7. `06_validate_data.R`
   - Checks missing values, duplicate records, salary fields, failed joins, and classification coverage
   - Produces validation output files

8. `07_enhance_industry_and_titles.R`
   - Cleans job title fields
   - Uses LLM classification to assign employer industries
   - Produces enhanced dataset and industry summaries

9. `08_eda.R`
   - Produces exploratory summaries for dashboard development
   - Includes role, skill, title group, industry, experience, state, and high-salary summaries

## Final Datasets

The project produces two main final datasets.

### Base Final Dataset

```text
data_clean/final_merged_data.csv
```

This dataset contains the merged job posting, skill, role, experience, Census, and BLS variables.

### Enhanced Final Dataset

```text
data_clean/final_merged_data_enhanced.csv
```

This dataset adds:

- Cleaned job title fields
- Job title groups
- Title-based seniority information
- Employer industry classification

The enhanced dataset is the preferred file for final dashboard development.

## Final Dataset Structure

The enhanced final dataset is organized at the job-posting level.

Each row represents one job posting.

The dataset includes the following groups of variables:

### Job Posting Variables

- Job title
- Cleaned job title
- Company
- Location
- State
- Salary estimates
- Posting date
- Job link
- Job ID

### Extracted Job Characteristics

- Skill indicators
- Skill count
- LLM role category
- LLM experience level
- Job title group
- Title-based seniority

### Employer Industry Variables

- Company industry
- Industry classification confidence
- Industry classification reason

### State-Level Context Variables

- Median household income
- Poverty rate
- Average unemployment rate
- Latest unemployment rate

## Key Validation Results

The base final merged dataset passed the main validation checks.

- Total rows: 2,983
- Total columns: 54
- Unique job IDs: 2,983
- Duplicate job IDs: 0
- Missing job IDs: 0
- Missing salary rows: 0
- Rows with keyword skill variables: 2,983
- Rows with LLM role classification: 2,983
- Rows with LLM experience classification: 2,983
- Rows missing state: 164
- Rows matched with Census data: 2,819
- Rows matched with BLS data: 2,808

The industry and title enhancement step also produces a validation output:

```text
output/industry_title_validation.csv
```

This file checks whether rows have industry classification, cleaned title fields, and title group values.

## Validation Output Files

The validation step produces several output files.

```text
output/validation_status.csv
output/data_validation_summary.csv
output/missing_value_summary.csv
output/salary_validation_summary.csv
output/state_merge_coverage.csv
output/state_merge_detail.csv
output/duplicate_job_check.csv
output/unmatched_census_states.csv
output/unmatched_bls_states.csv
output/llm_validation_summary.csv
output/industry_title_validation.csv
```

These files document data quality checks, including missing values, duplicate records, salary checks, failed joins, and LLM classification coverage.

## EDA Output Files

The EDA step produces summary files used for Tableau or Power BI.

```text
output/eda_overview_summary.csv
output/eda_role_salary_summary.csv
output/eda_title_group_salary_summary.csv
output/eda_skill_salary_summary.csv
output/eda_experience_salary_summary.csv
output/eda_state_salary_summary.csv
output/eda_skill_by_role.csv
output/eda_role_by_experience.csv
output/eda_state_labor_context.csv
output/eda_correlation_summary.csv
output/eda_company_summary.csv
output/eda_search_query_summary.csv
output/eda_industry_salary_summary.csv
output/eda_skill_by_industry.csv
output/eda_industry_role_summary.csv
output/eda_industry_experience_summary.csv
output/eda_high_salary_skill_summary.csv
output/eda_industry_high_salary_summary.csv
output/skill_label_lookup.csv
```

## Dashboard Data Files

The main dashboard can be built from the enhanced final dataset:

```text
data_clean/final_merged_data_enhanced.csv
```

The following summary files are also useful for dashboard views:

```text
output/eda_role_salary_summary.csv
output/eda_title_group_salary_summary.csv
output/eda_skill_salary_summary.csv
output/eda_experience_salary_summary.csv
output/eda_state_salary_summary.csv
output/eda_industry_salary_summary.csv
output/eda_skill_by_industry.csv
output/eda_high_salary_skill_summary.csv
```

## Dashboard Plan

The final dashboard is organized around three main views.

### 1. Job Market Overview

This view summarizes the collected job posting dataset.

Planned elements include:

- Total job postings
- Average posting salary
- Number of unique companies
- Role category distribution
- Top states by postings
- Employer industry distribution

### 2. Skill, Role, and Salary Analysis

This view examines how salary patterns differ by skills, roles, and experience levels.

Planned elements include:

- Average salary by role category
- Average salary by cleaned job title group
- Average salary by experience level
- Most common skill indicators
- Average salary by skill
- Skills associated with high-salary postings

### 3. Industry and State-Level Context

This view connects job posting patterns with employer industry and state-level context.

Planned elements include:

- Average salary by employer industry
- Skill share by industry
- Role mix by industry
- Job postings by state
- Average salary by state
- Census and BLS state-level context

## Preliminary EDA Notes

The EDA output files support several initial observations.

- Salary patterns differ across role categories and experience levels.
- Skill indicators such as machine learning, ETL, cloud, database, statistics, and Python appear in higher-salary summaries.
- Employer industry classification allows the project to compare skill requirements across industries.
- State-level Census and BLS variables provide context for regional job posting comparisons.
- Some state-level comparisons are limited by postings without clear state information.

These observations are based on the collected Adzuna job posting sample and should not be interpreted as a complete measure of the U.S. labor market.

## API Credential Management

API credentials are not stored in the GitHub repository.

Required API keys are stored locally in a `.Renviron` file and loaded in R using `Sys.getenv()`.

Required credentials include:

```text
ADZUNA_APP_ID=your_adzuna_app_id
ADZUNA_APP_KEY=your_adzuna_app_key
CENSUS_API_KEY=your_census_api_key
BLS_API_KEY=your_bls_api_key
OPENAI_API_KEY=your_openai_api_key
```

The `.Renviron` file is excluded from the repository through `.gitignore`.

## Reproducibility Instructions

To reproduce the project:

1. Clone or download the repository.
2. Create a `.Renviron` file with the required API credentials.
3. Restart the R session.
4. Run the scripts in order.

```r
source("scripts/01_acquire_adzuna.R")
source("scripts/02_acquire_census_data.R")
source("scripts/03_acquire_bls_data.R")
source("scripts/04_extract_skills.R")
source("scripts/04_extract_skills_llm.R")
source("scripts/05_merge_data.R")
source("scripts/06_validate_data.R")
source("scripts/07_enhance_industry_and_titles.R")
source("scripts/08_eda.R")
```

The final enhanced dataset will be saved in:

```text
data_clean/final_merged_data_enhanced.csv
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
│   ├── 07_enhance_industry_and_titles.R
│   └── 08_eda.R
├── data_raw/
│   └── adzuna_jobs_raw.csv
├── data_clean/
│   ├── adzuna_jobs_clean.csv
│   ├── adzuna_jobs_with_skills.csv
│   ├── adzuna_jobs_with_llm_roles.csv
│   ├── state_economic_data.csv
│   ├── bls_laus_state_avg.csv
│   ├── final_merged_data.csv
│   └── final_merged_data_enhanced.csv
├── output/
│   ├── validation_status.csv
│   ├── merge_validation.csv
│   ├── industry_title_validation.csv
│   ├── eda_overview_summary.csv
│   ├── eda_role_salary_summary.csv
│   ├── eda_skill_salary_summary.csv
│   ├── eda_industry_salary_summary.csv
│   ├── eda_skill_by_industry.csv
│   └── eda_high_salary_skill_summary.csv
└── dashboard/
```

## Limitations

This project uses job postings collected from Adzuna. The results should be interpreted as patterns in the collected Adzuna job posting sample rather than a complete census of all U.S. data and analytics jobs.

Some salary values from Adzuna may be estimated or standardized. Salary findings should therefore be interpreted as approximate market indicators rather than exact employer-reported compensation.

Some job postings do not include a clear state-level location. These rows are retained for job-level analysis but may be excluded from state-level Census and BLS comparisons.

The BLS state-level unemployment data did not fully match every state represented in the job posting data. In the validation output, Wyoming appears as an unmatched BLS state.

Keyword-based skill extraction depends on selected search terms and may miss skills that are described indirectly.

LLM-based classification is used for role, experience, and industry classification. The output requires standardization and validation.

Employer industry classification is based on company names and job posting context. Some companies may operate across multiple industries, so the assigned industry should be treated as an analytical approximation.

## Tools and Packages

This project uses R for data acquisition, cleaning, transformation, validation, and exploratory analysis.

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

The final dashboard is created using Tableau or Power BI.
