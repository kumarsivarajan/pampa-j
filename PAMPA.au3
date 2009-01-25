#include <Array.au3>
#include <Constants.au3>
#include <StaticConstants.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
Opt("TrayMenuMode", 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PAMPA() ;; (c) Andrea Giammarchi - GPL License               ;;
;; Portable Apache, MySQL, and PHP Application               ;;
;; now with Aptana Jaxer included                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General non-dedicated functions                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Func isTrue($value) ;; returns True if a generic variable is 1, true, on, or ok (not case sensitive)
	Local $result = False
	Local $compare = StringLower($value)
	If $compare == '1' Or $compare == 'true' Or $compare == 'on' Or $compare == 'ok' Then
		$result = True
	EndIf
	Return $result
EndFunc

Func kill($pid) ;; kill a process and its subprocesses via taskkill windows command.
			    ;; If the process still exists, remove PAMPA dependency trying to close it
	If ProcessExists($pid) Then
		RunWait('taskkill /T /F /PID ' & $pid, @SystemDir, @SW_HIDE)
		If ProcessExists($pid) Then
			ProcessClose($pid)
		EndIf
	EndIf
EndFunc

Func path($str)
	Return StringReplace(StringReplace($str, "/", "\"), "\\", "\")
EndFunc

Func read($file) ;; returns the content of a file, if present, empty string otherwise
	Local $fp = FileOpen($file, 0)
	Local $str = ""
	If $fp <> -1 Then
		$str = FileRead($fp, FileGetSize($file))
		FileClose($fp)
	EndIf
	Return $str
EndFunc

Func write($file, $msg) ;; erease a file, if present, and writes content
	If FileExists($file) Then
		FileDelete($file)
	EndIf
	Local $fp = FileOpen($file, 1)
	FileWriteLine($fp, $msg)
	FileClose($fp)
EndFunc



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Third parts software dedicated functions                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func PAMPA_Apache() ;; create the string to launch Apache reading directives from PAMPA/config/pampa.ini file and launch it
	Local $getoutSinceThereIsSomethingWrong = 0
	Local $webport = IniRead($PAMPA_INI_FILE, 'Jaxer', 'webport', '')
	Local $Listen = IniRead($PAMPA_INI_FILE, 'Apache', 'Listen', '')
	Local $ServerName = IniRead($PAMPA_INI_FILE, 'Apache', 'ServerName', '')
	Local $ServerAdmin = IniRead($PAMPA_INI_FILE, 'Apache', 'ServerAdmin', '')
	Local $DefaultType = IniRead($PAMPA_INI_FILE, 'Apache', 'DefaultType', '')
	Local $LogLevel = IniRead($PAMPA_INI_FILE, 'Apache', 'LogLevel', '')
	Local $PidFile = IniRead($PAMPA_INI_FILE, 'Apache', 'PidFile', '')
	Local $ErrorLog = IniRead($PAMPA_INI_FILE, 'Apache', 'ErrorLog', '')
	Local $ServerRoot = IniRead($PAMPA_INI_FILE, 'Apache', 'ServerRoot', '')
	Local $DocumentRoot = $PAMPA_APACHE_DOCUMENT_ROOT
	If $webport == '' Then
		$webport = '4327'
	EndIf
	If $Listen == '' Then
		$Listen = '85'
	EndIf
	If $ServerName == '' Then
		$ServerName = 'PAMPA'
	EndIf
	If $ServerAdmin == '' Then
		$ServerAdmin = 'pampa@portable.wamp'
	EndIf
	If $DefaultType == '' Then
		$DefaultType = 'text/html'
	EndIf
	If $LogLevel == '' Then
		$LogLevel = 'warn'
	EndIf
	If $PidFile == '' Then
		$PidFile = $PAMPA_TMP_PREFIX & 'apache.pid'
	EndIf
	If $ErrorLog == '' Then
		$ErrorLog = $PAMPA_TMP_PREFIX & 'apache.log'
	EndIf
	If $ServerRoot == '' Then
		$ServerRoot = $PAMPA_PATH & '\PAMPA\apache.32'
	EndIf
	Local $apache = 'PAMPA\apache.32\bin\httpd.exe -d "' & $PAMPA_PATH & '\PAMPA\apache" '
	If $PAMPA_LAUNCH_JAXER Then
		$apache &= '-C "LoadModule jaxer_module ''' & $PAMPA_PATH & '\PAMPA\jaxer.32\connectors\mod_jaxer.so''" '
		$apache &= '-C "JaxerWorker 127.0.0.1 ' & $webport & '" '
		$apache &= '-C "Alias /aptana ''' & $PAMPA_PATH & '\PAMPA\jaxer.32\aptana''" '
		$apache &= '-C "Alias /public ''' & $PAMPA_PATH & '\PAMPA\apache.32\htdocs\public''" '
		$apache &= '-C "Alias /jaxer/framework/clientFramework_compressed.js ''' & $PAMPA_PATH & '\PAMPA\jaxer.32\framework\clientFramework_compressed.js''" '
		$apache &= '-C "Alias /jaxer/framework/clientFramework.js ''' & $PAMPA_PATH & '\PAMPA\jaxer.32\framework\clientFramework.js''" '
		$apache &= '-c "Include ''' & $PAMPA_PATH & '\PAMPA\config\jaxer.conf''" '
	EndIf
	If $PAMPA_LAUNCH_PHP Then
		$apache &= '-C "LoadModule php5_module ''' & $PAMPA_PATH & '\PAMPA\php.32\php5apache2_2.dll''" '
		$apache &= '-C "PHPIniDir ''' & $PAMPA_PATH & '\PAMPA\config\php.ini''" '
		$apache &= '-C "addtype application/x-httpd-php .php .phps .php5 .php4 .phar" '
	EndIf
	$apache &= '-C "Listen ''' & $Listen & '''" '
	$apache &= '-C "ServerName ''' & $ServerName & '''" '
	$apache &= '-C "ServerAdmin ''' & $ServerAdmin & '''" '
	$apache &= '-C "DefaultType ''' & $DefaultType & '''" '
	$apache &= '-C "LogLevel ''' & $LogLevel & '''" '
	$apache &= '-C "PidFile ''' & $PidFile & '''" '
	$apache &= '-C "ErrorLog ''' & $ErrorLog & '''" '
	$apache &= '-C "DocumentRoot ''' & $DocumentRoot & '''" '
	$apache &= '-C "ServerRoot ''' & $ServerRoot & '''" '
	$apache &= '-C "Alias /icons/ ''' & $ServerRoot & '\icons\''" '
	$apache &= '-C "ScriptAlias /cgi-bin/ ''' & $ServerRoot & '\cgi-bin\''" '
	$apache &= '-f "' & $PAMPA_PATH & '\PAMPA\config\httpd.conf" '
	If $PAMPA_DEBUG Then
		write('apache.bat', 'start /B ' & $apache)
	EndIf
	Global $PAMPA_APACHE_PORT = $Listen
	Global $PAMPA_APACHE = Run($apache, @ScriptDir, @SW_HIDE)
EndFunc

Func PAMPA_Browser() ;; uses the default browser if X-Firefox is not present (ready for WinPenPack project)
	Local $firefox = '/MAX'
	Local $browser
	If FileExists("..\..\XDrive\X-Firefox.exe") Then
		$firefox = '"winPenPack" /MAX "..\..\XDrive\X-Firefox.exe"'
	EndIf
	$browser = @ComSpec & ' /c start ' & $firefox & ' http://127.0.0.1'
	If $PAMPA_APACHE_PORT <> '80' Then
		$browser &= ':' & $PAMPA_APACHE_PORT
	EndIf
	$browser &= '/'
	If $PAMPA_DEBUG Then
		write('browser.bat', $browser)
	EndIf
	While InetGetSize('http://127.0.0.1:' & $PAMPA_APACHE_PORT & '/') < 0
		If @error <> 0 Or $getoutSinceThereIsSomethingWrong == 49 Then
			$PAMPA_ERROR = True
			TrayTip("Warning", "Please be sure the port " & $PAMPA_APACHE_PORT & " is not used and/or Apache has been authorized", 3, 2)
			ExitLoop
		EndIf
		PAMPA_Sleep(200)
		$getoutSinceThereIsSomethingWrong = $getoutSinceThereIsSomethingWrong + 1
	WEnd
	If $PAMPA_ERROR == False Then
		If $PAMPA_BROWSER <> -1 Then
			ProcessClose($PAMPA_BROWSER)
		EndIf
		$PAMPA_BROWSER = Run($browser, @ScriptDir, @SW_HIDE)
	EndIf
EndFunc

Func PAMPA_Jaxer() ;; create the string to launch the Jaxer manager and Jaxer itself reading directives from PAMPA/config/pampa.ini file and launch them
	Local $tempdir = IniRead($PAMPA_INI_FILE, 'Jaxer', 'tempdir', '')
	Local $configfile = IniRead($PAMPA_INI_FILE, 'Jaxer', 'configfile', '')
	Local $webport = IniRead($PAMPA_INI_FILE, 'Jaxer', 'webport', '')
	Local $commandport = IniRead($PAMPA_INI_FILE, 'Jaxer', 'commandport', '')
	Local $output = IniRead($PAMPA_INI_FILE, 'Jaxer', 'log_output', '')
	If $tempdir == '' Then
		$tempdir = $PAMPA_TMP
	EndIf
	If $configfile == '' Then
		$configfile = path($PAMPA_PATH & '\PAMPA\local_jaxer\conf\JaxerManager.cfg')
	EndIf
	If $webport == '' Then
		$webport = '4327'
	EndIf
	If $commandport == '' Then
		$commandport = '4328'
	EndIf
	If $output == '' Then
		$output = $PAMPA_TMP_PREFIX & 'jaxer.log'
	EndIf
	Local $JaxerManager = 'PAMPA\jaxer.32\JaxerManager '
	$JaxerManager &= '--configfile="' & $configfile & '" '
	$JaxerManager &= '--webport=' & $webport & ' '
	$JaxerManager &= '--commandport=' & $commandport & ' '
	$JaxerManager &= '--cfg:tempdir="' & $tempdir & '" '
	$JaxerManager &= '--log:output="' & $output & '" '
	If $PAMPA_DEBUG Then
		write('jaxer_manager.bat', 'start /B ' & $JaxerManager)
	EndIf
	Global $PAMPA_JAXER_MANAGER = Run($JaxerManager, @ScriptDir, @SW_HIDE)
EndFunc

Func PAMPA_MySQL() ;; create the string to launch MySQL reading directives from PAMPA/config/pampa.ini file and launch it
	Local $data = IniRead($PAMPA_INI_FILE, 'MySQL', 'data', '')
	Local $port = IniRead($PAMPA_INI_FILE, 'MySQL', 'port', '')
	Local $InnoDB = IniRead($PAMPA_INI_FILE, 'MySQL', 'InnoDB', '')
	If $data == '' Then
		$data = $PAMPA_PATH & '\PAMPA\data'
	EndIf
	If $port == '' Then
		$port = 3307
	EndIf
	If isTrue($InnoDB) Then
		$InnoDB = '--innodb'
	Else
		$InnoDB = '--skip-innodb --skip-innodb-doublewrite --skip-innodb-checksums --skip-innodb-adaptive-hash-index '
	EndIf
	Local $mysql = 'PAMPA\mysql.32\bin\mysqld.exe '
	$mysql &= '--defaults-file="' & $PAMPA_PATH & '\PAMPA\config\my.ini' & '" '
	$mysql &= '--basedir="' & $PAMPA_PATH & '\PAMPA\mysql.32" '
	$mysql &= '--datadir="' & $data & '" '
	$mysql &= '--log-error="' & $PAMPA_TMP_PREFIX & 'mysql.log" '
	$mysql &= '--pid-file="' & $PAMPA_TMP_PREFIX & 'mysql.pid" '
	$mysql &= '--port=' & $port & ' --standalone ' & $InnoDB
	If $PAMPA_DEBUG Then
		write('mysql.bat', 'start /B ' & $mysql)
	EndIf
	Global $PAMPA_MYSQL = Run($mysql, @ScriptDir, @SW_HIDE)
EndFunc



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PAMPA System Tray Application dedicated functions         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func PAMPA() ;; create the temporary folder and launch the application if AutoStart directive is True
	PAMPA_Globals()
	PAMPA_TrayCreate()
	If $PAMPA_AUTOSTART Then
		PAMPA_Start()
	Else
		PAMPA_TrayStatus("stop")
	EndIf
	PAMPA_Loop()
EndFunc

Func PAMPA_About() ;; show the popup with PAMPA project informations
	Local $msg
    Local $gui = GUICreate("PAMPA", 320, 260, -1, -1, $WS_POPUPWINDOW)
	Local $pic_top = GUICtrlCreatePic(@ScriptDir & "\PAMPA\images\PAMPA_TOP.bmp", 0, 0, 320, 46)
	Local $pic_left = GUICtrlCreatePic(@ScriptDir & "\PAMPA\images\PAMPA_SIDE.bmp", 0, 46, 4, 154)
	Local $pic_right = GUICtrlCreatePic(@ScriptDir & "\PAMPA\images\PAMPA_SIDE.bmp", 316, 46, 4, 154)
	Local $pic_bottom = GUICtrlCreatePic(@ScriptDir & "\PAMPA\images\PAMPA_BOTTOM.bmp", 0, 200, 320, 60)
	Local $tab = GUICtrlCreateTab(4, 46, 312, 154)
    Local $close = GUICtrlCreateButton("Close", 276, 46, 40, 20)
	Local $about = GUICtrlCreateTabItem("About")
	Local $about_text = GUICtrlCreateEdit(read(@ScriptDir & "\PAMPA\about.txt"), 5, 68, 309, 131, $ES_AUTOVSCROLL + $WS_VSCROLL)
	Local $credits = GUICtrlCreateTabItem("Credits")
	Local $credits_text = GUICtrlCreateEdit(read(@ScriptDir & "\PAMPA\credits.txt"), 5, 68, 309, 131, $ES_AUTOVSCROLL + $WS_VSCROLL)
	GUICtrlSetStyle($close, $BS_FLAT)
	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
		Select
			case $msg = 0
				ContinueLoop
			case $msg = $close Or $msg = $GUI_EVENT_CLOSE
				GUIDelete($gui)
				ExitLoop
		EndSelect
	WEnd
EndFunc

Func PAMPA_Error() ;; deprecated -- in this file for possible future reuse
	If @error <> 0 Then
		$PAMPA_ERROR = True
		TrayTip("Warning", "Something was wrong!", 3, 3)
	EndIf
EndFunc

Func PAMPA_Exit() ;; remove temporary flder and files if removeTemporaryFilesOnExit directive is True and kill the process itself plus its subprocesses
	Local $removeTemporaryFilesOnExit = IniRead($PAMPA_INI_FILE, 'PAMPA', 'removeTemporaryFilesOnExit', '')
	If isTrue($removeTemporaryFilesOnExit) Then
		DirRemove($PAMPA_TMP, 1)
	EndIf
	TraySetState(2)
	kill(@AutoItPID)
	Exit
EndFunc

Func PAMPA_Globals() ;; define global variables, with $PAMPA_ prefix, for the entire programm lifetime
	Global $PAMPA_ERROR = False
	Global $PAMPA_BROWSER = -1
	Global $PAMPA_PATH = path(@ScriptDir)
	Global $PAMPA_INI_FILE = $PAMPA_PATH & '\PAMPA\config\pampa.ini'
	If isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'useUserTemporaryFolder', '')) Then
		Global $TempDir = path(@TempDir)
		Global $PAMPA_TMP = $TempDir & "\PAMPA"
	Else
		Global $TempDir = path(@ScriptDir)
		Global $PAMPA_TMP = $TempDir & "\PAMPA\logs"
	EndIf
	Global $PAMPA_TMP_PREFIX = $PAMPA_TMP & '\' & @ScriptName & '.'
	Global $PAMPA_AUTOSTART = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'AutoStart', ''))
	Global $PAMPA_DEBUG = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'debug', ''))
	Global $PAMPA_LAUNCH_BROWSER = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'AutoLaunchBrowser', ''))
	Global $PAMPA_LAUNCH_JAXER = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'Jaxer', ''))
	Global $PAMPA_LAUNCH_MYSQL = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'MySQL', ''))
	Global $PAMPA_LAUNCH_PHP = isTrue(IniRead($PAMPA_INI_FILE, 'PAMPA', 'PHP', ''))
	Global $PAMPA_APACHE_DOCUMENT_ROOT = IniRead($PAMPA_INI_FILE, 'Apache', 'DocumentRoot', '')
	If $PAMPA_APACHE_DOCUMENT_ROOT == '' Then
		$PAMPA_APACHE_DOCUMENT_ROOT = $PAMPA_PATH & '\PAMPA\apache.32\htdocs'
	EndIf
EndFunc

Func PAMPA_Loop() ;; listen System Tray icon user actions, exit program on loop finished
	Local $str
	Local $i
	Local $length
	Local $msg
	While 1
		$msg = TrayGetMsg()
		Select
			Case $msg = 0
				ContinueLoop
			Case $msg = $PAMPA_MENU_DOCUMENT_ROOT
				Run('explorer "' & path($PAMPA_APACHE_DOCUMENT_ROOT) & '"', @ScriptDir, @SW_SHOW)
			Case $msg = $PAMPA_MENU_LOGS
				Run('explorer "' & $PAMPA_TMP & '"', @ScriptDir, @SW_SHOW)
			case $msg = $PAMPA_MENU_CONFIG
				Run('explorer "PAMPA\config"', @ScriptDir, @SW_SHOW)
			case $msg = $PAMPA_MENU_ABOUT
				PAMPA_About()
			Case $msg = $PAMPA_MENU_BROWSER
				PAMPA_Browser()
			Case $msg = $PAMPA_MENU_START
				PAMPA_Start()
			Case $msg = $PAMPA_MENU_RESTART
				PAMPA_Restart()
			Case $msg = $PAMPA_MENU_STOP
				PAMPA_Stop()
			Case $msg = $PAMPA_MENU_EXIT
				PAMPA_Stop()
				ExitLoop
			Case $msg <> 0
				$str = String($msg)
				$i = 0
				$length = UBound($PAMPA_CONFIG_FILES)
				While $i < $length
					If $str = $PAMPA_CONFIG_FILES[$i] Then
						$str = $PAMPA_CONFIG_FILES[$i + 1]
						If StringLower(StringMid($str, StringLen($str) - 3)) == ".lnk" Then
							ShellExecute($str)
						Else
							Run('Notepad "' & $str & '"', @ScriptDir, @SW_SHOW)
						EndIf
						$i = $length - 2
					EndIf
					$i += 2
				WEnd
		EndSelect
	WEnd
	PAMPA_Exit()
EndFunc

Func PAMPA_Restart() ;; stop running processes and start them again after a PAMPA_Sleep
	PAMPA_Stop()
	PAMPA_Sleep(200)
	PAMPA_Start()
EndFunc

Func PAMPA_Sleep($total) ;; flush 4 times the system tray icon for a spinning effect while the program is in pause (minimum 200 milliseconds)
	Local $partial = 0
	While 1
		TraySetIcon('PAMPA\images\PAMPA_90.ico', -1)
		Sleep(50)
		TraySetIcon('PAMPA\images\PAMPA_180.ico', -1)
		Sleep(50)
		TraySetIcon('PAMPA\images\PAMPA_270.ico', -1)
		Sleep(50)
		TraySetIcon('PAMPA\images\PAMPA_OFF.ico', -1)
		Sleep(50)
		$partial = $partial + 200
		If $partial > $total Then
			ExitLoop
		EndIf
	Wend
EndFunc

Func PAMPA_Start() ;; verify which third part software should be launched and launch them in order MySQL, Jaxer, Apache, Browser
	If FileExists($PAMPA_TMP) = False Then
		DirCreate($PAMPA_TMP)
	EndIf
	If $PAMPA_DEBUG Then
		write('dos.bat', 'cmd')
	EndIf
	If $PAMPA_LAUNCH_MYSQL Then
		PAMPA_MySQL()
	EndIf
	If $PAMPA_ERROR == False And $PAMPA_LAUNCH_JAXER Then
		PAMPA_Jaxer()
	EndIf
	If $PAMPA_ERROR == False Then
		PAMPA_Apache()
	EndIf
	If $PAMPA_ERROR == False And $PAMPA_LAUNCH_BROWSER Then
		PAMPA_Browser()
	EndIf
	If $PAMPA_ERROR == False Then
		PAMPA_TrayStatus("start")
	EndIf
	$PAMPA_AUTOSTART = True
EndFunc

Func PAMPA_Stop() ;; kill processes launched by PAMPA, if any. Remove dependencies from the launched browser (should not close it)
	If $PAMPA_LAUNCH_MYSQL And $PAMPA_AUTOSTART Then
		kill($PAMPA_MYSQL)
	EndIF
	If $PAMPA_LAUNCH_JAXER And $PAMPA_AUTOSTART Then
		kill($PAMPA_JAXER_MANAGER)
	EndIf
	If $PAMPA_AUTOSTART Then
		kill($PAMPA_APACHE)
	EndIf
	If $PAMPA_LAUNCH_BROWSER And $PAMPA_AUTOSTART Then
		ProcessClose($PAMPA_BROWSER)
	EndIf
	PAMPA_TrayStatus("stop")
EndFunc

Func PAMPA_TrayCreate() ;; create System Tray PAMPA Icon and its submenus statically or dynamically (PAMPA/config/*.*)
	                    ;; the PAMPA/config folder will be showed without directories but with links.
						;; every file that is not a link (.lnk) will be opened via Notepad.
						;; every .lnk file will be executed as link (so it is possible to add custom links/files)
	Global $PAMPA_MENU_START = TrayCreateItem("Start", -1)
	Global $PAMPA_MENU_RESTART = TrayCreateItem("Restart", -1)
	Global $PAMPA_MENU_STOP = TrayCreateItem("Stop", -1)
	TrayCreateItem("", -1)
	Global $PAMPA_MENU_DOCUMENT_ROOT = TrayCreateItem("Document Root", -1)
	Global $PAMPA_MENU_BROWSER = TrayCreateItem("Launch Browser", -1)
	TrayCreateItem("", -1)
	Local $view = TrayCreateMenu("View", -1)
	Local $list
	Local $file
	Local $folder = FileFindFirstFile($PAMPA_PATH & "\PAMPA\config\*.*")
	While $folder <> -1
		$file = FileFindNextFile($folder)
		If @error <> 0 Then
			FileClose($folder)
			ExitLoop
		Elseif $file = "." Or $file = ".." Or FileGetAttrib($PAMPA_PATH & "\PAMPA\config\" & $file) = "D" Then
			ContinueLoop
		Else
			$list &= "|" & TrayCreateItem($file, $view) & "|" & $PAMPA_PATH & "\PAMPA\config\" & $file
		EndIf
	WEnd
	$file = @WindowsDir & "\system32\drivers\etc\hosts"
	If FileExists($file) Then
		TrayCreateItem("", $view)
		$list &= "|" & TrayCreateItem("hosts", $view) & "|" & $file
	EndIf
	TrayCreateItem("", $view)
	Global $PAMPA_MENU_CONFIG = TrayCreateItem("Config Root", $view)
	Global $PAMPA_MENU_LOGS = TrayCreateItem("Logs Root", $view)
	Global $PAMPA_CONFIG_FILES = StringSplit(StringMid($list, 1), "|")
	TrayCreateItem("", $view)
	Global $PAMPA_MENU_ABOUT = TrayCreateItem("About PAMPA", $view)
	TrayCreateItem("", -1)
	Global $PAMPA_MENU_EXIT = TrayCreateItem("Exit", -1)
	PAMPA_TrayStatus("disable")
	TraySetState(1)
	TraySetToolTip("PAMPA 1.0")
EndFunc

Func PAMPA_TrayStatus($status) ;; set active/unactive items in the System Tray
	If $status == "disable" Then
		TrayItemSetState($PAMPA_MENU_START, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_RESTART, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_STOP, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_BROWSER, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_LOGS, $TRAY_DISABLE)
		TraySetIcon('PAMPA\images\PAMPA_OFF.ico', -1)
	ElseIf $status == "start" Then
		TrayItemSetState($PAMPA_MENU_START, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_RESTART, $TRAY_ENABLE)
		TrayItemSetState($PAMPA_MENU_STOP, $TRAY_ENABLE)
		TrayItemSetState($PAMPA_MENU_BROWSER, $TRAY_ENABLE)
		TrayItemSetState($PAMPA_MENU_LOGS, $TRAY_ENABLE)
		TraySetIcon('PAMPA\images\PAMPA_ON.ico', -1)
	ElseIf $status == "stop" Then
		TrayItemSetState($PAMPA_MENU_START, $TRAY_ENABLE)
		TrayItemSetState($PAMPA_MENU_RESTART, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_STOP, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_BROWSER, $TRAY_DISABLE)
		TrayItemSetState($PAMPA_MENU_LOGS, $TRAY_DISABLE)
		TraySetIcon('PAMPA\images\PAMPA_OFF.ico', -1)
	EndIf
EndFunc
