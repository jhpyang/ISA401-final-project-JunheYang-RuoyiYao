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

This project satisfies the requirement of using multiple data sources and multiple acquisition or transformation methods.

The project uses three primary external data sources:

1. Adzuna job postings
2. U.S. Census ACS state-level economic data
3. BLS LAUS state-level labor market data

The project also uses two major data acquisition and transformation methods:

1. API-based data acquisition for Adzuna, Census ACS, and BLS LAUS
2. Text-based transformation of job descriptions using keyword extraction and LLM-based classification

Keyword-based extraction is applied to the full job posting dataset to identify skill indicators such as SQL, Python, Excel, Tableau, Power BI, machine learning, cloud, ETL, database, reporting, and communication skills.

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
