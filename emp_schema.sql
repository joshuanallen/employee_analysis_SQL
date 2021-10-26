-- Drop table if exists
DROP TABLE emp;


-- Create table to hold employee database
CREATE TABLE emp (
	empno NUMERIC(10,0) NOT NULL,
	ename VARCHAR(100) NOT NULL,
	login_id VARCHAR(100),
	job VARCHAR(100) NOT NULL,
	mgr NUMERIC(10,0),
	mname VARCHAR(100),
	hiredate DATE NOT NULL,
	--hiredate TIMESTAMP NOT NULL,
	sal NUMERIC(10,0) NOT NULL,
	commission NUMERIC(10,0),
	team_name VARCHAR(100) NOT NULL
);