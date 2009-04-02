/**
* (c) 2008 Technology Lab,
* Stored Procedure Generator 0.2
*
* Features:
*	will generate stored procedure wrappers around a given <schema>.<table> pair to perform: inserts, retrieves, updates opertions.
*
* License
* This is utility is designed for PostgreSQL 7x and later and comes with absolutely NO WARRANTY or Implied warranty.
* licensed under GPL V3.0 License (http://www.gnu.org/licenses/gpl.html)
* Change; share at will and give proper credit to contributors
*
* How to install this utility:
*	1. Create a schema called utils (if it doesn't already exist)
*	2. Run this file from either a command line (pgsql) or a GUI client
*
* How to run the utility:
*	For a given <schema>.<table> you should run in SQL editor (command line or GUI):
*	SELECT utils.generateStoredProcedures(<schema>,<table>) ; and the utility will create the appropriate functions in the <schema> you specified.
*
* Things to know:
*	1. Tables accessed with double quotes on their names are not yet supported
*
* TODO:
*	1. Provide Security to avoid SQL injection for varchar|Text|char(x) fields using regex
*	2. Refine getters i.e getter by unique; foreign keys (not just primary keys)
*	3. Provide support for delete operations
*
* Contributors:
*	Steve L. Nyemba, nyemba@gmail.com
*	Gregg Boyle, greggboyle@gmail.com
*/

CREATE OR REPLACE FUNCTION utils.getFieldNames(p_schemaName varchar, p_tableName varchar) returns REFCURSOR AS $$
DECLARE
	oFieldNames REFCURSOR;
BEGIN
	OPEN oFieldNames FOR
	SELECT column_name,data_type
	FROM 
		information_schema.columns
	WHERE
		table_schema=p_schemaName and table_name = p_tableName
		;
    
	return oFieldNames ;
END;
$$ LANGUAGE PLPGSQL ;

CREATE OR REPLACE FUNCTION utils.generateUpdateStoredProcedure(p_schemaName VARCHAR, p_tableName VARCHAR) RETURNS VOID AS $$
DECLARE
	oRecord		RECORD;
	oTableDef	REFCURSOR;

	oFunctionBody 	    VARCHAR;
	oSQLCommand	        VARCHAR;
	oFilter		        VARCHAR;
	oParameterList	    VARCHAR;
	oFieldNameList	    VARCHAR;
	oPrimaryKeyName     VARCHAR;
	
BEGIN
    oPrimaryKeyName := utils.getPrimaryKeyName(p_schemaName,p_tableName) ;
	-- Creating an update stored procedure for a given <p_schemaName>.<p_tableName>
	oFunctionBody 	:= 'CREATE OR REPLACE FUNCTION ' ||p_schemaName||'.upd_'||p_tableName ||'(' ;
	oSQLCommand 	:= 'UPDATE '||p_schemaName ||'.'||p_tableName || ' SET ';
	OPEN oTableDef FOR SELECT  utils.getFieldNames(p_schemaName,p_tableName);
	FETCH oTableDef INTO oTableDef;
    
	oParameterList 	:= '';
	oFieldNameList	:= '';

	LOOP
	    FETCH oTableDef INTO oRecord ;
		-- Function body at this point should include Parameter list
		IF FOUND THEN
			/**
			* If we have a record Then we assign parameter list and continue building the SQL Command
			*
		 	* Inspecting if we must insert commas. The principal is as follows :
		 	*  If the parameter list is not empty i.e != '' then we have at least one element that is inserted and because the status is set to FOUND then it means the previous elements have to be appended with comma before adding the new fields found
		 	*  consider that the Parameter list is the same as the field name list that would be in the INSERT statement
			*/
            
            
			IF oParameterList != '' THEN
				oParameterList := oParameterList || ', ' ;
						
			END IF ;
			
			IF oFieldNameList != '' THEN
				oFieldNameList := oFieldNameList || ',' ;

			END IF ;
			
			oParameterList := oParameterList || 'p_' || oRecord.column_name || ' ' || oRecord.data_type ;

		-- Parameter list  and field name lists:
		-- Not taking into account agn which is the primary key

			IF oRecord.column_name != oPrimaryKeyName THEN
				oFieldNameList := oFieldNameList|| oRecord.column_name ||' = '||'p_'|| oRecord.column_name ;

			ELSE
				-- Building the filter query WHERE agn = p_agn
				oFilter := ' WHERE '||oRecord.column_name||' = '||'p_'||oRecord.column_name ||';';
			END IF ;
		ELSE
			-- We have to place the closing parenthesis and the Exit the loop
			oParameterList := oParameterList || ')' ;
		
			EXIT ;
		END IF ;
		

	END LOOP ;
	oSQLCommand := oSQLCommand || oFieldNameList ||oFilter ;
	oFunctionBody := oFunctionBody || oParameterList;
	oFunctionBody := oFunctionBody || ' RETURNS VOID AS  ' || CHR(36) || CHR(36) || '  BEGIN ';

	oFunctionBody := oFunctionBody || oSQLCommand ;
	oFunctionBody := oFunctionBody || ' END; ' || CHR(36)||CHR(36) ||' LANGUAGE PLPGSQL ' ; 


	CLOSE oTableDef ;
	--INSERT INTO gquery(query) VALUES (oFunctionBody) ;
    EXECUTE ''||oFunctionBody ||'' ;
END;
$$ LANGUAGE PLPGSQL ;

CREATE OR REPLACE FUNCTION utils.generateInsertStoredProcedure(p_schemaName varchar,p_tableName varchar) returns void as  $$
DECLARE
	oRecord 			RECORD;
	oTableDef			REFCURSOR;

	oFunctionBody		VARCHAR;
	oSQLCommand			VARCHAR;
	oParameterList		VARCHAR;
	oFieldNameList		VARCHAR;
	oParameterValues	VARCHAR;
	oPrimaryKeyName     VARCHAR;
BEGIN
    oPrimaryKeyName := utils.getPrimaryKeyName(p_schemaName,p_tableName) ;
	oFunctionBody := 'CREATE OR REPLACE FUNCTION ' || p_schemaName || '.ins_' || p_tableName || '(';
	oSQLCommand :='INSERT INTO ' || p_schemaName || '.' || p_tableName || '(';
	OPEN oTableDef FOR SELECT utils.getFieldNames(p_schemaName,p_tableName);
	FETCH oTableDef INTO oTableDef; 

	--FETCH oTableDef INTO oRecord;
	oParameterList := '';
	oFieldNameList :='' ;
	oParameterValues   :='' ;
LOOP
		FETCH oTableDef INTO oRecord ;
		-- Function body at this point should include Parameter list
		IF FOUND THEN
			/** 
			* If we have a record Then we assign parameter list and continue building the SQL Command
			*
		 	* Inspecting if we must insert commas. The principal is as follows :
		 	*  If the parameter list is not empty i.e != '' then we have at least one element that is inserted and because the status is set to FOUND then it means the previous elements have to be appended with comma before adding the new fields found
		 	*  consider that the Parameter list is the same as the field name list that would be in the INSERT statement
			*/
			IF oParameterList != '' THEN
				oParameterList := oParameterList || ', ' ;
				oFieldNameList := oFieldNameList || ',' ;
				oParameterValues := oParameterValues || ',' ;
			END IF ;
			/**
			* Parameter list  and field name lists:
			* Not taking into account agn which is the primary key
            		*/
			IF oRecord.column_name != oPrimaryKeyName THEN
				oParameterValues := oParameterValues ||'p_'|| oRecord.column_name;
				oParameterList := oParameterList || 'p_' || oRecord.column_name || ' ' || oRecord.data_type ;
				oFieldNameList := oFieldNameList || oRecord.column_name ;
			END IF ;
		ELSE
			/**
            		* At this point nothing has been found in oRecord, 
            		* We can now proceed to close the SQL Command with either parenthesis or semi colon
            		* We have to place the closing parenthesis and the Exit the loop
            		*/
			oParameterList := oParameterList || ')' ;
			oFieldNameList := oFieldNameList || ')' ;
			oParameterValues := oParameterValues ||') ; ';
			EXIT ;
		END IF ;
	
	END LOOP;
	-- Let's build the SQL Command string, remembering that the oParameterList and oFieldNameList already contains the closing parenthesis
	oSQLCommand := oSQLCommand || oFieldNameList ;
	oSQLCommand := oSQLCommand || ' VALUES (' || oParameterValues ;
	
	oFunctionBody := oFunctionBody || oParameterList;
	oFunctionBody := oFunctionBody || ' RETURNS VOID AS  ' || CHR(36) || CHR(36) || '  BEGIN ';

	oFunctionBody := oFunctionBody || oSQLCommand ;
	oFunctionBody := oFunctionBody || ' END; ' || CHR(36)||CHR(36) ||' LANGUAGE PLPGSQL ' ; 

	CLOSE oTableDef ;
	-- INSERT INTO gQuery(query) VALUES (''||oFunctionBody||'') ;
	EXECUTE ''|| oFunctionBody || '';
END;
$$ LANGUAGE PLPGSQL ;
CREATE OR REPLACE FUNCTION utils.generateGetStoredProcedure(p_schemaName VARCHAR,p_tableName VARCHAR) RETURNS VOID AS $$
DECLARE
	oFunctionBody 	VARCHAR;
	oSQLQuery	VARCHAR;
BEGIN
	oFunctionBody 	:= 'CREATE OR REPLACE FUNCTION '||p_schemaName||'.get_' ||p_tableName||'() RETURNS REFCURSOR AS '||CHR(36)||CHR(36) ;
	oFunctionBody	:= oFunctionBody || ' DECLARE oCursor REFCURSOR; BEGIN ' ;
	oSQLQuery	    := ' OPEN oCursor FOR SELECT * FROM '||p_schemaName||'.'||p_tableName ||';' ;
	oFunctionBody 	:= oFunctionBody || oSQLQuery || ' RETURN oCursor; ';
	oFunctionBody	:= oFunctionBody ||' END; '||CHR(36) ||CHR(36)||' LANGUAGE PLPGSQL; ';
	--INSERT INTO gquery(query) VALUES(oFunctionBody) ;
	EXECUTE oFunctionBody ;

END;
$$LANGUAGE  PLPGSQL;

CREATE OR REPLACE FUNCTION utils.generateGetByAgnStoredProcedure(p_schemaName VARCHAR,p_tableName VARCHAR) RETURNS VOID AS $$
DECLARE
	oFunctionBody 	    VARCHAR ;
	oSQLQuery	        VARCHAR;
	oPrimaryKeyName     VARCHAR;
BEGIN
    oPrimaryKeyName := utils.getPrimaryKeyName(p_schemaName,p_tableName) ;
	oFunctionBody 	:= 'CREATE OR REPLACE FUNCTION '||p_schemaName||'.get_' ||p_tableName||'(p_Agn VARCHAR) RETURNS REFCURSOR AS '||CHR(36)||CHR(36) ;
	oFunctionBody	:= oFunctionBody || ' DECLARE oCursor REFCURSOR; BEGIN ' ;
	oSQLQuery	    := ' OPEN oCursor FOR SELECT * FROM '||p_schemaName||'.'||p_tableName ||' WHERE '||oPrimaryKeyName||' = p_Agn; ' ;
	oFunctionBody 	:= oFunctionBody || oSQLQuery || ' RETURN oCursor; ';
	oFunctionBody	:= oFunctionBody ||' END; '||CHR(36) ||CHR(36)||' LANGUAGE PLPGSQL; ';
	--INSERT INTO gquery(query) VALUES(oFunctionBody) ;
	EXECUTE oFunctionBody ;


END;
$$ LANGUAGE PLPGSQL ;

CREATE OR REPLACE FUNCTION utils.generateStoredProcedures(p_schemaName varchar,p_tableName varchar) returns void as $$
DECLARE 
	oFieldNames REFCURSOR ;
	oReferenceCount INTEGER;
BEGIN
	/*
	* In This area we insure that the p_schemaName and p_tableName exist
	* If the item does not exist then an exception is thrown
	*/
	 SELECT count(*) INTO oReferenceCount
	FROM information_schema.tables
	WHERE  table_schema = p_schemaName and table_name = p_tableName;
	if oReferenceCount != 1 THEN
		RAISE EXCEPTION 'Invalid schema name or table name entered ';
	ELSE 
		-- Loading field Names and assigning them to respective functions/stored procedures


--		OPEN oFieldNames FOR SELECT utils.getFieldNames(p_schemaName,p_tableName) ;
--		FETCH oFieldNames INTO oFieldNames ;
		-- Creating an insert stored procedure
		PERFORM utils.generateInsertStoredProcedure(p_schemaName,p_tableName) ;
		PERFORM utils.generateGetByAgnStoredProcedure(p_schemaName,p_tableName);
		PERFORM utils.generateUpdateStoredProcedure(p_schemaName,p_tableName);
		PERFORM utils.generateGetStoredProcedure(p_schemaName,p_tableName);
--		CLOSE oFieldNames ;
	END IF ;
END;


$$ LANGUAGE PLPGSQL ;

CREATE OR REPLACE FUNCTION utils.getPrimaryKeyName(p_schemaName varchar, p_tableName varchar) returns varchar as $$
DECLARE
       v_keyColumnName varchar  ;
       v_ConstraintName varchar ;
BEGIN
     SELECT constraint_name
     FROM information_schema.table_constraints
     WHERE table_schema = p_schemaName AND table_name = p_tableName AND constraint_type='PRIMARY KEY'
     INTO v_ConstraintName ;
     /**
     * At this point we have the constraint name and we will look for the column that maps to the primary key contraint name
     */
     IF NOT FOUND THEN
        RAISE EXCEPTION 'Missing Primary Key for selected schema/table '; --||p_schemaName||'.'||p_tableName) ;
     ELSE
          SELECT column_name
          FROM information_schema.constraint_column_usage
          WHERE table_schema = p_schemaName AND table_name = p_tableName AND constraint_name = v_ConstraintName
          INTO v_keyColumnName ;
     END IF ;
     
     RETURN v_keyColumnName ;
END ;
$$ LANGUAGE PLPGSQL ;
