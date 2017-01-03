REM This is required so we can check the errorlevel inside the FOR loop
SETLOCAL ENABLEDELAYEDEXPANSION

REM Verbose output check
if /i %VERBOSE%==yes echo Looking for:

REM Loop through the file...
for /f %%i in (stage_2_de-bloat\oem\programs_to_target_by_GUID.txt) do (
    REM  ...and for each line: a. check if it is a comment or SET command and b. perform the removal if not
    if not %%i==:: (
    if not %%i==set (
        if /i %VERBOSE%==yes echo    %%i
        start /wait msiexec /qn /norestart /x %%i >> "%LOGPATH%\%LOGFILE%" 2>nul

        REM Reset UpdateExeVolatile. I guess we could check to see if it's flipped, but eh, not really any point since we're just going to reset it anyway
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Updates" /v UpdateExeVolatile /d 0 /f >nul 2>&1

        REM Check if the uninstaller added entries to PendingFileRenameOperations. If it did, export the contents, nuke the key value, then continue on
        reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1
        if !errorlevel!==0 (
            echo Offending GUID: %%i >> "%RAW_LOGS%\PendingFileRenameOperations_%COMPUTERNAME%_%CUR_DATE%.txt"
            reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >> "%RAW_LOGS%\PendingFileRenameOperations_%COMPUTERNAME%_%CUR_DATE%.txt"
            reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /f >nul 2>&1
            if /i %VERBOSE%==yes echo  ^^! Detected filenames in PendingFileRenameOperations. Entries exported to "%RAW_LOGS%\PendingFileRenameOperations_%COMPUTERNAME%_%CUR_DATE%.txt" and deleted.
            echo  ^^! Detected filenames in PendingFileRenameOperations. Entries exported to "%RAW_LOGS%\PendingFileRenameOperations_%COMPUTERNAME%_%CUR_DATE%.txt" and deleted. >> "%LOGPATH%\%LOGFILE%"
            echo ------------------------------------------------------------------- >> "%RAW_LOGS%\PendingFileRenameOperations_%COMPUTERNAME%_%CUR_DATE%.txt"
            )
        )
    )
)
ENDLOCAL DISABLEDELAYEDEXPANSION
)
call functions\log.bat "%CUR_DATE% %TIME%    Done."
