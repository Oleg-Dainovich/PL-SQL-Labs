-- TASK 5
CREATE OR REPLACE PROCEDURE InsertOperation(num_id IN NUMBER, num_val IN NUMBER)
IS 
BEGIN 
	INSERT INTO MyTable (id, val) VALUES (num_id, num_val);
	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Insert completed.');
	EXCEPTION 
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Error. Insert denied.' || SQLERRM);
			ROLLBACK;
END;

BEGIN 
	InsertOperation(0, 0);
END;

CREATE OR REPLACE PROCEDURE UpdateOperation(num_id IN NUMBER, num_val IN NUMBER)
IS 
BEGIN 
	UPDATE MyTable SET val = num_val WHERE id = num_id;
	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Update completed.');
	EXCEPTION 
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Error. Update denied.' || SQLERRM);
			ROLLBACK;
END;

BEGIN 
	UpdateOperation(0, 1);
END;

CREATE OR REPLACE PROCEDURE DeleteOperation(num_id IN NUMBER)
IS 
BEGIN 
	DELETE FROM MyTable WHERE id = num_id;
	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Delete completed.');
	EXCEPTION 
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Error. Delete denied.' || SQLERRM);
			ROLLBACK;
END;

BEGIN 
	DeleteOperation(0);
END;
