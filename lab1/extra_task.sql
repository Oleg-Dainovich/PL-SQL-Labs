-- EXTRA TASK
CREATE OR REPLACE FUNCTION ErrOrInsert(num_id IN NUMBER, num_val IN NUMBER)
RETURN VARCHAR2 IS 
	is_exist NUMBER := 0;
	str_command VARCHAR2(1000);
BEGIN
	BEGIN
		SELECT COUNT(*) INTO is_exist
		FROM MyTable
		WHERE id = num_id AND val = num_val;
	END;
	IF is_exist > 0 THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Error. Data already exists.');
	END IF;
	str_command := 'INSERT INTO MyTable(id, val) VALUES (' || num_id || ', ' || num_val || ')';
	RETURN str_command;
END;

BEGIN
	DBMS_OUTPUT.PUT_LINE('Result: ' || ErrOrInsert(1324, 6455));
END;
