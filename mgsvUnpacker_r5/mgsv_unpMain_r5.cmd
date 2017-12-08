@ECHO OFF
::CLS
SETLOCAL enableExtensions enableDelayedExpansion
PROMPT $BStack:$+$B$P$B$_

REM 'Stack' in the custom prompt is referring to the directory stack that grows with PUSHD. Easy to blow it if you're careless.

::###########################################################################################################

REM Parse and validate user input in config.txt
IF NOT EXIST config.txt ECHO config file does not exist. Performing default operations. & GOTO :f_getGameInstallPath

REM SET needs to be wrapped on this line because of how the config file is set up.
::	e.g. SET cfg%%A || would become cfgPullDats='1 ' ; note the space in the string.
::	Could also just write it as cfg%%A|| but that doesn't emphasize potential bugs
::	in case anyone tries learning from the script or wants to maintain it.

FOR /F "eol=[" %%A IN (config.txt) DO (SET "cfg%%A" || call :e_badConfig)
FOR /F "usebackq delims== tokens=1*" %%A IN (`SET cfg`) DO (IF %%B NEQ 1 SET %%A=)

IF DEFINED cfgEcho ECHO User enabled echo with Echo var input. & @ECHO ON

REM If user requested to skip a dat, skip all tool steps associated with it.
CALL :f_configFolder 000
CALL :f_configFolder 001
CALL :f_configFolder 100
CALL :f_configFolder 101
CALL :f_configFolder d1
FOR /L %%A IN (0,1,4) DO (
	CALL :f_configFolder c%%A
	CALL :f_configFolder t%%A
)
GOTO :f_getGameInstallPath

::###########################################################################################################

:f_configFolder
FOR /F "usebackq delims== tokens=1*" %%A IN (`SET cfg%1Skip 2^>NUL`) DO (
	SET var=%%A
	SET var=!var:~3!
	SET cfgDat_!var!=1
	SET cfgDds_!var!=1
	SET cfgFox_!var!=1
	SET cfgFpk_!var!=1
	SET cfgLang_!var!=1
)
SET var=
EXIT /B

::###########################################################################################################

:f_getGameInstallPath
SET key="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 287700"
FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY %key% /V InstallLocation`) DO (SET "tppDir=%%A %%B\master")
SET key="HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 287700"
IF NOT DEFINED tppDir (FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY %key% /V InstallLocation`) DO (SET "tppDir=%%A %%B\master"))
SET key=
IF NOT DEFINED tppDir GOTO :e_noGameDir
IF "%~dp0" EQU "%tppDir%" GOTO :e_badDirectory
GOTO :initOfEnvironment

::###########################################################################################################

:initOfEnvironment
REM Initializing other variables and filepaths. Checking that all tools are present and valid.
::MKDIR logs 2>NUL
::MKDIR exceptions 2>NUL
::MKDIR trash 2>NUL
::MKDIR archive 2>NUL
::MKDIR fileCounts 2>NUL

PUSHD unpacker_tools || CALL :e_badPush unpacker_tools
SET "toolDirTppGzs=%CD%\gzsTool"
SET "toolDirFox=%CD%\foxTool"
SET "toolDirTrans=%CD%\foxTrans"
SET "toolDirFtex=%CD%\ftexTool"
POPD

PUSHD "%toolDirFox%"
IF EXIST CityHash.dll (IF EXIST fox_dictionary.txt (IF EXIST FoxTool.exe (IF EXIST FoxTool.exe.config (ECHO 1>NUL)))) ELSE (GOTO :e_badToolFoxTool)
CALL :f_verifyDictionary fox_dictionary.txt
POPD

PUSHD "%toolDirFtex%"
IF EXIST FtexTool.exe (IF EXIST FtexTool.exe.config (IF EXIST ICSharpCode.SharpZipLib.dll (ECHO 1>NUL))) ELSE (CALL :e_badToolFtex)
POPD

PUSHD "%toolDirTppGzs%"
IF EXIST CityHash.dll (IF EXIST fpk_dictionary.txt (IF EXIST GzsTool.Core.dll (IF EXIST GzsTool.exe (IF EXIST GzsTool.exe.config (IF EXIST qar_dictionary.txt (ECHO 1>NUL)))))) ELSE (CALL :e_badToolGzsTpp)
CALL :f_verifyDictionary fpk_dictionary.txt
CALL :f_verifyDictionary qar_dictionary.txt
POPD

PUSHD "%toolDirTrans%"
IF EXIST CityHash.dll (IF EXIST FfntTool.exe (IF EXIST FfntTool.exe.config (IF EXIST lang_dictionary.txt (IF EXIST LangTool.exe (IF EXIST LangTool.exe.config (IF EXIST SubpTool.exe (IF EXIST SubpTool.exe.config (ECHO 1>NUL)))))))) ELSE (CALL :e_badToolFoxTranslation)
CALL :f_verifyDictionary lang_dictionary.txt
POPD

CALL :f_getDats

SET "folderTexturePatches=%~dp01%folderTexturePatches%\0"
SET "folderChunkPatches=%~dp00"
SET data1SubtitleFileDirectory=Assets\tpp\ui\Subtitles\subp
SET commonSubtitleFileDirectory=Assets\tpp\pack\ui\subtitles
SET commonSoundFileDirectory=Assets\tpp\sound

SET exeFfnt="%toolDirTrans%\FfntTool.exe"
SET exeFox="%toolDirFox%\FoxTool.exe"
SET exeFtex="%toolDirFtex%\FtexTool.exe"
SET exeGzsTpp="%toolDirTppGzs%\GzsTool.exe"
SET exeLang="%toolDirTrans%\LangTool.exe"
SET exeSubp="%toolDirTrans%\SubpTool.exe"

REM Renaming directories made by QARTool to use GzsTool's naming convention if they exist.
:: quick note that QARTool is significantly faster than GzsTool by a few minutes when doing an unpack on all dats. This script uses GzsTool on .dat files for the sake of naming consistency and readability of repack files.
RENAME 0\00 0\00_dat 2>NUL
RENAME 0\01 0\01_dat 2>NUL
RENAME "%folderTexturePatches%\00" 00_dat 2>NUL
RENAME "%folderTexturePatches%\01" 01_dat 2>NUL
RENAME chunk0 chunk0_dat 2>NUL
RENAME chunk1 chunk1_dat 2>NUL
RENAME chunk2 chunk2_dat 2>NUL
RENAME chunk3 chunk3_dat 2>NUL
RENAME chunk4 chunk4_dat 2>NUL
RENAME texture0 texture0_dat 2>NUL
RENAME texture1 texture1_dat 2>NUL
RENAME texture2 texture2_dat 2>NUL
RENAME texture3 texture3_dat 2>NUL
RENAME texture4 texture4_dat 2>NUL

REM Skipping init count for now. It was too slow, added too much complexity, and made the file hard to maintain.

GOTO :main

::###########################################################################################################

:f_verifyDictionary
REM Check that dictionary entry counts match up with current versions
FOR /F "usebackq" %%A IN (`FIND /V /C "" ^<%1`) DO (SET n=%%A)

IF %1 EQU fox_dictionary.txt (SET compOp=LSS 21543) ELSE (
	IF %1 EQU fpk_dictionary.txt (SET compOp=LSS 2063) ELSE (
		IF %1 EQU lang_dictionary.txt (SET compOp=NEQ 11102) ELSE (
			IF %1 EQU qar_dictionary.txt (SET compOp=LSS 38780)
		)
	)
)

IF %n% %compOp% CALL :e_oldDictionary %1
SET n=
EXIT /B

::###########################################################################################################

:f_getDats
REM Copy master folder directory structure
ROBOCOPY "%tppDir%" "%CD%" /S /E /NOCOPY /NP /XJ /MT:8 /R:0 /W:0
PUSHD 1\MGSVTUPDATE*\0 || CALL :e_badPush 1\MGSVTUPDATE*\0
POPD
PUSHD 1\MGSVTUPDATE*
FOR %%* IN (.) DO (SET folderTexturePatches=%%~nx*)
POPD

IF NOT DEFINED cfgPullDats EXIT /B

REM Skip files as requested by user and copy files only if they do not already exist in unpack folder
SET "exclude= "
IF DEFINED cfg000Skip SET "exclude=%exclude% 00.dat"
IF DEFINED cfg001Skip SET "exclude=%exclude% 01.dat"
ROBOCOPY "%tppDir%\0" 0 *.dat /XF "%exclude%" /S /NODCOPY /COPY:DT /XO /XN /XC /XJ /MT:8 /R:0 /W:0

SET "exclude= "
IF DEFINED cfg100Skip SET "exclude=%exclude% 00.dat"
IF DEFINED cfg101Skip SET "exclude=%exclude% 01.dat"
ROBOCOPY "%tppDir%\1\%folderTexturePatches%\0" "1\%folderTexturePatches%\0" *.dat /XF "%exclude%" /S /NODCOPY /COPY:DT /XO /XN /XC /XJ /MT:8 /R:0 /W:0

SET "exclude=e2f*dat"
IF DEFINED cfgd1Skip SET "exlude=%exclude% data1.dat"
IF DEFINED cfgc0Skip SET "exclude=%exclude% chunk0.dat"
IF DEFINED cfgc1Skip SET "exclude=%exclude% chunk1.dat"
IF DEFINED cfgc2Skip SET "exclude=%exclude% chunk2.dat"
IF DEFINED cfgc3Skip SET "exclude=%exclude% chunk3.dat"
IF DEFINED cfgc4Skip SET "exclude=%exclude% chunk4.dat"
IF DEFINED cfgt0Skip SET "exclude=%exclude% texture0.dat"
IF DEFINED cfgt1Skip SET "exclude=%exclude% texture1.dat"
IF DEFINED cfgt2Skip SET "exclude=%exclude% texture2.dat"
IF DEFINED cfgt3Skip SET "exclude=%exclude% texture3.dat"
IF DEFINED cfgt4Skip SET "exclude=%exclude% texture4.dat"

REM For some reason ROBOCOPY doesn't like a quoted %~dp0 destination parameter
ROBOCOPY "%tppDir%" "%CD%" *.dat /XF "%exclude%" /NODCOPY /COPY:DT /XO /XN /XC /XJ /MT:8 /R:0 /W:0
SET exclude=

EXIT /B

::###########################################################################################################

:main
REM While the pseudo-function calls do use the same variables, they are redefined each call and are all NUL'd [destroyed] before finishing a conditional block.

IF NOT DEFINED cfgDatSkip (
::								target					abrv		unpackedFolder
	CALL :f_unpackDats	"%folderChunkPatches%\00.dat"	000		"%folderChunkPatches%\00_dat"
	CALL :f_unpackDats	"%folderChunkPatches%\01.dat"	001		"%folderChunkPatches%\01_dat"
	CALL :f_unpackDats	"%folderTexturePatches%\00.dat"	100		"%folderTexturePatches%\00_dat"
	CALL :f_unpackDats	"%folderTexturePatches%\01.dat"	101		"%folderTexturePatches%\01_dat"
	CALL :f_unpackDats	"%~dp0data1.dat"				d1		"%~dp0data1_dat"
	CALL :f_unpackDats	"%~dp0chunk0.dat"				c0		"%~dp0chunk0_dat"
	CALL :f_unpackDats	"%~dp0chunk1.dat"				c1		"%~dp0chunk1_dat"
	CALL :f_unpackDats	"%~dp0chunk2.dat"				c2		"%~dp0chunk2_dat"
	CALL :f_unpackDats	"%~dp0chunk3.dat"				c3		"%~dp0chunk3_dat"
	CALL :f_unpackDats	"%~dp0chunk4.dat"				c4		"%~dp0chunk4_dat"
	CALL :f_unpackDats	"%~dp0texture0.dat"				t0		"%~dp0texture0_dat"
	CALL :f_unpackDats	"%~dp0texture1.dat"				t1		"%~dp0texture1_dat"
	CALL :f_unpackDats	"%~dp0texture2.dat"				t2		"%~dp0texture2_dat"
	CALL :f_unpackDats	"%~dp0texture3.dat"				t3		"%~dp0texture3_dat"
	CALL :f_unpackDats	"%~dp0texture4.dat"				t4		"%~dp0texture4_dat"

	SET target=
	SET abrv=
	SET unpackedFolder=

	ECHO Finished unpacking .dat files.
)

IF NOT DEFINED cfgFpkSkip (
::											target						abrv					fpkFileThatVerifiesToolRan																pftxsOrSbpFileThatVerifiesToolRan
	CALL :f_unpackFpkdPftxsSbpFiles	"%folderChunkPatches%\00_dat"		000		"%folderChunkPatches%\00_dat\Assets\tpp\pack\ui\ui_respawn_menu.fpk.xml"						"%folderChunkPatches%\00_dat\Assets\tpp\pack\ui\ui_respawn_menu.pftxs.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%folderTexturePatches%\00_dat"		100		"%folderTexturePatches%\00_dat\Assets\tpp\pack\player\fova\plfova_sna8_main0_c60.fpkd.xml"		"%folderTexturePatches%\00_dat\Assets\tpp\pack\player\fova\plfova_sna8_main0_c60.pftxs.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%~dp0chunk0_dat"					c0		"%~dp0chunk0_dat\Assets\tpptest\pack\location\empty\empty.fpkd.xml"								"%~dp0chunk0_dat\Assets\tpp\sound\asset\vox_sna.sbp.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%~dp0chunk1_dat"					c1		"%~dp0chunk1_dat\Assets\tpp\pack\vehicle\veh_rl_west_wav_machinegun.fpkd.xml"					"%~dp0chunk1_dat\Assets\tpp\sound\asset\vox_zmb.sbp.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%~dp0chunk2_dat"					c2		"%~dp0chunk2_dat\Assets\tpp\pack\mission2\story\s10260\s10260_ending.fpkd.xml"					"%~dp0chunk2_dat\Assets\tpp\sound\asset\vox_s10260.sbp.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%~dp0chunk3_dat"					c3		"%~dp0chunk3_dat\Assets\tpp\pack\mission2\story\s10240\s10240_d03.fpkd.xml"						"%~dp0chunk3_dat\Assets\tpp\sound\asset\vox_s10240_type0.sbp.xml"
	CALL :f_unpackFpkdPftxsSbpFiles	"%~dp0chunk4_dat"					c4		"%~dp0chunk4_dat\Assets\tpp\pack\mission2\story\s10211\s10211_order_box.fpkd.xml"				"%~dp0chunk4_dat\Assets\tpp\sound\asset\vox_s10211.sbp.xml"

	SET target=
	SET abrv=
	SET fpkFileThatVerifiesToolRan=
	SET pftxsOrSbpFileThatVerifiesToolRan=

	ECHO Finished extracting all .fpk, .fpkd, .pftxs, and .sbp files.
)

IF NOT DEFINED cfgFoxSkip (
::											target						abrv													xmlFileThatVerifiesToolRan
	CALL :f_unpackFoxEngineFiles	"%folderChunkPatches%\00_dat"		000		"%folderChunkPatches%\00_dat\Assets\tpp\pack\ui\ui_pause_store_fpkd\Assets\tpp\ui\GraphAsset\entry_datas\pause_store_entry.fox2.xml"
	CALL :f_unpackFoxEngineFiles	"%folderTexturePatches%\00_dat"		100		"%folderTexturePatches%\00_dat\Assets\tpp\pack\player\fova\plfova_sna8_main0_c60_fpkd\Assets\tpp\level_asset\chara\player\game_object\plfova_sna8_main0_c60.fox2.xml"
	CALL :f_unpackFoxEngineFiles	"%~dp0chunk0_dat"					c0		"%~dp0chunk0_dat\Assets\tpptest\pack\location\empty\empty_fpkd\Assets\tpptest\level\location\empty\empty_stage.fox2.xml"
	CALL :f_unpackFoxEngineFiles	"%~dp0chunk1_dat"					c1		"%~dp0chunk1_dat\Assets\tpp\pack\vehicle\veh_rl_west_wav_machinegun_fpkd\Assets\tpp\parts\mecha\wav\wav0_turt1_def.tgt.xml"
	CALL :f_unpackFoxEngineFiles	"%~dp0chunk2_dat"					c2		"%~dp0chunk2_dat\Assets\tpp\pack\mission2\story\s10260\s10260_ending_fpkd\Assets\tpp\ui\GraphAsset\entry_datas\ending_quiet.fox2.xml"
	CALL :f_unpackFoxEngineFiles	"%~dp0chunk3_dat"					c3		"%~dp0chunk3_dat\Assets\tpp\pack\mission2\story\s10240\s10240_d03_fpkd\Assets\tpp\parts\item\cof\cof0_main0_def_V00.parts.xml"
	CALL :f_unpackFoxEngineFiles	"%~dp0chunk4_dat"					c4		"%~dp0chunk4_dat\Assets\tpp\pack\mission2\story\s10211\s10211_order_box_fpkd\Assets\tpp\level\mission2\story\s10211\s10211_order_box_script.fox2.xml"

	SET target=
	SET abrv=
	SET xmlFileThatVerifiesToolRan=

	ECHO Finished decompiling all FoxEngine files.
)

IF NOT DEFINED cfgLangSkip (
::											target					abrv	ffnt	lang	subp
	CALL :f_unpackLocalizationFiles "%folderChunkPatches%\00_dat"	000		FALSE	TRUE	FALSE
	CALL :f_unpackLocalizationFiles "%~dp0data1_dat"				d1		TRUE	FALSE	TRUE
	CALL :f_unpackLocalizationFiles "%~dp0chunk0_dat"				c0		FALSE	TRUE	TRUE
	CALL :f_unpackLocalizationFiles "%~dp0chunk2_dat"				c2		FALSE	TRUE	TRUE
	CALL :f_unpackLocalizationFiles "%~dp0chunk3_dat"				c3		FALSE	TRUE	TRUE
	CALL :f_unpackLocalizationFiles "%~dp0chunk4_dat"				c4		FALSE	FALSE	TRUE

	SET target=
	SET abrv=
	SET folderHasFontFiles=
	SET folderHasLangFiles=
	SET folderHasSubtitleFiles=

	ECHO Finished running Fox.TranslationTools on all localization files.
)

IF NOT DEFINED cfgDdsSkip (
::									target					abrv
	CALL :f_unpackFtexFiles	"%folderChunkPatches%\00_dat"	000
	CALL :f_unpackFtexFiles	"%folderChunkPatches%\01_dat"	001
	CALL :f_unpackFtexFiles	"%folderTexturePatches%\00_dat"	100
	CALL :f_unpackFtexFiles	"%folderTexturePatches%\01_dat"	101
	CALL :f_unpackFtexFiles	"%~dp0chunk0_dat"				c0
	CALL :f_unpackFtexFiles	"%~dp0texture0_dat"				t0
	CALL :f_unpackFtexFiles	"%~dp0texture1_dat"				t1
	CALL :f_unpackFtexFiles	"%~dp0texture2_dat"				t2
	CALL :f_unpackFtexFiles	"%~dp0texture3_dat"				t3
	CALL :f_unpackFtexFiles	"%~dp0texture4_dat"				t4

	SET target=
	SET abrv=

	ECHO Finished running FtexTool.exe on all files.
)

CLS
PROMPT
EXIT

::###########################################################################################################

:f_unpackDats
SET target=%1
SET abrv=%2
SET unpackedFolder=%3

IF DEFINED cfgDat_%abrv%Skip EXIT /B
IF NOT EXIST %target% EXIT /B
IF EXIST %unpackedFolder% EXIT /B

ECHO Unpacking %target%
%exeGzsTpp% %target% 1>NUL
EXIT /B

::###########################################################################################################

:f_unpackFpkdPftxsSbpFiles
SET target=%1
SET abrv=%2
SET fpkFileThatVerifiesToolRan=%3
SET pftxsOrSbpFileThatVerifiesToolRan=%4

IF NOT EXIST %target% EXIT /B
IF NOT EXIST %fpkFileThatVerifiesToolRan% CALL :nestF_unpackFpkd
IF NOT EXIST %pftxsOrSbpFileThatVerifiesToolRan% CALL :nestF_unpackPftxsSbp

:nestF_unpackFpkd
IF DEFINED cfgFpk_%abrv%Skip ECHO Skipping .fpk and .fpkd files in %target% & EXIT /B
ECHO Unpacking .fpk and .fpkd files in %target%
%exeGzsTpp% %target% 1>NUL
EXIT /B

:nestF_unpackPftxsSbp
IF DEFINED cfgPftxsSbp_%abrv%Skip ECHO Skipping .pftxs and .sbp files in %target% & EXIT /B
ECHO Unpacking any .pftxs and .sbp files in %target%
FOR /R %%A IN (*.pftxs *.sbp) DO (%exeGzsTpp% "%%A")1>NUL
EXIT /B

::###########################################################################################################

:f_unpackFoxEngineFiles
SET target=%1
SET abrv=%2
SET xmlFileThatVerifiesToolRan=%3

IF DEFINED cfgFox_%abrv%Skip EXIT /B
IF NOT EXIST %target% EXIT /B
IF EXIST %xmlFileThatVerifiesToolRan% EXIT /B

ECHO Decompiling FoxEngine files in %target%
%exeFox% %target% 1>NUL
EXIT /B

::###########################################################################################################

:f_unpackLocalizationFiles
SET target=%1
SET abrv=%2
SET folderHasFontFiles=%3
SET folderHasLangFiles=%4
SET folderHasSubtitleFiles=%5

IF DEFINED cfgLang_%abrv%Skip EXIT /B
IF NOT EXIST %target% EXIT /B

PUSHD %target%

IF %folderHasFontFiles%==TRUE (
	ECHO Running FfntTool.exe on %target%
	FOR /R %%A IN (*.ffnt) DO (%exeFfnt% "%%A")1>NUL
)

IF %folderHasLangFiles%==TRUE (
	ECHO Running LangTool.exe on %target%
	COPY "%toolDirTrans%\lang_dictionary.txt" 1>NUL
	FOR /R %%A IN (*.lng?) DO (%exeLang% "%%A")1>NUL
	DEL /F /Q lang_dictionary.txt 1>NUL
)

IF %folderHasSubtitleFiles%==TRUE CALL :f_unpackSubpFiles

POPD
EXIT /B

::###########################################################################################################

:f_unpackSubpFiles
ECHO Starting recursive unpack of subtitle files in %target%
IF "%CD%" EQU "%~dp0data1_dat" (PUSHD "%data1SubtitleFileDirectory%\*Voice" || ECHO Unable to change to %target% expected path of "%data1SubtitleFileDirectory%\*Voice" && EXIT /B) ELSE (PUSHD "%commonSubtitleFileDirectory%\*Voice" || ECHO Unable to change to %target% expected .subp path of "%commonSubtitleFileDirectory%\*Voice" && EXIT /B)

ECHO "Running SubpTool.exe on any English, French, German, Italian, and Spanish files with ISO-8859-1 encoding."
PUSHD EngText 2>NUL && CALL :nestF_encodeISO1 || ECHO English subtitles do not exist in "%CD%"
PUSHD FreText 2>NUL && CALL :nestF_encodeISO1 || ECHO French subtitles do not exist in "%CD%"
PUSHD GerText 2>NUL && CALL :nestF_encodeISO1 || ECHO German subtitles do not exist in "%CD%"
PUSHD ItaText 2>NUL && CALL :nestF_encodeISO1 || ECHO Italian subtitles do not exist in "%CD%"
PUSHD SpaText 2>NUL && CALL :nestF_encodeISO1 || ECHO Spanish subtitles do not exist in "%CD%"

ECHO "Running SubpTool.exe on any Russian files with ISO-8859-5 encoding."
PUSHD RusText 2>NUL && CALL :nestF_encodeISO5 || ECHO Russian subtitles do not exist in "%CD%"

ECHO "Running SubpTool.exe on any Arabic, Japanese, and Portuguese files with UTF-8 encoding." 
PUSHD AraText 2>NUL && CALL :nestF_encodeUTF || ECHO Arabic subtitles do not exist in "%CD%"
PUSHD JpnText 2>NUL && CALL :nestF_encodeUTF || ECHO Japanese subtitles do not exist in "%CD%"
PUSHD PorText 2>NUL && CALL :nestF_encodeUTF || ECHO Portuguese subtitles do not exist in "%CD%"

POPD
EXIT /B

:nestF_encodeISO1
FOR /R %%A IN (*.subp) DO (%exeSubp% "%%A")1>NUL
POPD
EXIT /B

:nestF_encodeISO5
FOR /R %%A IN (*.subp) DO (%exeSubp% -rus "%%A")1>NUL
POPD
EXIT /B

:nestF_encodeUTF
FOR /R %%A IN (*.subp) DO (%exeSubp% -ara "%%A")1>NUL
POPD
EXIT /B

::###########################################################################################################

:f_unpackFtexFiles
SET target=%1
SET abrv=%2

IF DEFINED cfgDds_%abrv%Skip ECHO Skipping unpack of .ftex files in %target% & EXIT /B
IF NOT EXIST %target% ECHO %target% does not exist; returning to call line. & EXIT /B

ECHO Unpacking .ftex files as .dds in %target%
%exeFtex% %target% 1>NUL
EXIT /B

::###########################################################################################################

REM Exception handling messages
:e_badCount
(
	ECHO Error 01
	ECHO __ __ __
	ECHO Failed to unpack all target files or folder is from unsupported game version.
	ECHO Expected __ or greater, got __
	ECHO.
) 1>> __
EXIT /B

:e_badDirectory
CLS
ECHO Error 02
ECHO This batch file is not designed to be run within __
ECHO Place the batch folder somewhere else, such as your desktop.
PROMPT
PAUSE
EXIT

:e_gameRunning
CLS
ECHO Error 03
ECHO The batch file cannot copy .dat files from your game directory while MGSV:TPP is running.
ECHO Close it before running the batch file again.
ECHO You can continue once all requested files have been copied and the unpacking process begins.
PROMPT
PAUSE
EXIT

:e_snakebiteEnabled
CLS
ECHO Error 04
ECHO Toggle SnakeBite's mod switch to disabled before running the batch file again.
ECHO You can continue once all requested files have been copied and the unpacking process begins.
PROMPT
PAUSE
EXIT

:e_badPush
CLS
ECHO Error 05
ECHO Failed to change directories.
ECHO Tried PUSHD %1 from "%CD%"
ECHO Further attempts at unpacking would likely result in side effects.
ECHO Unable to continue.
PROMPT
PAUSE
EXIT

:e_badToolGzsTpp
CLS
ECHO Error 06
ECHO GzsTool
ECHO A tool used by the batch file does not exist or is missing components.
IF NOT EXIST GzsTool.exe ECHO GzsTool.exe is missing.
IF NOT EXIST GzsTool.exe.config ECHO GzsTool.exe.config is missing.
IF NOT EXIST qar_dictionary.txt ECHO qar_dictionary.txt is missing.
IF NOT EXIST fpk_dictionary.txt ECHO fpk_dictionary.txt is missing.
IF NOT EXIST CityHash.dll ECHO CityHash.dll is missing.
IF NOT EXIST Zlib.Portable.dll ECHO Zlib.Portable.dll is missing.
ECHO Check __ for any missing files.
ECHO Add the missing files, redownload the batch file, or download GzsTool.
ECHO https://github.com/Atvaark/GzsTool
PROMPT
PAUSE
EXIT

:e_badToolFoxTool
CLS
ECHO Error 07
ECHO FoxTool
ECHO A tool used by the batch file does not exist or is missing components.
IF NOT EXIST FoxTool.exe ECHO FoxTool.exe is missing.
IF NOT EXIST FoxTool.exe.config ECHO FoxTool.exe.config is missing.
IF NOT EXIST fox_dictionary.txt ECHO fox_dictionary.txt is missing.
IF NOT EXIST CityHash.dll ECHO CityHash.dll is missing.
ECHO Check __ for any missing files.
ECHO Add the missing files, redownload the batch file, or download FoxTool.
ECHO https://github.com/Atvaark/FoxTool
PROMPT
PAUSE
EXIT

:e_badToolFoxTranslation
CLS
ECHO Error 08
ECHO Fox.TranslationTools
ECHO A tool used by the batch file does not exist or is missing components.
IF NOT EXIST FfntTool.exe ECHO FfntTool.exe is missing.
IF NOT EXIST FfntTool.exe.config ECHO FfntTool.exe.config is missing.
IF NOT EXIST SubpTool.exe ECHO SubpTool.exe is missing.
IF NOT EXIST SubpTool.exe.config ECHO SubpTool.exe.config is missing.
IF NOT EXIST LangTool.exe ECHO LangTool.exe is missing.
IF NOT EXIST lang_dictionary.txt ECHO lang_dictionary.txt is missing.
IF NOT EXIST CityHash.dll ECHO CityHash.dll is missing.
ECHO Check __ for any missing files.
ECHO Add the missing files, redownload the batch file, or download Fox.TranslationTools.
ECHO https://github.com/Atvaark/FoxEngine.TranslationTool
PROMPT
PAUSE
EXIT

:e_badToolFtex
CLS
ECHO Error 09
ECHO FtexTool
ECHO A tool used by the batch file does not exist or is missing components.
IF NOT EXIST FtexTool.exe ECHO FtexTool.exe is missing.
IF NOT EXIST FtexTool.exe.config ECHO FtexTool.exe.config is missing.
IF NOT EXIST ICSharpCode.SharpZipLib.dll ECHO ICSharpCode.SharpZipLib.dll is missing.
ECHO Check __ for any missing files.
ECHO Add the missing files, redownload the batch file, or download FtexTool.
ECHO https://github.com/Atvaark/FtexTool
PROMPT
PAUSE
EXIT

:e_oldDictionary
CLS
ECHO Error 10
ECHO %1 in %2 is outdated.
ECHO Replace it with the latest version.
ECHO.
ECHO FOX: https://github.com/Atvaark/FoxTool/blob/master/FoxTool/fox_dictionary.txt
ECHO LANG: https://github.com/Atvaark/FoxEngine.TranslationTool/blob/master/LangTool/lang_dictionary.txt
ECHO QAR: https://github.com/emoose/MGSV-QAR-Dictionary-Project/blob/master/dictionary.txt
ECHO.
ECHO Press any button to ignore this warning and continue (files will not be unpacked properly and fail validation counts).
PAUSE
EXIT /B

:e_badConfig
CLS
ECHO Error 11
ECHO A variable used by the batch file coult not be defined with config.txt.
ECHO.
ECHO If you edit config.txt, ensure that variables are only assigned the values 0 or 1.
ECHO If you added any additional text, remember that space and tab characters are ignored.
ECHO.
ECHO [
ECHO That is the EOL character used for parsing the file.
ECHO Any same-line characters after it will be ignored.
ECHO.
ECHO A variable needs to be assigned something with =
ECHO e.g. varSkip=1
ECHO Setting varSkip= would be invalid because CMD interprets it as varSkip=NUL (nil, void, nothing)
ECHO.
ECHO If you can not fix the config file then just redownload the batch file.
PROMPT
PAUSE
EXIT

:e_noFile
CLS
ECHO Error 12
ECHO File %1 does not exist
PROMPT
PAUSE
EXIT

:e_noGameDir
CLS
ECHO Error 13
ECHO Could not locate your Steam game directory!
PROMPT
PAUSE
EXIT