-- TASK 3

CREATE OR REPLACE TRIGGER trg_cascade_delete
BEFORE DELETE ON GROUPS
FOR EACH ROW 
BEGIN
	DELETE
	FROM STUDENTS
	WHERE GROUP_ID = :OLD.ID;
END;

--DELETE FROM GROUPS WHERE ID = 0
--SELECT * FROM GROUPS 
--SELECT * FROM STUDENTS 
