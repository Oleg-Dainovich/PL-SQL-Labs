-- TASK 5
CREATE OR REPLACE PROCEDURE proc_restore_info (timestamp_val TIMESTAMP DEFAULT NULL, 
												time_offset_val INTERVAL DAY TO SECOND DEFAULT NULL)
IS
	time_val TIMESTAMP;
BEGIN
	IF timestamp_val IS NULL AND time_offset_val IS NULL THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Error. You need to enter timestamp or time offset.');
	END IF;

	IF timestamp_val IS NOT NULL THEN
		time_val := timestamp_val;
	ELSIF time_offset_val IS NOT NULL THEN 
		time_val := SYSTIMESTAMP - time_offset_val;
	END IF;

	FOR record_val IN (
		SELECT * FROM STUDENTS_LOG
		WHERE LOG_DATE >= time_val
		ORDER BY LOG_DATE DESC
	)
	LOOP
		IF record_val.OPERATION = 'INSERT' THEN
			DELETE FROM STUDENTS WHERE ID = record_val.NEW_STUDENT_ID;
		ELSIF record_val.OPERATION = 'DELETE' THEN
			INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
			VALUES (record_val.OLD_STUDENT_ID, record_val.OLD_NAME, record_val.OLD_GROUP_ID);
		ELSIF record_val.OPERATION = 'UPDATE' THEN
			UPDATE STUDENTS SET NAME = record_val.OLD_NAME, GROUP_ID = record_val.OLD_GROUP_ID
			WHERE ID = record_val.OLD_STUDENT_ID;
		END IF;
	END LOOP;
END;

BEGIN
	proc_restore_info(NULL, INTERVAL '2' DAY);
END;
