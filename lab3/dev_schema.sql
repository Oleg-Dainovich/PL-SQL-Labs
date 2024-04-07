-- TABLES --

CREATE TABLE dev.dev_users (
    id NUMBER PRIMARY KEY,
    username VARCHAR2(50),
    email VARCHAR2(100)
);

CREATE TABLE dev.dev_orders (
    id NUMBER PRIMARY KEY,
    user_id NUMBER,
    amount NUMBER,
    status VARCHAR2(20),
    FOREIGN KEY (user_id) REFERENCES dev_users(id)
);

CREATE TABLE dev.dev_products (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    price NUMBER
);

CREATE TABLE dev.common_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    description VARCHAR2(255)
);

CREATE TABLE dev.diff_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    status VARCHAR2(20)  
);

CREATE TABLE dev.t_one (
	id NUMBER PRIMARY KEY,
	val NUMBER
);

CREATE TABLE dev.t_two (
	id NUMBER PRIMARY KEY,
	val NUMBER
);

CREATE TABLE dev.t_three (
	id NUMBER PRIMARY KEY,
	val NUMBER
);

ALTER TABLE dev.t_one ADD CONSTRAINT fk_constraint_key FOREIGN KEY (val) REFERENCES dev.t_three (id);
ALTER TABLE dev.t_three ADD CONSTRAINT fk_constraint_key_two FOREIGN KEY (val) REFERENCES dev.t_two (id);

DROP TABLE dev.t_one;
DROP TABLE dev.t_three;
DROP TABLE dev.t_two;

-- LOOPS -- 

CREATE TABLE loop_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    parent_group_id NUMBER REFERENCES loop_table(id)
);
DROP TABLE loop_table;

-- PROCEDURES --

CREATE OR REPLACE PROCEDURE create_table_dev AS
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE dev_table (id NUMBER, name VARCHAR2(100))';
END;

CREATE OR REPLACE PROCEDURE create_proc_dev AS
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PROCEDURE dev_proc AS BEGIN NULL; END;';
END;

CREATE OR REPLACE PROCEDURE create_index_dev AS
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX dev_index ON dev_table(id)';
END;

CREATE OR REPLACE PROCEDURE common_proc AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('This is a common procedure.');
END;

CREATE OR REPLACE PROCEDURE diff_proc(arg1 VARCHAR2) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Procedure diff_proc from DEV is called with argument: ' || arg1);
END;

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION dev_function_1 RETURN VARCHAR2 AS
BEGIN
    RETURN 'This is dev function 1.';
END;

CREATE OR REPLACE FUNCTION dev_function_2 RETURN VARCHAR2 AS
BEGIN
    RETURN 'This is dev function 2.';
END;

CREATE OR REPLACE FUNCTION common_func RETURN VARCHAR2 AS
BEGIN
    RETURN 'This is a common function.';
END;

CREATE OR REPLACE FUNCTION diff_func(arg1 VARCHAR2) RETURN VARCHAR2 AS
BEGIN
    RETURN 'This is DEV diff function with argument: ' || arg1;
END;


-- INDEXES --

CREATE INDEX idx_dev_products ON dev.dev_products(name);

CREATE INDEX idx_dev_common_table ON dev.common_table(name);


CREATE OR REPLACE PROCEDURE ya_sdal_proc AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('baaldeeezh');
END;


