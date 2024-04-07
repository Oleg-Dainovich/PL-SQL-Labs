-- create schemas 
CREATE USER dev IDENTIFIED BY dev_schema;
CREATE USER prod IDENTIFIED BY prod_schema;

GRANT ALL PRIVILEGES TO system;
GRANT ALL PRIVILEGES TO hr;
GRANT ALL PRIVILEGES TO dev;
GRANT ALL PRIVILEGES TO prod;

-- 
DROP TABLE diff_tables;
DROP TABLE out_tables;

TRUNCATE TABLE DIFF_TABLES ;
TRUNCATE TABLE OUT_TABLES ;

-- store 'list' of tables with differences in schemas
CREATE TABLE diff_tables (
    name VARCHAR2(100) NOT NULL,
    description VARCHAR2(100)
);

-- store 'list' of tables without differences
CREATE TABLE out_tables (
    name VARCHAR2(100) NOT NULL,
    description VARCHAR2(100)
);

CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
)
IS 
    tables_count NUMBER;
    columns_count NUMBER;
   
    our_table_count NUMBER;
    other_table_count NUMBER;

    ref_table VARCHAR2(100);
    ref_constraint VARCHAR2(100);
    ref_tables_count NUMBER;

    is_ref BOOLEAN := TRUE;

    obj_count NUMBER;
    f1_arg_count NUMBER;
    f2_arg_count NUMBER;
    arg_count NUMBER;
   
    f1_arg_list VARCHAR2(4000);
    f2_arg_list VARCHAR2(4000);

    is_exists BOOLEAN;
BEGIN
    dbms_output.put_line('_______________ Tables Info _______________');
    dbms_output.put_line(' ');
    -- get number of tables in Dev-schema
    SELECT COUNT(*) INTO tables_count FROM ALL_TABLES WHERE OWNER = dev_schema_name;

    -- if there are no tables in Dev-schema -> STOP
    IF tables_count = 0 THEN
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain tables.');
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain tables.');
    ELSE
         -- get list of tables in dev-schema
        FOR tab IN (SELECT * FROM all_tables WHERE owner=dev_schema_name)
        LOOP
            -- get number of tables with same name in Prod-schema
            SELECT COUNT(*) INTO tables_count FROM all_tables WHERE owner=prod_schema_name AND table_name=tab.table_name;
        
            -- table exists in prod-schema?
            IF tables_count = 1 THEN
            	SELECT COUNT(*) INTO other_table_count FROM all_tab_columns WHERE table_name=tab.table_name AND owner=prod_schema_name;
            	SELECT COUNT(*) INTO our_table_count FROM all_tab_columns WHERE table_name=tab.table_name AND owner=dev_schema_name;	
            	IF other_table_count <> our_table_count THEN
            		INSERT INTO diff_tables VALUES(tab.table_name, 'structure');
            	ELSE
	                FOR col IN (SELECT * FROM all_tab_columns WHERE table_name=tab.table_name AND owner=dev_schema_name)
	                LOOP
	                    SELECT COUNT(*) INTO columns_count FROM all_tab_columns WHERE owner=prod_schema_name AND
	                                                                                  column_name=col.column_name AND
	                                                                                  data_type=col.data_type AND
	                                                                                  data_length=col.data_length AND
	                                                                                  nullable=col.nullable;
	                    IF columns_count = 0 THEN
	                    -- -> tables structure is different
	                        INSERT INTO diff_tables VALUES(tab.table_name, 'structure');
	                    END IF;
	                    EXIT WHEN columns_count=0;
	                END LOOP;
	            END IF;
            ELSE
                INSERT INTO diff_tables VALUES (tab.table_name, 'not exists');
            END IF;
        END LOOP;

        -- check fk & cycle 
        SELECT COUNT(*) INTO tables_count FROM diff_tables;

        WHILE tables_count != 0
        LOOP
            FOR tab IN (SELECT * FROM diff_tables) LOOP
                FOR fk IN (SELECT * FROM all_constraints WHERE owner=dev_schema_name AND 
                                            table_name=tab.name AND constraint_type='R')
                LOOP
                    check_cycle(fk.r_constraint_name, dev_schema_name, fk.table_name);

                    SELECT table_name INTO ref_table FROM all_constraints 
                        WHERE constraint_name=fk.r_constraint_name;

                    SELECT COUNT(*) INTO ref_tables_count FROM out_tables WHERE name=ref_table;

                    IF ref_tables_count = 0 THEN
                        is_ref := FALSE;
                    END IF;
                END LOOP;

                IF is_ref THEN
                    DELETE FROM diff_tables WHERE name=tab.name;
                    INSERT INTO out_tables VALUES(tab.name, tab.description);
                END IF;

                is_ref := TRUE;

            END LOOP;

            SELECT COUNT(*) INTO tables_count FROM diff_tables;

        END LOOP;

        SELECT COUNT(*) INTO tables_count FROM out_tables;

        IF tables_count = 0 THEN
            dbms_output.put_line('There are no differences!');
        ELSE
            FOR tab IN (SELECT * FROM out_tables) LOOP
                dbms_output.put_line(tab.name || ' - ' || tab.description);
            END LOOP;
        END IF;
    END IF;

    -- task 2
    dbms_output.put_line(' ');
    dbms_output.put_line('_____________ Procedures Info _____________');
    dbms_output.put_line(' ');
   
    -- get number of procedures in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=dev_schema_name AND object_type='PROCEDURE';
    
    -- if there are no procedures in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain procedures.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain procedures.');
    ELSE
        FOR proc IN (SELECT * FROM all_objects WHERE owner=dev_schema_name AND object_type='PROCEDURE')
        LOOP
            SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=prod_schema_name AND 
                                object_type='PROCEDURE' AND object_name=proc.object_name;

            IF obj_count = 0 THEN
                dbms_output.put_line(proc.object_name || ' not exists in Prod-schema');
            ELSE
                SELECT COUNT(*) INTO f1_arg_count FROM all_arguments WHERE owner=dev_schema_name AND object_name=proc.object_name;
                SELECT COUNT(*) INTO f2_arg_count FROM all_arguments WHERE owner=prod_schema_name AND object_name=proc.object_name;

                IF f1_arg_count != f2_arg_count THEN
                    dbms_output.put_line(proc.object_name || ' has different arguments');
                ELSE
                    FOR arg IN (SELECT * FROM all_arguments WHERE owner=dev_schema_name AND object_name=proc.object_name)
                    LOOP
                        SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=prod_schema_name AND 
                                                object_name=proc.object_name AND data_type=arg.data_type;

                        IF arg_count = 0 THEN
                            dbms_output.put_line(proc.object_name || ' has different arguments data types');
                        ELSE
                        	FOR arg IN (SELECT * FROM all_arguments WHERE owner=prod_schema_name AND object_name=proc.object_name)
		                    LOOP
		                        SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=dev_schema_name AND 
		                                                object_name=proc.object_name AND data_type=arg.data_type;
		
		                        IF arg_count = 0 THEN
		                            dbms_output.put_line(proc.object_name || ' has different arguments data types');
		                        END IF;
		                    END LOOP;
                       END IF;
                    END LOOP;
                   
                    IF arg_count != 0 THEN
                    	FOR arg IN (SELECT * FROM all_arguments WHERE owner=prod_schema_name AND object_name=proc.object_name)
	                    LOOP
	                        SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=dev_schema_name AND 
	                                                object_name=proc.object_name AND data_type=arg.data_type;
	
	                        IF arg_count = 0 THEN
	                            dbms_output.put_line(proc.object_name || ' has different arguments data types');
	                        END IF;
	                    END LOOP;
                   	END IF;
                   
                END IF;
            END IF;
        END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line('_____________ Functions  Info _____________');
    dbms_output.put_line(' ');
    -- get number of functions in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=dev_schema_name AND object_type='FUNCTION';
    
    -- if there are no functions in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain functions.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain functions.');
    ELSE
        -- Check functions in Dev-schema
		FOR func IN (SELECT * FROM all_objects WHERE owner=dev_schema_name AND object_type='FUNCTION')
		LOOP
		    -- Проверка существования функции в схеме Prod
		    SELECT COUNT(*) INTO obj_count FROM all_objects WHERE owner=prod_schema_name AND 
		                        object_type='FUNCTION' AND object_name=func.object_name;
		    IF obj_count = 0 THEN
		        dbms_output.put_line(func.object_name || ' does not exist in Prod-schema');
		    ELSE
		        -- Получение списка аргументов функции в схеме Dev
		        SELECT sum(COUNT(*)) INTO f1_arg_count 
		        FROM all_arguments WHERE owner=dev_schema_name AND object_name=func.object_name GROUP BY data_type;
		       
		        -- Получение списка аргументов функции в схеме Prod
		        SELECT SUM(COUNT(*)) INTO f2_arg_count 
		        FROM all_arguments WHERE owner=prod_schema_name AND object_name=func.object_name GROUP BY data_type;
		       
		        -- Если количество аргументов разное, выводим сообщение
		        IF f1_arg_count != f2_arg_count THEN
		            dbms_output.put_line(func.object_name || ' has different number of arguments');
		        ELSE
		        	FOR arg IN (SELECT * FROM all_arguments WHERE owner=dev_schema_name AND object_name=func.object_name)
                    LOOP
	                    SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=prod_schema_name AND 
                                                object_name=func.object_name AND data_type=arg.data_type;

                        IF arg_count = 0 THEN
                            dbms_output.put_line(func.object_name || ' has different arguments data types');
                       END IF;
                    END LOOP;
                   
                   	IF arg_count != 0 THEN
                   		FOR arg IN (SELECT * FROM all_arguments WHERE owner=prod_schema_name AND object_name=func.object_name)
	                    LOOP
		                    SELECT COUNT(*) INTO arg_count FROM all_arguments WHERE owner=dev_schema_name AND 
	                                                object_name=func.object_name AND data_type=arg.data_type;
	
	                        IF arg_count = 0 THEN
	                            dbms_output.put_line(func.object_name || ' has different arguments data types');
	                        END IF;
	                    END LOOP;
                   	END IF;
                                      
		        END IF;
		    END IF;
		END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line('______________ Indexes  Info _____________');
    dbms_output.put_line(' ');
    -- get number of indexes in Dev-schema
    SELECT COUNT(*) INTO obj_count FROM all_ind_columns WHERE index_owner=dev_schema_name; -- AND object_type='PACKAGE';
    
    -- if there are no packages in Dev-schema -> STOP
    IF obj_count = 0 THEN
        -- RAISE_APPLICATION_ERROR(-20002, 'Schema ' || dev_schema_name || ' does not contain procedures.');
        dbms_output.put_line('Schema ' || dev_schema_name || ' does not contain package indexes.');
    ELSE
        FOR dev_index IN (SELECT * FROM all_ind_columns WHERE index_owner=dev_schema_name)
        LOOP
            is_exists := FALSE;
            SELECT COUNT(*) INTO obj_count FROM all_ind_columns WHERE index_owner=prod_schema_name;

            IF obj_count = 0 THEN
                dbms_output.put_line('Index ' || dev_index.index_name || ' not exists in Prod-schema');
            ELSE
                FOR prod_index IN (SELECT * FROM all_ind_columns WHERE index_owner=prod_schema_name)
                LOOP
                    IF dev_index.index_name = prod_index.index_name THEN
                        IF dev_index.table_name = prod_index.table_name THEN
                            IF dev_index.column_name = prod_index.column_name THEN
                                is_exists := TRUE;
                            END IF;
                        END IF; 
                    END IF;
                END LOOP;

                IF is_exists = FALSE THEN
                    IF SUBSTR(dev_index.index_name, 1, 3) != 'BIN' AND
                        SUBSTR(dev_index.index_name, 1, 3) != 'SYS' THEN
                        dbms_output.put_line('Index ' || dev_index.index_name || ' not exists in Prod-schema');
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END IF;

    dbms_output.put_line(' ');
    dbms_output.put_line(' ');

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR | ' || SQLERRM);

END compare_schemas;




CREATE OR REPLACE PROCEDURE check_cycle (
    ref_constraint_name IN VARCHAR2,
    dev_schema_name IN VARCHAR2,
    start_table_name IN VARCHAR2,
    cur_table_name IN VARCHAR2 DEFAULT NULL
)
IS 
    ref_table_name VARCHAR2(100);
BEGIN
    IF cur_table_name IS NULL THEN
        SELECT table_name INTO ref_table_name FROM all_constraints 
            WHERE constraint_name=ref_constraint_name;
    ELSE
        SELECT table_name INTO ref_table_name FROM all_constraints 
            WHERE constraint_name=ref_constraint_name AND table_name!=cur_table_name;
    END IF;

    IF ref_table_name = start_table_name THEN
        RAISE_APPLICATION_ERROR(-20003, 'Loop detected in foreign keys for table ' || dev_schema_name ||
                '.' || start_table_name || '!');
    ELSE
        FOR fk IN (SELECT * FROM all_constraints WHERE owner=dev_schema_name AND table_name=ref_table_name AND constraint_type='R')
        LOOP
            check_cycle(fk.r_constraint_name, dev_schema_name, start_table_name, ref_table_name);
        END LOOP;
    END IF;
END check_cycle;

-- task 3
CREATE OR REPLACE PROCEDURE COMPARE_SCHEMAS_DDL(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
IS
    counter NUMBER;
    counter2 NUMBER;
    table_counter NUMBER;
    text VARCHAR2(100);
BEGIN
    -- dev tables to create or add columns in prod
    FOR res IN (
        SELECT DISTINCT table_name 
        FROM all_tab_columns 
        WHERE owner = dev_schema_name 
            AND table_name NOT LIKE 'SYS_%' 
            AND (table_name, column_name) NOT IN (
                SELECT table_name, column_name 
                FROM all_tab_columns 
                WHERE owner = prod_schema_name
            )
    )
    LOOP
        counter := 0;
        SELECT COUNT(*) INTO counter FROM all_tables WHERE owner = prod_schema_name AND table_name = res.table_name;
        IF counter > 0 THEN
            FOR res2 IN (
                SELECT DISTINCT column_name, data_type 
                FROM all_tab_columns 
                WHERE owner = dev_schema_name 
                    AND table_name = res.table_name  
                    AND (table_name, column_name) NOT IN (
                        SELECT table_name, column_name 
                        FROM all_tab_columns 
                        WHERE owner = prod_schema_name
                    )
            )
            LOOP
                DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || prod_schema_name || '.' || res.table_name || ' ADD ' || res2.column_name || ' ' || res2.data_type || '(20);');
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || prod_schema_name || '.' || res.table_name || ' AS (SELECT * FROM ' || dev_schema_name || '.' || res.table_name || ' WHERE 1=0);');
        END IF;
    END LOOP;

    -- prod tables to delete or drop columns
    FOR res IN (
        SELECT DISTINCT table_name 
        FROM all_tab_columns 
        WHERE owner = prod_schema_name  
            AND (table_name, column_name) NOT IN (
                SELECT table_name, column_name 
                FROM all_tab_columns 
                WHERE owner = dev_schema_name
            )
    )
    LOOP
        counter := 0;
        counter2 :=0;
        table_counter := 0;
        SELECT COUNT(column_name) INTO counter FROM all_tab_columns WHERE owner = prod_schema_name AND table_name = res.table_name;
        SELECT COUNT(column_name) INTO counter2 FROM all_tab_columns WHERE owner = dev_schema_name AND table_name = res.table_name;
        SELECT COUNT(*) INTO table_counter FROM all_tables WHERE owner = dev_schema_name AND table_name = res.table_name;
        IF table_counter != 0 AND counter != counter2 THEN
            FOR res2 IN (
                SELECT column_name 
                FROM all_tab_columns 
                WHERE owner = prod_schema_name 
                    AND table_name = res.table_name 
                    AND column_name NOT IN (
                        SELECT column_name 
                        FROM all_tab_columns 
                        WHERE owner = dev_schema_name 
                            AND table_name = res.table_name
                    )
            )
            LOOP
                DBMS_OUTPUT.PUT_LINE('ALTER TABLE '|| prod_schema_name || '.' || res.table_name || ' DROP COLUMN ' || res2.column_name || ';');
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('DROP TABLE ' || prod_schema_name || '.' || res.table_name || ' CASCADE CONSTRAINTS;');
        END IF;
    END LOOP;
    
    -- dev procedure to create in prod
    FOR res IN (
        SELECT DISTINCT object_name 
        FROM all_objects 
        WHERE object_type = 'PROCEDURE' 
            AND owner = dev_schema_name  
            AND object_name NOT IN (
                SELECT object_name 
                FROM all_objects 
                WHERE owner = prod_schema_name 
                    AND object_type = 'PROCEDURE'
            )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (
            SELECT text 
            FROM all_source 
            WHERE type = 'PROCEDURE' 
                AND name = res.object_name 
                AND owner = dev_schema_name
            ORDER BY line
        )
        LOOP
	        DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
        END LOOP;
    END LOOP;   

    -- prod procedures to delete
    FOR res IN (
        SELECT DISTINCT object_name 
        FROM all_objects 
        WHERE object_type = 'PROCEDURE' 
            AND owner = prod_schema_name 
            AND object_name NOT IN (
                SELECT object_name 
                FROM all_objects 
                WHERE owner = dev_schema_name 
                    AND object_type = 'PROCEDURE'
            )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP PROCEDURE ' || prod_schema_name || '.' || res.object_name || ';');
    END LOOP;   

    -- dev functions to create in prod
    FOR res IN (
        SELECT DISTINCT object_name 
        FROM all_objects 
        WHERE object_type = 'FUNCTION' 
            AND owner = dev_schema_name  
            AND object_name NOT IN (
                SELECT object_name 
                FROM all_objects 
                WHERE owner = prod_schema_name 
                    AND object_type = 'FUNCTION'
            )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (
            SELECT text 
            FROM all_source 
            WHERE type = 'FUNCTION' 
                AND name = res.object_name 
                AND owner = dev_schema_name
            ORDER BY line
        )
        LOOP
            DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
        END LOOP;
    END LOOP; 

    -- prod functions to delete
    FOR res IN (
        SELECT DISTINCT object_name 
        FROM all_objects 
        WHERE object_type = 'FUNCTION' 
            AND owner = prod_schema_name 
            AND object_name NOT IN (
                SELECT object_name 
                FROM all_objects 
                WHERE owner = dev_schema_name 
                    AND object_type = 'FUNCTION'
            )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP FUNCTION ' || prod_schema_name || '.' || res.object_name || ';');
    END LOOP;  
    
	-- Проверка процедур с одинаковыми именами, но разными аргументами
	FOR res IN (
	    SELECT DISTINCT object_name
	    FROM all_objects
	    WHERE object_type = 'PROCEDURE'
	        AND owner = dev_schema_name
	        AND object_name IN (
	            SELECT object_name
	            FROM all_objects
	            WHERE owner = prod_schema_name
	                AND object_type = 'PROCEDURE'
	        )
	)
	LOOP
	    FOR dev_arg IN (
	        SELECT argument_name, data_type
	        FROM all_arguments
	        WHERE object_name = res.object_name
	            AND owner = dev_schema_name
	        ORDER BY position
	    )
	    LOOP
	        FOR prod_arg IN (
	            SELECT argument_name, data_type
	            FROM all_arguments
	            WHERE object_name = res.object_name
	                AND owner = prod_schema_name
	            ORDER BY position
	        )
	        LOOP
	            IF dev_arg.argument_name = prod_arg.argument_name AND dev_arg.data_type != prod_arg.data_type THEN
			        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
			        FOR res2 IN (
			            SELECT text 
			            FROM all_source 
			            WHERE type = 'PROCEDURE' 
			                AND name = res.object_name 
			                AND owner = dev_schema_name
			            ORDER BY line
			        )
			        LOOP
				        DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
			        END LOOP;
	            END IF;
	        END LOOP;
	    END LOOP;
	END LOOP;
	
	-- Проверка функций с одинаковыми именами, но разными аргументами
	FOR res IN (
	    SELECT DISTINCT object_name
	    FROM all_objects
	    WHERE object_type = 'FUNCTION'
	        AND owner = dev_schema_name
	        AND object_name IN (
	            SELECT object_name
	            FROM all_objects
	            WHERE owner = prod_schema_name
	                AND object_type = 'FUNCTION'
	        )
	)
	LOOP
	    FOR dev_arg IN (
	        SELECT argument_name, data_type
	        FROM all_arguments
	        WHERE object_name = res.object_name
	            AND owner = dev_schema_name
	        ORDER BY position
	    )
	    LOOP
	        FOR prod_arg IN (
	            SELECT argument_name, data_type
	            FROM all_arguments
	            WHERE object_name = res.object_name
	                AND owner = prod_schema_name
	            ORDER BY position
	        )
	        LOOP
	            IF dev_arg.argument_name = prod_arg.argument_name AND dev_arg.data_type != prod_arg.data_type THEN
			        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
			        FOR res2 IN (
			            SELECT text 
			            FROM all_source 
			            WHERE type = 'FUNCTION' 
			                AND name = res.object_name 
			                AND owner = dev_schema_name
			            ORDER BY line
			        )
			        LOOP
			            DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
			        END LOOP;
	            END IF;
	        END LOOP;
	    END LOOP;
	END LOOP;

    -- delete indexes from prod
    FOR res IN (
        SELECT index_name 
        FROM all_indexes 
        WHERE table_owner = prod_schema_name 
            AND index_name NOT LIKE 'SYS_%' 
            AND index_name NOT LIKE '%_PK' 
            AND index_name NOT IN (
                SELECT index_name 
                FROM all_indexes 
                WHERE table_owner = dev_schema_name 
                    AND index_name NOT LIKE '%_PK'
            )
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP INDEX ' || res.index_name || ';');
    END LOOP;
   
    -- dev indexes to create in prod
    FOR res IN (
        SELECT index_name, index_type, table_name 
        FROM all_indexes 
        WHERE table_owner = dev_schema_name 
            AND index_name NOT LIKE 'SYS_%' 
            AND index_name NOT LIKE '%_PK' 
            AND index_name NOT IN (
                SELECT index_name 
                FROM all_indexes 
                WHERE table_owner = prod_schema_name 
                    AND index_name NOT LIKE '%_PK'
            )
    )
    LOOP
        SELECT column_name INTO text 
        FROM ALL_IND_COLUMNS 
        WHERE index_name = res.index_name 
            AND table_owner = dev_schema_name;

        DBMS_OUTPUT.PUT_LINE('CREATE ' || res.index_type || ' INDEX ' || res.index_name || ' ON ' || prod_schema_name || '.' || res.table_name || '(' || text || ');');
    END LOOP;
   
   	EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR | ' || SQLERRM);
END;



CALL COMPARE_SCHEMAS('DEV', 'PROD');
TRUNCATE TABLE DIFF_TABLES;
TRUNCATE TABLE OUT_TABLES; 

CALL COMPARE_SCHEMAS_DDL('DEV','PROD');
