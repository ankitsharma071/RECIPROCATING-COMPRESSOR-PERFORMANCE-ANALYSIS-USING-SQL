-- ====================================================================================
-- QUESTION 1:
-- How does increasing the pressure ratio (PR) impact compressor volumetric (eta_vol) 
-- and isentropic (eta_is) efficiencies, and what is the optimal PR operating range?
-- ====================================================================================

SELECT
    CASE
        WHEN pressure_ratio >= 1 AND pressure_ratio < 2 THEN '01-02'
        WHEN pressure_ratio >= 2 AND pressure_ratio < 3 THEN '02-03'
        WHEN pressure_ratio >= 3 AND pressure_ratio < 4 THEN '03-04'
        WHEN pressure_ratio >= 4 AND pressure_ratio < 5 THEN '04-05'
        WHEN pressure_ratio >= 5 AND pressure_ratio < 6 THEN '05-06'
        WHEN pressure_ratio >= 6 AND pressure_ratio < 7 THEN '06-07'
        WHEN pressure_ratio >= 7 AND pressure_ratio < 8 THEN '07-08'
        WHEN pressure_ratio >= 8 AND pressure_ratio < 9 THEN '08-09'
        WHEN pressure_ratio >= 9 AND pressure_ratio < 10 THEN '09-10'
        WHEN pressure_ratio >= 10 AND pressure_ratio < 12 THEN '10-12'
        WHEN pressure_ratio >= 12 AND pressure_ratio < 15 THEN '12-15'
        ELSE '15+'
    END AS PR_range,

    COUNT(*) AS data_points,
    ROUND(AVG(eta_vol), 4) AS avg_volumetric_eff,
    ROUND(AVG(eta_is), 4) AS avg_isentropic_eff,
    ROUND(MIN(eta_is), 4) AS min_isentropic_eff,
    ROUND(MAX(eta_is), 4) AS max_isentropic_eff

FROM compressor_analysis
WHERE pressure_ratio >= 1 
  AND eta_is BETWEEN 0 AND 1 
  AND eta_vol BETWEEN 0 AND 1
GROUP BY 1
ORDER BY MIN(pressure_ratio);


-- ====================================================================================
-- QUESTION 2:
-- What is the effect of suction gas superheat (DeltaT_sh) on suction density, 
-- volumetric flow degradation, and internal cylinder heat transfer losses?
-- ====================================================================================

SELECT
    CASE
        WHEN DeltaT_sh_K < 10 THEN '01. <10 K'
        WHEN DeltaT_sh_K BETWEEN 10 AND 15 THEN '02. 10-15 K'
        WHEN DeltaT_sh_K BETWEEN 15 AND 20 THEN '03. 15-20 K'
        WHEN DeltaT_sh_K BETWEEN 20 AND 25 THEN '04. 20-25 K'
        WHEN DeltaT_sh_K BETWEEN 25 AND 30 THEN '05. 25-30 K'
        WHEN DeltaT_sh_K BETWEEN 30 AND 35 THEN '06. 30-35 K'
        WHEN DeltaT_sh_K BETWEEN 35 AND 40 THEN '07. 35-40 K'
        WHEN DeltaT_sh_K BETWEEN 40 AND 45 THEN '08. 40-45 K'
        WHEN DeltaT_sh_K BETWEEN 45 AND 50 THEN '09. 45-50 K'
        ELSE '10. 50+ K'
    END AS superheat_range,

    COUNT(*) AS data_points,
    ROUND(AVG(pressure_ratio), 2) AS avg_PR,
    ROUND(AVG(eta_vol), 4) AS avg_volumetric_eff,
    ROUND(AVG(eta_is), 4) AS avg_isentropic_eff

FROM compressor_analysis
WHERE DeltaT_sh_K IS NOT NULL
  AND eta_is BETWEEN 0 AND 1 
  AND eta_vol BETWEEN 0 AND 1
GROUP BY 1
ORDER BY superheat_range;

-- ====================================================================================
-- QUESTION 3:
-- How do eco-friendly refrigerants (Propene, Propane, CO2, R1234ze(E)) benchmark 
-- against legacy R134a in terms of overall average volumetric and isentropic performance?
-- ====================================================================================


SELECT 
    refrigerant,
    COUNT(*) AS total_points,
    ROUND(AVG(pressure_ratio), 2) AS avg_pressure_ratio,
    ROUND(AVG(eta_vol), 4) AS avg_volumetric_eff,
    ROUND(AVG(eta_is), 4) AS avg_isentropic_eff
FROM compressor_analysis
WHERE eta_vol BETWEEN 0 AND 1 
  AND eta_is BETWEEN 0 AND 1
GROUP BY refrigerant
HAVING COUNT(*) >= 200
ORDER BY avg_isentropic_eff DESC;


-- ====================================================================================
-- QUESTION 4:
-- How does efficiency degradation across pressure ratio ranges vary for each 
-- individual working fluid (Propene, Propane, R134a, R1234ze(E), and CO2)?
-- ====================================================================================

SELECT 
    refrigerant,
    CASE
        WHEN pressure_ratio >= 1 AND pressure_ratio < 2 THEN '01-02'
        WHEN pressure_ratio >= 2 AND pressure_ratio < 3 THEN '02-03'
        WHEN pressure_ratio >= 3 AND pressure_ratio < 4 THEN '03-04'
        WHEN pressure_ratio >= 4 AND pressure_ratio < 5 THEN '04-05'
        WHEN pressure_ratio >= 5 AND pressure_ratio < 6 THEN '05-06'
        WHEN pressure_ratio >= 6 AND pressure_ratio < 7 THEN '06-07'
        WHEN pressure_ratio >= 7 AND pressure_ratio < 8 THEN '07-08'
        WHEN pressure_ratio >= 8 AND pressure_ratio < 9 THEN '08-09'
        WHEN pressure_ratio >= 9 AND pressure_ratio < 10 THEN '09-10'
        WHEN pressure_ratio >= 10 AND pressure_ratio < 12 THEN '10-12'
        WHEN pressure_ratio >= 12 AND pressure_ratio < 15 THEN '12-15'
        ELSE '15+'
    END AS PR_range,

    COUNT(*) AS data_points,
    ROUND(AVG(eta_vol), 4) AS avg_vol_eff,
    ROUND(AVG(eta_is), 4) AS avg_is_eff

FROM compressor_analysis
WHERE LOWER(refrigerant) IN ('r134a', 'r1234ze(e)', 'propane', 'propene', 'co2')
  AND pressure_ratio >= 1
  AND eta_is BETWEEN 0 AND 1
GROUP BY refrigerant, PR_range
ORDER BY refrigerant, MIN(pressure_ratio);



-- ====================================================================================
-- QUESTION 5:
-- Which refrigerant provides the highest efficiency across specific application 
-- zones: Low-Temp Freezing (<-20 C), Medium-Temp Commercial (-20 to 0 C), and 
-- High-Temp Air Conditioning (>0 C)?
-- ====================================================================================

SELECT 
    CASE 
        WHEN T_ev_C < -20 THEN '1. Low Temp (Freezing: <-20 C)'
        WHEN T_ev_C BETWEEN -20 AND 0 THEN '2. Medium Temp (Refrig: -20 to 0 C)'
        ELSE '3. High Temp (AC/Chiller: >0 C)'
    END AS application_zone,
    refrigerant,
    COUNT(*) AS sample_points,
    ROUND(AVG(p_dis_bar / p_suc_bar), 2) AS avg_pressure_ratio,
    ROUND(AVG(eta_vol), 3) AS avg_vol_eff,
    ROUND(AVG(eta_is), 3) AS avg_is_eff
FROM compressor_analysis
WHERE LOWER(refrigerant) IN ('r134a', 'r1234ze(e)', 'propane', 'propene', 'co2')
  AND eta_is BETWEEN 0 AND 1 
  AND eta_vol BETWEEN 0 AND 1
GROUP BY application_zone, refrigerant
ORDER BY application_zone, avg_is_eff DESC;