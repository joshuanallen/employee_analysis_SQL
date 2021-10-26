-- Separate the two “login_id’s into different columns.
-- Label one column “phone_id” (id with four numbers) and the other “chat_id” (id that starts with “005”)
-- Example: chat_id = 00550000000ssw5AAA AND phone_id = 4524

-- Create separate table with chat login ids
SELECT empno, login_id as chat_id
INTO chat_id_tbl
FROM emp
WHERE login_id LIKE '005%';

-- Create separate table with phone login ids
SELECT empno, login_id as phone_id
INTO phone_id_tbl
FROM emp
WHERE LENGTH(login_id) = 4;

-- Change the format of the “ENAME” & “MNAME” column to “First Name and Last Name”
-- (e.g., Peter Parker) and sort “JOB” in ascending order but make sure “President” is at the top of the list.
-- Employee name column alteration from "LastName, FirstName" to "FirstName LastName"
-- Create table with correctly formatted employee names
SELECT DISTINCT (empno),
-- 	PostgreSQL does not use String_Split function so used their version which is SPLIT_PART
	SPLIT_PART(ename,', ',2)|| ' ' || SPLIT_PART(ename,', ',1) AS ename 
INTO ename_split
FROM emp
WHERE ename IS NOT NULL;


-- Manager name column alteration from "LastName, FirstName" to "FirstName LastName"
SELECT DISTINCT (mgr),
	SPLIT_PART(mname,', ',2)|| ' ' || SPLIT_PART(mname,', ',1) AS mname 
INTO mname_split
FROM emp
WHERE mname IS NOT NULL;

-- Date conversion table for calculating tenure and "hiredate" format manipulation
SELECT DISTINCT (empno),
	-- PostgreSQL does not use DateDiff function so used their version which is AGE and has a default output
	AGE('2021-05-03', hiredate) as etenure,
	-- PostgreSQL 11 has preset date format that is difficult to change. Work around by converting to string format. DATE_PART function works similar to EXTRACT() function in PostgreSQL 11.
	DATE_PART('day', hiredate) || '-' || date_part('month', hiredate) || '-' || date_part('year', hiredate) as hiredate
INTO emp_tenure
FROM emp;

-- Combine all edited pieces into new clean table "emp_clean"
SELECT DISTINCT (e.empno),
	es.ename,
	e.job,
	e.mgr,
	ms.mname,
	et.hiredate,
	et.etenure,
	e.sal,
	e.commission,
	e.team_name,
	cht.chat_id,
	phn.phone_id

INTO emp_clean
FROM emp as e
-- join chat_id_tbl to add chat_id column
LEFT JOIN chat_id_tbl as cht
ON e.empno = cht.empno
-- join phone_id_tbl to add phone_id column
LEFT JOIN phone_id_tbl as phn
ON e.empno = phn.empno
-- join ename_split to add fixed ename column
LEFT JOIN ename_split as es
ON e.empno = es.empno
-- join mname_split to add fixed mname column
LEFT JOIN mname_split as ms
ON e.mgr = ms.mgr
-- join emp_tenure
LEFT JOIN emp_tenure as et
ON e.empno = et.empno;


-- Populate null values with appropriate filler.
-- Numerical values are chaned from "null" to "0"
UPDATE emp_clean
SET mgr = 0
WHERE
mgr IS NULL;

UPDATE emp_clean
SET commission = 0
WHERE
commission IS NULL;

-- string values are changed from "null" to "none."
UPDATE emp_clean
SET mname = 'none'
WHERE
mname IS NULL;

UPDATE emp_clean
SET chat_id = 'none'
WHERE
chat_id IS NULL;


-- Change the data types for clarity
ALTER TABLE emp_clean
ALTER COLUMN ename TYPE VARCHAR(100),
ALTER COLUMN mname TYPE VARCHAR(100);

-- sort by “JOB” in ascending order but make sure “President” is at the top of the list.
SELECT * 
INTO emp_clean_sorted
FROM emp_clean
ORDER BY 
 -- identifies "President" in job column and places that row first, then sorts the remaining in ascending order
	CASE
		WHEN job = 'President' then 0
		else 1
	end,
	job ASC;


-- 2. Let’s assume that the CSV file we started with is a live source where our “EMP” table data comes from, you successfully created a new table from that source but there’s one problem, the table isn’t automatically updated, which means we won’t always have the latest employee data. Not to worry I have a solution for you. (Est. Time 40 Min )
--  Your task is to create a stored procedure that we can use to create a nightly job to automate the process of loading new data into our “EMP” table.
--  To avoid duplicating the existing data you’ll need to insert data into our target table (new table you just created) from the results of the source table.
--  In other words, synchronize the two tables (Source and Target Tables ) by inserting, updating, or deleting rows in one table based on differences found in the other table.

-- Create procedure with input parameter for exported source table and to-be-updated target_table
CREATE PROCEDURE update_target_emp(source_table, target_table)
	AS
		BEGIN
			-- create chat_id table
			SELECT empno, login_id as chat_id
			INTO chat_id_tbl
			FROM source_table
			WHERE login_id LIKE '005%';
			
			-- create phone_id table
			SELECT empno, login_id as phone_id
			INTO phone_id_tbl
			FROM source_table
			WHERE LENGTH(login_id) = 4;
			
			-- Create table with correctly formatted employee names
			SELECT DISTINCT (empno),
				SPLIT_PART(ename,', ',2)|| ' ' || SPLIT_PART(ename,', ',1) AS ename 
			INTO ename_split
			FROM source_table
			WHERE ename IS NOT NULL;
			
			-- Manager name table alteration from "LastName, FirstName" to "FirstName LastName"
			SELECT DISTINCT (mgr),
				SPLIT_PART(mname,', ',2)|| ' ' || SPLIT_PART(mname,', ',1) AS mname 
			INTO mname_split
			FROM source_table
			WHERE mname IS NOT NULL;

			-- Date table for hire date formatting and tenure calculation
			SELECT DISTINCT (empno),
				AGE('2021-05-03', hiredate) as etenure,
				DATE_PART('day', hiredate) || '-' || date_part('month', hiredate) || '-' || date_part('year', hiredate) as hiredate
			INTO emp_tenure
			FROM source_table;
			
			-- Create new table for updated and cleaned data to be added
			SELECT DISTINCT (e.empno),
				es.ename,
				e.job,
				e.mgr,
				ms.mname,
				et.hiredate,
				et.etenure,
				e.sal,
				e.commission,
				e.team_name,
				cht.chat_id,
				phn.phone_id

			INTO emp_clean
			FROM emp as e
			-- join chat_id_tbl to add chat_id column
			LEFT JOIN chat_id_tbl as cht
			ON e.empno = cht.empno
			-- join phone_id_tbl to add phone_id column
			LEFT JOIN phone_id_tbl as phn
			ON e.empno = phn.empno
			-- join ename_split to add fixed ename column
			LEFT JOIN ename_split as es
			ON e.empno = es.empno
			-- join mname_split to add fixed mname column
			LEFT JOIN mname_split as ms
			ON e.mgr = ms.mgr
			-- join emp_tenure
			LEFT JOIN emp_tenure as et
			ON e.empno = et.empno;
			
			-- Delete temporary tables
			DROP TABLE chat_id_tbl;
			DROP TABLE phone_id_tbl;
			DROP TABLE ename_split;
			DROP TABLE mname_split;
			DROP TABLE emp_tenure;
			
			-- Fill in null values before syncing cleaned source_table with target_table
			-- Populate null values with appropriate filler.
			-- Numerical values are chaned from "null" to "0"
			UPDATE emp_clean
			SET mgr = 0
			WHERE
			mgr IS NULL;

			UPDATE emp_clean
			SET commission = 0
			WHERE
			commission IS NULL;

			-- string values are changed from "null" to "none."
			UPDATE emp_clean
			SET mname = 'none'
			WHERE
			mname IS NULL;

			UPDATE emp_clean
			SET chat_id = 'none'
			WHERE
			chat_id IS NULL;

			-- Change the data types for clarity
			ALTER TABLE emp_clean
			ALTER COLUMN ename TYPE VARCHAR(100),
			ALTER COLUMN mname TYPE VARCHAR(100);

			-- Update target_table with cleaned source table data (emp_clean)
			MERGE target_table AS tar
				USING emp_clean AS src
				ON src.empno = tar.empno
				-- Identify rows to be updated when "empno" already exists in target database and update if there are any changes
				WHEN MATCHED
					THEN	UPDATE
						SET ename = src.ename,
							job = src.job,
							mgr = src.mgr,
							mname = src.mname,
							hiredate = src.hiredate,
							etenure = src.etenure,
							sal = src.sal,
							commission = src.commission,
							team_name = src.team_name,
							chat_id = src.chat_id,
							phone_id = src.phone_id
				-- Insert rows to be added that do not exist in target_table
				WHEN NOT MATCHED
					THEN	INSERT
						(empno, 
						 ename, 
						 job, 
						 mgr, 
						 mname, 
						 hiredate, 
						 etenure, 
						 sal, 
						 commission, 
						 team_name, 
						 chat_id, 
						 phone_id)
						 VALUES
						 (src.empno, 
						 src.ename, 
						 src.job, 
						 src.mgr, 
						 src.mname, 
						 src.hiredate, 
						 src.etenure, 
						 src.sal, 
						 src.commission, 
						 src.team_name, 
						 src.chat_id, 
						 src.phone_id);
		 		-- Delete temporary table emp_clean
		 		DROP TABLE emp_clean;
		END



-- 3. We want to rank employee salary values from our "EMP” table and then pivot the result set into three columns. 
-- Your task is to show the top 5, the next 5, then all the rest. 
-- You'll do this by ranking the employees by Salary and then pivot the results into three columns. Please be as detailed as possible for your answer

-- There is no PIVOT function in PostgreSQL 11 and CROSSTAB function is not installed by default, therefore I created a new table to hold salary values to workaround the lack of functionality in my current platform.
-- Creates first "top_5" table by selecting the first 5 results from the SELECT query using row index
SELECT ROW_NUMBER() OVER (ORDER BY sal) + 0 AS row_num,
	ename || ' (' || sal || ')' AS top_5
INTO top_5
FROM emp_clean_sorted
ORDER BY sal DESC 
	OFFSET 0 ROWS 
	FETCH NEXT 5 ROWS ONLY;

-- Creates the second "next_5" table by selecting the next 5 results using the OFFSET/FETCH parameters using row index plus the offset to align with top_5 table
SELECT ROW_NUMBER() OVER (ORDER BY sal) + 5 AS row_num,
	ename || ' (' || sal || ')' AS next_5
INTO next_5
FROM emp_clean_sorted
ORDER BY sal DESC 
	OFFSET 5 ROWS 
	FETCH NEXT 5 ROWS ONLY;

-- Creates the second "rest" table by selecting the rest of the results using the OFFSET/FETCH parameters using row index plus the offset to align with top_5 table
SELECT ROW_NUMBER() OVER (ORDER BY sal) + 10 AS row_num,
	ename || ' (' || sal || ')' AS rest
INTO rest
FROM emp_clean_sorted
ORDER BY sal DESC 
	OFFSET 10 ROWS 
	;

-- Uses JOIN to concatenate the top_5, next_5, and rest tables to mimic the pivot table shown as PIVOT is not available as a default function in PgAdmin 4 - Postgresql 11.
SELECT t5.top_5,
	n5.next_5,
	r.rest
INTO top_salaries
FROM top_5 AS t5
LEFT JOIN next_5 AS n5
ON t5.row_num = n5.row_num
LEFT JOIN rest AS r
ON t5.row_num = r.row_num
ORDER BY t5.row_num DESC;



-- 4. Using a self-join write a query that counts how many employees report to each manager.
SELECT m.mname, COUNT(e.empno) as emp_Count
FROM emp_clean_sorted AS m, emp_clean_sorted AS e
WHERE m.mgr = e.empno
GROUP BY m.mname
ORDER BY emp_count DESC;

-- Notes: 
-- I would change the "mgr" column to be a VARCHAR type as there should not be any numeric operations performed on that number.
-- The hiredate format change would be set to the default server settings for displaying dates. Since the requested format did not match PostgreSQL 11's default format, it has been left as a string of text. The DATE_PART extraction function does not generate a 2 digit format so it would have to be hard coded in the output string, but since this would most likely be left as a datetime data type in a database changing the default format settings would be a better approach than code manipulation.


-- Typos in instructions
-- Header: misspells "Challenge" in SQL CODE Challenge
-- Redundant "this" in the 1st bullet point in the intructions list in "Let's clean up..."
-- Table used as example in the "Top 5, Next 5, and rest" contains six entries in each column not 5 entries.

