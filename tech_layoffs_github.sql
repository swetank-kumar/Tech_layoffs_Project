-- Tech Layoffs Data Cleaning & Analysis
-- MySQL

USE tech_layoffs;

-- Create a working copy so the original raw table remains unchanged.
CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs;

-- Check for possible duplicate records.
SELECT
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    date,
    COUNT(*) AS record_count
FROM layoffs_staging
GROUP BY
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    date
HAVING COUNT(*) > 1;

-- Standardize company names.
UPDATE layoffs_staging
SET company = TRIM(company);

-- Standardize Crypto industry values.
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names.
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- Convert date text into DATE values.
UPDATE layoffs_staging
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN date DATE;

-- Convert blank industry values to NULL.
UPDATE layoffs_staging
SET industry = NULL
WHERE TRIM(industry) = '';

-- Fill missing industry values when another record for the same
-- company and location contains a non-null industry.
UPDATE layoffs_staging s1
JOIN layoffs_staging s2
    ON s1.company = s2.company
    AND s1.location = s2.location
SET s1.industry = s2.industry
WHERE s1.industry IS NULL
  AND s2.industry IS NOT NULL;

-- Remove records where both layoff measures are missing.
DELETE FROM layoffs_staging
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Data quality checks.
SELECT COUNT(*) AS total_records
FROM layoffs_staging;

SELECT *
FROM layoffs_staging
WHERE company IS NULL
   OR TRIM(company) = '';

SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Total layoffs by industry.
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Total layoffs by country.
SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_laid_off DESC;

-- Companies with the highest reported layoffs.
SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
WHERE company IS NOT NULL
GROUP BY company
ORDER BY total_laid_off DESC
LIMIT 10;

-- Layoff events by year.
SELECT
    YEAR(date) AS layoff_year,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY YEAR(date)
ORDER BY layoff_year;

-- Number of layoff records by industry.
SELECT
    industry,
    COUNT(*) AS layoff_events
FROM layoffs_staging
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY layoff_events DESC;

-- Average percentage laid off by industry.
SELECT
    industry,
    AVG(percentage_laid_off) AS average_percentage_laid_off
FROM layoffs_staging
WHERE industry IS NOT NULL
  AND percentage_laid_off IS NOT NULL
GROUP BY industry
ORDER BY average_percentage_laid_off DESC;

-- Final cleaned dataset.
SELECT *
FROM layoffs_staging
ORDER BY date, company;
