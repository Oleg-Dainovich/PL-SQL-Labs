-- TASK 4
CREATE OR REPLACE FUNCTION GenerateCommand(str_id IN VARCHAR2, num_val IN NUMBER)
RETURN VARCHAR2 IS 
	num_id NUMBER;
	res_command VARCHAR2(1000);
BEGIN
	BEGIN
		num_id := TO_NUMBER(str_id);
		EXCEPTION
			WHEN OTHERS THEN
				RETURN 'Error. Invalid input.';
	END;
	
	res_command := 'INSERT INTO MyTable (id, val) VALUES (' || num_id || ', ' || num_val || ')';
	RETURN res_command;
END;

DECLARE
	input_id VARCHAR2(1000);
	ans VARCHAR2(1000);
BEGIN
	input_id := '12';
	ans := GenerateCommand(input_id, 0);
	DBMS_OUTPUT.PUT_LINE('Result: ' || ans);
END;
