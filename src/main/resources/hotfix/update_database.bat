@echo off
setlocal

rem ---------------------------------------------------------------------------
rem
rem HF-009
rem This script will update the Spotfire Database to the format of HF-009
rem
rem Before using this script you need to:
rem     set the following variables below:
rem         * CONNECTIDENTIFIER
rem         * SERVERDB_NAME
rem         * SERVERDB_USER
rem         * SERVERDB_PASSWORD
rem
rem     replace <SERVER> with the name of the server running the SQL Server instance.
rem     replace <MSSQL_INSTANCENAME> with the name of the SQL Server instance.
rem
rem ---------------------------------------------------------------------------

rem Set these variables to reflect the local environment:
set CONNECTIDENTIFIER=%1	
set SERVERDB_NAME=%2
set SERVERDB_USER=%3
set SERVERDB_PASSWORD=%4

@echo Performing update
sqlcmd -S%CONNECTIDENTIFIER% -U%SERVERDB_USER% -P%SERVERDB_PASSWORD% -i hotfix.sql -v SERVERDB_NAME="%SERVERDB_NAME%" > log_hotfix.txt
if %errorlevel% neq 0 (
  @echo Error while running SQL script 'hotfix.sql'
  @echo For more information consult the log_hotfix.txt file
  exit /B 1
)

@echo -----------------------------------------------------------------
@echo Please review the log file (log_hotfix.txt) for any errors or warnings!
endlocal
