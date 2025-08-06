; OpenSPP NSIS Installer Script
; Based on Odoo installer structure

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"

;--------------------------------
; General

Name "OpenSPP {{VERSION}}"
OutFile "..\..\dist\openspp-{{VERSION}}-setup.exe"
InstallDir "$PROGRAMFILES64\OpenSPP"
InstallDirRegKey HKLM "Software\OpenSPP" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
ShowInstDetails show

;--------------------------------
; Variables

Var StartMenuFolder
Var PostgreSQLPath
Var PostgreSQLVersion
Var PostgreSQLUser
Var PostgreSQLPassword
Var PostgreSQLPort

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "openspp.ico"
!define MUI_UNICON "openspp.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "installer_left.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "installer_left.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "installer_top.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "installer_top.bmp"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY

; Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM" 
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\OpenSPP" 
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES

; Finish Page Configuration
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start OpenSPP Server"
!define MUI_FINISHPAGE_RUN_FUNCTION "StartOpenSPP"
!define MUI_FINISHPAGE_LINK "Visit OpenSPP Documentation"
!define MUI_FINISHPAGE_LINK_LOCATION "https://docs.openspp.org"
!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Version Information

VIProductVersion "{{VERSION}}.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "OpenSPP"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "OpenSPP Contributors"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "© OpenSPP Contributors"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "OpenSPP Installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "{{VERSION}}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "{{VERSION}}"

;--------------------------------
; Installer Sections

Section "OpenSPP Server" SecServer
    SectionIn RO
    
    SetOutPath "$INSTDIR"
    
    ; Copy Python files
    File /r "..\..\openspp\*.*"
    
    ; Copy configuration template
    File "openspp.conf.template"
    
    ; Copy service wrapper
    File "openspp-service.exe"
    
    ; Copy launcher scripts
    File "openspp-server.bat"
    File "openspp-shell.bat"
    
    ; Create configuration file
    FileOpen $0 "$INSTDIR\openspp.conf" w
    FileWrite $0 "[options]$\r$\n"
    FileWrite $0 "; Database configuration$\r$\n"
    FileWrite $0 "db_host = localhost$\r$\n"
    FileWrite $0 "db_port = 5432$\r$\n"
    FileWrite $0 "db_user = openspp$\r$\n"
    FileWrite $0 "db_password = openspp$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "; Paths$\r$\n"
    FileWrite $0 "addons_path = $INSTDIR\addons$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "; Server settings$\r$\n"
    FileWrite $0 "http_port = 8069$\r$\n"
    FileWrite $0 "longpolling_port = 8072$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "; Logging$\r$\n"
    FileWrite $0 "log_level = info$\r$\n"
    FileWrite $0 "log_file = $INSTDIR\openspp.log$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "; OpenSPP settings$\r$\n"
    FileWrite $0 "default_productivity_apps = True$\r$\n"
    FileClose $0
    
    ; Register service
    ExecWait '"$INSTDIR\openspp-service.exe" install'
    
    ; Write registry keys
    WriteRegStr HKLM "Software\OpenSPP" "InstallDir" "$INSTDIR"
    WriteRegStr HKLM "Software\OpenSPP" "Version" "{{VERSION}}"
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Register uninstaller
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "DisplayName" "OpenSPP {{VERSION}}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "DisplayIcon" "$INSTDIR\openspp.ico"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "Publisher" "OpenSPP Contributors"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "DisplayVersion" "{{VERSION}}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP" \
                     "URLInfoAbout" "https://openspp.org"
    
    ; Create shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
        CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\OpenSPP Server.lnk" \
                       "$INSTDIR\openspp-server.bat" "" "$INSTDIR\openspp.ico"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\OpenSPP Shell.lnk" \
                       "$INSTDIR\openspp-shell.bat" "" "$INSTDIR\openspp.ico"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\OpenSPP Configuration.lnk" \
                       "notepad.exe" "$INSTDIR\openspp.conf"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall OpenSPP.lnk" \
                       "$INSTDIR\Uninstall.exe"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\OpenSPP Web Interface.lnk" \
                       "http://localhost:8069"
    !insertmacro MUI_STARTMENU_WRITE_END
    
SectionEnd

Section "PostgreSQL 15" SecPostgreSQL
    ; Download and install PostgreSQL if not present
    IfFileExists "$PROGRAMFILES64\PostgreSQL\15\bin\postgres.exe" PostgreSQLExists PostgreSQLInstall
    
    PostgreSQLInstall:
        DetailPrint "Downloading PostgreSQL 15..."
        NSISdl::download "https://get.enterprisedb.com/postgresql/postgresql-15.5-1-windows-x64.exe" \
                        "$TEMP\postgresql-installer.exe"
        Pop $R0
        StrCmp $R0 "success" +2
            MessageBox MB_OK "PostgreSQL download failed. Please install manually."
            Goto PostgreSQLDone
        
        DetailPrint "Installing PostgreSQL 15..."
        ExecWait '"$TEMP\postgresql-installer.exe" --mode unattended --unattendedmodeui minimal \
                 --prefix "$PROGRAMFILES64\PostgreSQL\15" --datadir "$PROGRAMFILES64\PostgreSQL\15\data" \
                 --superpassword "postgres" --serverport 5432 --enable_acledit 1'
        Delete "$TEMP\postgresql-installer.exe"
        
        ; Create OpenSPP database user
        ExecWait '"$PROGRAMFILES64\PostgreSQL\15\bin\psql.exe" -U postgres -c \
                 "CREATE USER openspp WITH CREATEDB PASSWORD $\'openspp$\';"'
        
        Goto PostgreSQLDone
    
    PostgreSQLExists:
        DetailPrint "PostgreSQL 15 is already installed."
    
    PostgreSQLDone:
SectionEnd

Section "Python 3.11" SecPython
    ; Download and install Python if not present
    IfFileExists "$LOCALAPPDATA\Programs\Python\Python311\python.exe" PythonExists PythonInstall
    
    PythonInstall:
        DetailPrint "Downloading Python 3.11..."
        NSISdl::download "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe" \
                        "$TEMP\python-installer.exe"
        Pop $R0
        StrCmp $R0 "success" +2
            MessageBox MB_OK "Python download failed. Please install manually."
            Goto PythonDone
        
        DetailPrint "Installing Python 3.11..."
        ExecWait '"$TEMP\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1'
        Delete "$TEMP\python-installer.exe"
        
        ; Install required Python packages
        DetailPrint "Installing Python dependencies..."
        ExecWait '"$LOCALAPPDATA\Programs\Python\Python311\python.exe" -m pip install --upgrade pip'
        ExecWait '"$LOCALAPPDATA\Programs\Python\Python311\python.exe" -m pip install -r "$INSTDIR\requirements.txt"'
        
        Goto PythonDone
    
    PythonExists:
        DetailPrint "Python 3.11 is already installed."
    
    PythonDone:
SectionEnd

;--------------------------------
; Section Descriptions

LangString DESC_SecServer ${LANG_ENGLISH} "OpenSPP Server and modules (required)"
LangString DESC_SecPostgreSQL ${LANG_ENGLISH} "PostgreSQL 15 Database Server"
LangString DESC_SecPython ${LANG_ENGLISH} "Python 3.11 Runtime"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecServer} $(DESC_SecServer)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPostgreSQL} $(DESC_SecPostgreSQL)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPython} $(DESC_SecPython)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Functions

Function StartOpenSPP
    ExecShell "" "$INSTDIR\openspp-server.bat"
FunctionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"
    ; Stop and remove service
    ExecWait '"$INSTDIR\openspp-service.exe" stop'
    ExecWait '"$INSTDIR\openspp-service.exe" remove'
    
    ; Remove files
    RMDir /r "$INSTDIR"
    
    ; Remove shortcuts
    !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
    Delete "$SMPROGRAMS\$StartMenuFolder\*.lnk"
    RMDir "$SMPROGRAMS\$StartMenuFolder"
    
    ; Remove registry keys
    DeleteRegKey HKLM "Software\OpenSPP"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenSPP"
    
SectionEnd