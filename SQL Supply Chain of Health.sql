SELECT * FROM supply_chain_shipment;

-- Check for duplicated data
WITH dup_cte as(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY id,project_code,pq,po_so ,asn_dn,country,managed_by,fulfill_via,vendor_inco_term,shipment_mode,pq_first_sent_to_client_date,po_sent_to_vendor_date,
scheduled_delivery_date,delivered_to_client_date,delivery_recorded_date,product_group,sub_classification,vendor,item_description,molecule_test_type,brand,dosage,dosage_form,unit_of_measure_per_pack,
line_item_quantity,line_item_value,pack_price,unit_price,manufacturing_site,first_line_designation,weight_kilograms,freight_cost_usd,line_item_insurance_usd ORDER BY id) AS row_num 
FROM supply_chain_shipment)
SELECT * FROM dup_cte 
WHERE row_num > 1;


-- Check the data type of the columns and inspect all columns
-- Normalize country names
ALTER TABLE supply_chain_shipment
ALTER COLUMN unit_of_measure_per_pack INT;

SELECT * FROM supply_chain_shipment;

SELECT DISTINCT country , 
CASE WHEN country = 'Congo, DRC' THEN 'DR Congo' ELSE country END AS country
FROM supply_chain_shipment;

UPDATE supply_chain_shipment
SET country = CASE WHEN country = 'Congo, DRC' THEN 'DR Congo' ELSE country END;

-- Check the format of the date sent to the vendor
SELECT po_sent_to_vendor_date, CASE WHEN  
po_sent_to_vendor_date = FORMAT(CAST(po_sent_to_vendor_date AS DATE), 'yyyy-MM-dd') THEN po_sent_to_vendor_date
ELSE po_sent_to_vendor_date END AS po_sent_to_vendor_date
FROM supply_chain_shipment;

UPDATE supply_chain_shipment
SET po_sent_to_vendor_date = CASE WHEN  
po_sent_to_vendor_date = FORMAT(CAST(po_sent_to_vendor_date AS DATE), 'yyyy-MM-dd') THEN po_sent_to_vendor_date
ELSE po_sent_to_vendor_date END;

-- Check for NULL values and fill in
SELECT id, asn_dn, weight_kilograms FROM supply_chain_shipment
WHERE weight_kilograms LIKE 'SEE DN-%';

SELECT id, asn_dn, freight_cost_usd FROM supply_chain_shipment
WHERE freight_cost_usd LIKE 'See DN-%' OR freight_cost_usd LIKE 'See ASN-%';

-- Retrieve weight information from reference records
/*
SELECT s1.id,
       s1.asn_dn,
       s1.weight_kilograms,
       s2.id AS ReferencedID,
       s2.asn_dn AS ReferencedASN,
       s2.weight_kilograms AS NewWeight
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.weight_kilograms LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn
WHERE ISNUMERIC(s2.weight_kilograms) = 1;


UPDATE s1
SET s1.weight_kilograms = s2.weight_kilograms
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.weight_kilograms LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn
WHERE ISNUMERIC(s2.weight_kilograms) = 1;
*/ 

-- Check and Update weight values from reference records
-- Check and Update freight_cost_usd values from reference records
SELECT s1.id,
       s1.asn_dn,
       s1.freight_cost_usd,
       s2.id AS ReferencedID,
       s2.asn_dn AS ReferencedASN,
       s2.freight_cost_usd AS NewWeight
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.freight_cost_usd LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn
WHERE ISNUMERIC(s2.freight_cost_usd) = 1;

SELECT s1.id,
       s1.asn_dn,
       s1.weight_kilograms,
       s2.id AS ReferencedID,
       s2.asn_dn AS ReferencedASN,
       CASE
           WHEN ISNUMERIC(s2.weight_kilograms) = 1 THEN s2.weight_kilograms 
           ELSE s2.weight_kilograms 
       END AS NewWeight
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.weight_kilograms LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn;

SELECT s1.id,
       s1.asn_dn,
       s1.freight_cost_usd,
       s2.id AS ReferencedID,
       s2.asn_dn AS ReferencedASN,
       CASE
           WHEN ISNUMERIC(s2.freight_cost_usd) = 1 THEN s2.freight_cost_usd -- Value Number
           ELSE s2.freight_cost_usd -- Value String
       END AS NewFreight
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.freight_cost_usd LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn;

UPDATE s1
SET s1.weight_kilograms = CASE
           WHEN ISNUMERIC(s2.weight_kilograms) = 1 THEN s2.weight_kilograms 
           ELSE s2.weight_kilograms END
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.weight_kilograms LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn;

UPDATE s1
SET s1.freight_cost_usd = CASE
           WHEN ISNUMERIC(s2.freight_cost_usd) = 1 THEN s2.freight_cost_usd 
           ELSE s2.freight_cost_usd END
FROM supply_chain_shipment s1
INNER JOIN supply_chain_shipment s2
    ON s1.freight_cost_usd LIKE '%ID#:' + CAST(s2.id AS VARCHAR) + '%'
    AND s1.asn_dn = s2.asn_dn;

SELECT DISTINCT(molecule_test_type), freight_cost_usd 
FROM supply_chain_shipment
WHERE freight_cost_usd = 'Invoiced Separately' OR freight_cost_usd = 'Freight Included in Commodity Cost'
ORDER BY molecule_test_type;

SELECT molecule_test_type,line_item_value, freight_cost_usd,
CASE WHEN freight_cost_usd = 'Invoiced Separately' THEN 0 
    WHEN freight_cost_usd = 'Freight Included in Commodity Cost' THEN line_item_value
    ELSE freight_cost_usd
    END AS new_freight
FROM supply_chain_shipment;

UPDATE supply_chain_shipment
SET freight_cost_usd = CASE WHEN freight_cost_usd = 'Invoiced Separately' THEN 0 
    WHEN freight_cost_usd = 'Freight Included in Commodity Cost' THEN line_item_value
    ELSE freight_cost_usd
    END;

ALTER TABLE supply_chain_shipment
ALTER COLUMN freight_cost_usd FLOAT;

SELECT weight_kilograms,CASE WHEN weight_kilograms ='Weight Captured Separately' THEN 0 ELSE weight_kilograms END as weight_kilograms
FROM supply_chain_shipment
WHERE weight_kilograms ='Weight Captured Separately';

UPDATE supply_chain_shipment
SET weight_kilograms = CASE WHEN weight_kilograms ='Weight Captured Separately' THEN 0 ELSE weight_kilograms END;
ALTER TABLE supply_chain_shipment
ALTER COLUMN weight_kilograms FLOAT;


SELECT line_item_insurance_usd, 
CASE WHEN line_item_insurance_usd IS NULL THEN 0 ELSE line_item_insurance_usd END AS line_item_insurance_usd
FROM supply_chain_shipment
WHERE line_item_insurance_usd IS NULL;

UPDATE supply_chain_shipment
SET line_item_insurance_usd = CASE WHEN line_item_insurance_usd IS NULL THEN 0 ELSE line_item_insurance_usd END;

SELECT DISTINCT (brand) ,dosage,dosage_form
FROM supply_chain_shipment
ORDER BY brand;

-- Remove unnecessary columns or rows
ALTER TABLE supply_chain_shipment
DROP COLUMN id;

-- Explore the data
SELECT * FROM supply_chain_shipment;

-- Analyze delivery time
SELECT vendor,scheduled_delivery_date,delivered_to_client_date, DATEDIFF(DAY,scheduled_delivery_date,delivered_to_client_date) as divide_date
FROM supply_chain_shipment
WHERE DATEDIFF(DAY,scheduled_delivery_date,delivered_to_client_date) < 0;

SELECT asn_dn, DATEDIFF(DAY,delivery_recorded_date,delivered_to_client_date) as record_date
FROM supply_chain_shipment
WHERE DATEDIFF(DAY,delivery_recorded_date,delivered_to_client_date) > 0;

SELECT YEAR(delivered_to_client_date) AS year_delivered ,
    count(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance
FROM supply_chain_shipment
GROUP BY YEAR(delivered_to_client_date)
ORDER BY YEAR(delivered_to_client_date);


-- Calculate total quantity and values by year
SELECT -- FORMAT(delivered_to_client_date,'yyyy-MM') AS month_year,
        YEAR(delivered_to_client_date) AS year_delivered , 
        ROUND(sum(line_item_value),2) as sum_value,
        SUM(ROUND(sum(line_item_value),2)) OVER(ORDER BY YEAR(delivered_to_client_date)) AS target_to_now
        -- DENSE_RANK() OVER(PARTITION BY YEAR(delivered_to_client_date) ORDER BY ROUND(sum(line_item_value),2) DESC) AS dense_sum_line
FROM supply_chain_shipment
GROUP BY -- FORMAT(delivered_to_client_date,'yyyy-MM'),
    YEAR(delivered_to_client_date);
-- ORDER BY month_year;

WITH total_revenue AS(
SELECT molecule_test_type,line_item_value, freight_cost_usd, line_item_insurance_usd, ROUND((freight_cost_usd + line_item_insurance_usd),2) as total_insurance
FROM supply_chain_shipment),
freight_percent AS(
    SELECT *, total_insurance/NULLIF(freight_cost_usd,0) * 100  AS percent_freight_cost
FROM total_revenue
) SELECT *,CASE WHEN percent_freight_cost IS NULL THEN 0 ELSE ROUND(percent_freight_cost,2) END AS percent_freight_cost
 FROM freight_percent
 ORDER BY total_insurance;

ALTER TABLE supply_chain_shipment
ADD total_freight_insurance FLOAT;

UPDATE supply_chain_shipment
SET total_freight_insurance = freight_cost_usd + line_item_insurance_usd;

-- Summarize by country
SELECT country,
    fulfill_via,
    count(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance,
    RANK() OVER(ORDER BY count(line_item_quantity) DESC) AS rank_quantity,
    ROW_NUMBER() OVER(ORDER BY ROUND(sum(line_item_value),2) DESC) AS row_value,
    ROW_NUMBER() OVER(ORDER BY ROUND(sum(freight_cost_usd),2) DESC) AS row_freight,
    ROW_NUMBER() OVER(ORDER BY ROUND(sum(line_item_insurance_usd),2) DESC) AS row_insurance
FROM supply_chain_shipment
WHERE fulfill_via = 'FROM RDC' -- fullfill_via = 'Direct Drop'
GROUP BY country,
fulfill_via;
--ORDER BY COUNTRY DESC; 


-- Summarize by fulfill_via
SELECT fulfill_via,
    count(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance
FROM supply_chain_shipment
GROUP BY 
fulfill_via;

-- Summarize by shipment mode 
SELECT COALESCE(shipment_mode,'No-information') as shipment_mode,
    COUNT(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance
FROM supply_chain_shipment
GROUP BY COALESCE(shipment_mode,'No-information')
ORDER BY shipment_mode;

-- Summarize by product group
SELECT product_group,
    COUNT(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance
FROM supply_chain_shipment
GROUP BY product_group
ORDER BY product_group;

-- Summarize by brand, dosage, and dosage form
SELECT brand, dosage,dosage_form,
        COUNT(line_item_quantity) AS count_quantity,    
    ROUND(sum(line_item_value),2) AS sum_value, 
    ROUND(sum(freight_cost_usd),2) AS sum_freight,
    ROUND(sum(line_item_insurance_usd),2) AS sum_insurance
FROM supply_chain_shipment
-- WHERE dosage IS NULL
GROUP BY brand,dosage,dosage_form
ORDER BY brand;

-- Count by first line designation
select first_line_designation,COUNT(first_line_designation) AS amount from supply_chain_shipment 
GROUP BY first_line_designation;

