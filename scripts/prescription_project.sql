--QUESTION 1 Which prescriber had the highest total number of claims (totaled over all drugs)
--ANSWER: npi: 1881634483 with 99707
SELECT npi, SUM(total_claim_count) AS total_claim
FROM prescriber AS p
INNER JOIN prescription
USING (npi)
GROUP BY npi
ORDER BY total_claim DESC;

--1b report nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
--ANSWER Bruce Pendley, Family Practice, 99707
SELECT npi, SUM(total_claim_count) AS total_claim,
nppes_provider_first_name, nppes_provider_last_org_name,
specialty_description
FROM prescription AS p
INNER JOIN prescriber
USING (npi)
GROUP BY npi, 
prescriber.nppes_provider_first_name, 
nppes_provider_last_org_name, 
specialty_description
ORDER BY total_claim DESC
LIMIT 5;

--QUESTION 2a which specialty had the most total number of claims (total over all drugs)
--ANSWER Family Practice 9752347
SELECT specialty_description, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber 
USING (npi)
GROUP BY specialty_description
ORDER BY total_claim DESC;

--2b QUESTION which specialty had the most total number of claims opioids
--ANSWER: Nurse Practioner, 900845
SELECT specialty_description, SUM(total_claim_count) AS total_claim, opioid_drug_flag
FROM prescription
INNER JOIN prescriber 
USING (npi)
INNER JOIN drug 
ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_claim DESC;

--QUESTION 3a ANSWER: Insulin glargine, 104264066.45
SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM drug
INNER JOIN prescription 
USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;


--3b ANSWER:  C1 ESTERASE INHIBITOR 
SELECT DISTINCT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS cost_per_day
FROM prescription
LEFT JOIN drug 
USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC NULLS LAST;

--QUESTION 4a 
SELECT  d.drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug AS d
	ORDER BY drug_name
--4b  opioid cost: $105,080,626.37  antibiotic cost: $38,435,121.26
SELECT 
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost::money END) AS opioid_cost,
	SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost::money END) AS antibiotic_cost
	FROM prescription
	LEFT JOIN drug
	ON drug.drug_name = prescription.drug_name;
	
--QUESTION 5a ANSWER: 10
SELECT COUNT (DISTINCT CBSA) AS cbsa_count
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--QUESTION 5b
--ANSWER: largest population Nashville_davidson, smallest Morristown, TN
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population AS p
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

--5c ANSWER: Sevier County, population: 95523
SELECT county, cbsa, population
FROM population
FULL JOIN cbsa
USING (fipscounty)
FULL JOIN fips_county
USING (fipscounty)
WHERE cbsa IS null
ORDER BY population DESC NULLS LAST;

--QUESTION 6
SELECT d.drug_name, total_claim_count, 
CONCAT(nppes_provider_first_name,' ',nppes_provider_last_org_name) AS provider_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END AS opioid
	FROM drug AS d
	FULL JOIN prescription AS p
	ON d.drug_name = p.drug_name
	FULL JOIN prescriber
	ON prescriber.npi = p.npi
	WHERE total_claim_count >= 3000
	ORDER BY total_claim_count DESC;
	
--QUESTION 7a to group by or no? either way yields 637
SELECT prescriber.npi, drug_name 
FROM drug 
CROSS JOIN prescriber
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug_name
ORDER BY npi DESC
	
--7b, 7c
SELECT prescriber.npi, drug.drug_name, COALESCE(SUM(total_claim_count),0) AS total_claim
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
USING (npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name
ORDER BY total_claim DESC


