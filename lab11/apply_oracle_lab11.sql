-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab11.sql
--  Lab Assignment: Lab #11
--  Program Author: Michael McLaughlin
--  Creation Date:  02-Mar-2018
-- ------------------------------------------------------------------
-- Instructions:
-- ------------------------------------------------------------------
-- The two scripts contain spooling commands, which is why there
-- isn't a spooling command in this script. When you run this file
-- you first connect to the Oracle database with this syntax:
--
--   sqlplus student/student@xe
--
-- Then, you call this script with the following syntax:
--
--   sql> @apply_oracle_lab11.sql
--
-- ------------------------------------------------------------------

-- ------------------------------------------------------------------
-- Call the prior lab.
-- ------------------------------------------------------------------
 
@@/home/student/Data/cit225/oracle/lab9/apply_oracle_lab9.sql
 
-- Open log file.  
SPOOL apply_oracle_lab8.txt
 
-- --------------------------------------------------------
--  Step #1
--  -------
--  Using the query from Lab 10, Step 1, insert the query
--  in the MERGE statement to the RENTAL table.
-- --------------------------------------------------------
 
-- Insert step #1 statements here.
 MERGE INTO rental target
USING ( SELECT DISTINCT
             r.rental_id
      ,      c.contact_id
      ,      TRUNC(tu.check_out_date) AS check_out_date
      ,      TRUNC(tu.return_date) AS return_date
      ,      1001 AS created_by
      ,      TRUNC(SYSDATE) AS creation_date
      ,      1001 AS last_updated_by
      ,      TRUNC(SYSDATE) AS last_update_date
      FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number LEFT JOIN rental r
      ON   c.contact_id = r.customer_id
      AND  TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
      AND  TRUNC(tu.return_date) = TRUNC(r.return_date) ) source
ON (target.rental_id = source.rental_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( rental_s1.nextval
,      source.contact_id
,      source.check_out_date
,      source.return_date
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date);


-- Test part 1
SELECT   TO_CHAR(COUNT(*),'99,999') AS "Rental after merge"
FROM     rental;
-- End Test part 1


-- --------------------------------------------------------
--  Step #2
--  -------
--  Using the query from Lab 10, Step 2, insert the query
--  in the MERGE statement to the RENTAL_ITEM table.
-- --------------------------------------------------------
 
-- Insert step #2 statements here.
MERGE INTO rental_item target
USING ( SELECT   ri.rental_item_id
,       r.rental_id
         ,        tu.item_id
         ,        TRUNC(r.return_date) - TRUNC(r.check_out_date) AS rental_item_price
         ,        cl.common_lookup_id AS rental_item_type
         ,        1001 AS created_by
         ,        TRUNC(SYSDATE) AS creation_date
         ,        1001 AS last_updated_by
         ,        TRUNC(SYSDATE) AS last_update_date
         FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number  INNER JOIN common_lookup cl
        ON cl.common_lookup_type = tu.rental_item_type
        AND cl.common_lookup_table = 'RENTAL_ITEM'
        AND cl.common_lookup_column = 'RENTAL_ITEM_TYPE' INNER JOIN rental r
      ON   r.customer_id = c.contact_id 
      AND  TRUNC(r.check_out_date) = TRUNC(tu.check_out_date)
      AND  TRUNC(r.return_date) = TRUNC(tu.return_date) LEFT JOIN rental_item ri
        ON ri.rental_id = r.rental_id ) source
ON (target.rental_item_id = source.rental_item_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( rental_item_s1.nextval
, source.rental_id
,      source.item_id
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date
,      source.rental_item_price
,      source.rental_item_type);

-- Test Part 2
SELECT   TO_CHAR(COUNT(*),'99,999') AS "Rental Item after merge"
FROM     rental_item;
-- End Test Part 2
 
-- --------------------------------------------------------
--  Step #3
--  -------
--  Using the query from Lab 10, Step 3, insert the query
--  in the MERGE statement to the TRANSACTION table.
-- --------------------------------------------------------
 
-- Insert step #3 statements here.
MERGE INTO transaction target
USING (SELECT t.transaction_id AS transaction_id
      ,      tu.payment_account_number AS transaction_account
      ,      cl1.common_lookup_id AS transaction_type
      ,      TRUNC(tu.transaction_date) AS transaction_date
 --     ,      SUM(tu.transaction_amount) OVER (PARTITION BY r.rental_id) AS transaction_amount
      ,      SUM(tu.transaction_amount / 1.06) AS transaction_amount
      ,      r.rental_id
      ,      cl2.common_lookup_id AS payment_method_type
      ,      m.credit_card_number as payment_account_number
      ,      1001 AS created_by
      ,      TRUNC(SYSDATE) AS creation_date
      ,      1001 AS last_updated_by
      ,      TRUNC(SYSDATE) AS last_update_date
      FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number INNER JOIN rental r
      ON   c.contact_id = r.customer_id
      AND  TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
      AND  TRUNC(tu.return_date) = TRUNC(r.return_date)INNER JOIN common_lookup cl1
ON      cl1.common_lookup_table = 'TRANSACTION'
AND     cl1.common_lookup_column = 'TRANSACTION_TYPE'
AND     cl1.common_lookup_type = tu.transaction_type INNER JOIN common_lookup cl2
ON      cl2.common_lookup_table = 'TRANSACTION'
AND     cl2.common_lookup_column = 'PAYMENT_METHOD_TYPE'
AND     cl2.common_lookup_type = tu.payment_method_type LEFT JOIN transaction t
ON t.TRANSACTION_ACCOUNT = tu.payment_account_number
AND t.TRANSACTION_TYPE = cl1.common_lookup_id
AND t.TRANSACTION_DATE = tu.transaction_date
AND t.TRANSACTION_AMOUNT = tu.TRANSACTION_AMOUNT
AND t.PAYMENT_METHOD_type = cl2.common_lookup_id
AND t.PAYMENT_ACCOUNT_NUMBER = m.credit_card_number
GROUP BY t.transaction_id, m.credit_card_number, cl1.common_lookup_id, tu.transaction_date,
r.rental_id, cl2.common_lookup_id, tu.payment_account_number) source
ON (target.transaction_id = source.transaction_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( transaction_s1.nextval
,      source.transaction_account
,      source.transaction_type
,      source.transaction_date
,      source.transaction_amount
,      source.rental_id
,      source.payment_method_type
,      source.payment_account_number
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date);

-- Test Part 3
SELECT   TO_CHAR(COUNT(*),'99,999') AS "Transaction after merge"
FROM     transaction;
-- End Test Part 3
 
-- --------------------------------------------------------
--  Step #4
--  -------
--  Insert the MERGE statements to the RENTAL, RENTAL_ITEM,
--  and TRANSACTION tables into the UPLOAD_TRANSACTION
--  procedure; execute the UPLOAD_TRANSACTION procedure,
--  and query the results from the target tables; and
--  re-execute the UPLOAD_TRANSACTION procedure to
--  verify that the query returns the same set and only
--  inserts new records.
-- --------------------------------------------------------
 
-- Insert step #4 statements here.
-- Start Test part 4a
-- Create a procedure to wrap the transaction.
CREATE OR REPLACE PROCEDURE upload_transaction IS 
BEGIN
  -- Set save point for an all or nothing transaction.
  SAVEPOINT starting_point;
 
  -- Merge into RENTAL table.
  MERGE INTO rental target
USING ( SELECT DISTINCT
             r.rental_id
      ,      c.contact_id
      ,      TRUNC(tu.check_out_date) AS check_out_date
      ,      TRUNC(tu.return_date) AS return_date
      ,      1001 AS created_by
      ,      TRUNC(SYSDATE) AS creation_date
      ,      1001 AS last_updated_by
      ,      TRUNC(SYSDATE) AS last_update_date
      FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number LEFT JOIN rental r
      ON   c.contact_id = r.customer_id
      AND  TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
      AND  TRUNC(tu.return_date) = TRUNC(r.return_date) ) source
ON (target.rental_id = source.rental_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( rental_s1.nextval
,      source.contact_id
,      source.check_out_date
,      source.return_date
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date);
 
  -- Merge into RENTAL_ITEM table.
  MERGE INTO rental_item target
USING ( SELECT   ri.rental_item_id
,       r.rental_id
         ,        tu.item_id
         ,        TRUNC(r.return_date) - TRUNC(r.check_out_date) AS rental_item_price
         ,        cl.common_lookup_id AS rental_item_type
         ,        3 AS created_by
         ,        TRUNC(SYSDATE) AS creation_date
         ,        3 AS last_updated_by
         ,        TRUNC(SYSDATE) AS last_update_date
         FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number  INNER JOIN common_lookup cl
        ON cl.common_lookup_type = tu.rental_item_type
        AND cl.common_lookup_table = 'RENTAL_ITEM'
        AND cl.common_lookup_column = 'RENTAL_ITEM_TYPE' INNER JOIN rental r
      ON   r.customer_id = c.contact_id 
      AND  TRUNC(r.check_out_date) = TRUNC(tu.check_out_date)
      AND  TRUNC(r.return_date) = TRUNC(tu.return_date) LEFT JOIN rental_item ri
        ON ri.rental_id = r.rental_id ) source
ON (target.rental_item_id = source.rental_item_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( rental_item_s1.nextval
, source.rental_id
,      source.item_id
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date
,      source.rental_item_price
,      source.rental_item_type);
 
  -- Merge into TRANSACTION table.
  MERGE INTO transaction target
USING (SELECT t.transaction_id AS transaction_id
      ,       tu.payment_account_number AS transaction_account
      ,      cl1.common_lookup_id AS transaction_type
      ,      TRUNC(tu.transaction_date) AS transaction_date
 --     ,      SUM(tu.transaction_amount) OVER (PARTITION BY r.rental_id) AS transaction_amount
      ,      SUM(tu.transaction_amount / 1.06) AS transaction_amount
      ,      r.rental_id
      ,      cl2.common_lookup_id AS payment_method_type
      ,      m.credit_card_number as payment_account_number
      ,      1001 AS created_by
      ,      TRUNC(SYSDATE) AS creation_date
      ,      1001 AS last_updated_by
      ,      TRUNC(SYSDATE) AS last_update_date
      FROM member m INNER JOIN contact c
      ON   m.member_id = c.member_id INNER JOIN transaction_upload tu
      ON   c.first_name = tu.first_name
      AND  NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
      AND  c.last_name = tu.last_name
      AND  tu.account_number = m.account_number INNER JOIN rental r
      ON   c.contact_id = r.customer_id
      AND  TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
      AND  TRUNC(tu.return_date) = TRUNC(r.return_date)INNER JOIN common_lookup cl1
ON      cl1.common_lookup_table = 'TRANSACTION'
AND     cl1.common_lookup_column = 'TRANSACTION_TYPE'
AND     cl1.common_lookup_type = tu.transaction_type INNER JOIN common_lookup cl2
ON      cl2.common_lookup_table = 'TRANSACTION'
AND     cl2.common_lookup_column = 'PAYMENT_METHOD_TYPE'
AND     cl2.common_lookup_type = tu.payment_method_type LEFT JOIN transaction t
ON t.TRANSACTION_ACCOUNT = tu.payment_account_number
AND t.TRANSACTION_TYPE = cl1.common_lookup_id
AND t.TRANSACTION_DATE = tu.transaction_date
AND t.TRANSACTION_AMOUNT = tu.TRANSACTION_AMOUNT
AND t.PAYMENT_METHOD_type = cl2.common_lookup_id
AND t.PAYMENT_ACCOUNT_NUMBER = m.credit_card_number
GROUP BY t.transaction_id, m.credit_card_number, cl1.common_lookup_id, tu.transaction_date,
r.rental_id, cl2.common_lookup_id, tu.payment_account_number) source
ON (target.transaction_id = source.transaction_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( transaction_s1.nextval
,      source.transaction_account
,      source.transaction_type
,      source.transaction_date
,      source.transaction_amount
,      source.rental_id
,      source.payment_method_type
,      source.payment_account_number
,      source.created_by
,      source.creation_date
,      source.last_updated_by
,      source.last_update_date);
 
  -- Save the changes.
  COMMIT;
 
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO starting_point;
    RETURN;
END;
/
-- End Part 4a
 
-- Start Part 4b
EXECUTE upload_transaction;
-- End Part 4b

-- Start Part 4c
COLUMN rental_count      FORMAT 99,999 HEADING "Rental|Count"
COLUMN rental_item_count FORMAT 99,999 HEADING "Rental|Item|Count"
COLUMN transaction_count FORMAT 99,999 HEADING "Transaction|Count"
 
SELECT   il1.rental_count
,        il2.rental_item_count
,        il3.transaction_count
FROM    (SELECT COUNT(*) AS rental_count FROM rental) il1 CROSS JOIN
        (SELECT COUNT(*) AS rental_item_count FROM rental_item) il2 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM TRANSACTION) il3;
-- End Part 4c

-- Start Part 4d
EXECUTE upload_transaction;
-- End Part 4d

-- Start Part 4e
COLUMN rental_count      FORMAT 99,999 HEADING "Rental|Count"
COLUMN rental_item_count FORMAT 99,999 HEADING "Rental|Item|Count"
COLUMN transaction_count FORMAT 99,999 HEADING "Transaction|Count"
 
SELECT   il1.rental_count
,        il2.rental_item_count
,        il3.transaction_count
FROM    (SELECT COUNT(*) AS rental_count FROM rental) il1 CROSS JOIN
        (SELECT COUNT(*) AS rental_item_count FROM rental_item) il2 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM TRANSACTION) il3;
-- End part 4e
-- --------------------------------------------------------
--  Step #5
--  -------
--  Write a query that uses date functions to report
--  aggregated transaction amount values for base revenue,
--  110% of revenue, 120% of revenue, 90% of revenue,
--  80% or revenue.
-- --------------------------------------------------------
 
-- Insert step #5 statements here.
SET LINESIZE 100
COLUMN month                FORMAT A15 HEADING "MONTH"
COLUMN BASE_REVENUE         FORMAT A15 HEADING "BASE_REVENUE"
COLUMN TEN_PLUS             FORMAT A15 HEADING "10_PLUS"
COLUMN twenty_plus          FORMAT A15 HEADING "20_PLUS"
COLUMN ten_plus_less_b      FORMAT A15 HEADING "10_PLUS_LESS_B"
COLUMN twenty_plus_less_b   FORMAT A15 HEADING "20_PLUS_LESS_B"

 SELECT il.MONTH
,       il.BASE_REVENUE
,       il.ten_plus AS "10_PLUS"
,       il.twenty_plus AS "20_PLUS"
,       il.ten_plus_less_b AS "10_PLUS_LESS_B"
,       il.twenty_plus_less_b AS "20_PLUS_LESS_B"
FROM (SELECT CONCAT(TO_CHAR(t.transaction_Date,'MON'),CONCAT('-',EXTRACT(YEAR FROM t.transaction_date))) AS MONTH
,       EXTRACT(MONTH FROM TRUNC(t.transaction_date)) AS sortkey
,       TO_CHAR(SUM(t.transaction_amount),'$9,999,999.00') AS BASE_REVENUE
,       TO_CHAR(SUM(t.transaction_amount + (t.transaction_amount * .1)),'$9,999,999.00') AS ten_plus
,       TO_CHAR(SUM(t.transaction_amount + (t.transaction_amount * .2)),'$9,999,999.00') AS twenty_plus
,       TO_CHAR(SUM(t.transaction_amount + (t.transaction_amount * .1)) -
                SUM(t.transaction_amount),'$9,999,999.00') AS ten_plus_less_b
,       TO_CHAR(SUM(t.transaction_amount + (t.transaction_amount * .2)) -
                SUM(t.transaction_amount),'$9,999,999.00') AS twenty_plus_less_b
FROM transaction t 
WHERE EXTRACT(YEAR FROM TRUNC(t.transaction_date)) = 2009
GROUP BY CONCAT(TO_CHAR(t.transaction_Date,'MON'),CONCAT('-',EXTRACT(YEAR FROM t.transaction_date)))
, EXTRACT(MONTH FROM TRUNC(t.transaction_date))) il
ORDER BY il.sortkey;
-- Close log file.
SPOOL OFF
 
-- Make all changes permanent.
COMMIT;
