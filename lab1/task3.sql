-- TASK 3
CREATE OR REPLACE FUNCTION CountVal
RETURN  VARCHAR2 IS 
	odd_val NUMBER := 0;
	even_val NUMBER := 0;
BEGIN 
	BEGIN
		SELECT COUNT(val) INTO odd_val
		FROM MyTable
		WHERE MOD(val, 2) = 1;
	
		SELECT COUNT(val) INTO even_val
		FROM MyTable
		WHERE MOD(val, 2) = 0;
	
		EXCEPTION
			WHEN OTHERS THEN
				RETURN 'Error.';
	END;

	IF even_val > odd_val THEN
		RETURN 'TRUE';
	ELSIF even_val < odd_val THEN
		RETURN 'FALSE';
	ELSE
		RETURN 'EQUAL';
	END IF;
END;

DECLARE
	ans VARCHAR2(10);
BEGIN
	ans := CountVal;
	DBMS_OUTPUT.PUT_LINE('Result: ' || ans);
END;
