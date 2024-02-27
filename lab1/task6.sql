-- TASK 6
CREATE OR REPLACE FUNCTION CountCash(salary IN VARCHAR2, bonus IN VARCHAR2) 
RETURN NUMBER IS 
	num_salary NUMBER;
	num_bonus NUMBER;
	percent_bonus NUMBER;
	total_income NUMBER;
BEGIN
	BEGIN
		num_salary := TO_NUMBER(salary);
		EXCEPTION
			WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE('Error. Invalid data.');
				RAISE_APPLICATION_ERROR(-20001, 'Error. Invalid data.');
	END;
	BEGIN
		num_bonus := TO_NUMBER(bonus);
		EXCEPTION
			WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE('Error. Invalid data.');
				RAISE_APPLICATION_ERROR(-20001, 'Error. Invalid data.');
	END;

	IF  num_salary <= 0 THEN
		DBMS_OUTPUT.PUT_LINE('Error. Salary must be positive.');
		RAISE_APPLICATION_ERROR(-20001, 'Error. Salary must be positive.');
	ELSIF num_bonus <= 0 THEN
		DBMS_OUTPUT.PUT_LINE('Error. Bonus must be positive.');
		RAISE_APPLICATION_ERROR(-20001, 'Error. Bonus must be positive.');
	END IF;

	percent_bonus := num_bonus / 100.0;
	total_income := (1 + percent_bonus) * 12 * num_salary;
	RETURN total_income;
END;

DECLARE
	ans NUMBER;
BEGIN 
	ans := CountCash('322', '32');
	DBMS_OUTPUT.PUT_LINE('Result: ' || ans);
END;
