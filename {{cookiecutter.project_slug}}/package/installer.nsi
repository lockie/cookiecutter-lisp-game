!include MUI2.nsh

!define MUI_PRODUCT "{{cookiecutter.project_name |
  reject('in', ('<', '>', ':', '"', '/', '\\', '|', '?', '*')) | join('')}}"
!define MUI_FILE "{{cookiecutter.project_slug}}"
!define MUI_VERSION $%VERSION%
!define MUI_ABORTWARNING
!define MUI_ICON "$%TEMP%\icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "$%TEMP%\icon.bmp"
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_UNBITMAP "$%TEMP%\icon.bmp"

Name "{{cookiecutter.project_name}}"
OutFile "../{{cookiecutter.project_slug}}-${MUI_VERSION}-setup.exe"

;Default installation folder
InstallDir "$LOCALAPPDATA\Programs\${MUI_PRODUCT}"

;Get installation folder from registry if available
InstallDirRegKey HKCU "Software\${MUI_PRODUCT}" ""

;Do not request application privileges for Windows Vista+
RequestExecutionLevel user

;Check CRC
CRCCheck On

;Best compression
SetCompressor /FINAL /SOLID lzma

;Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ../LICENSE
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"


;Installer section
Section ""
    SetOutPath "$INSTDIR"

    ;Files
    File /r "..\bin"
    File /r "..\Resources"
    File "${MUI_ICON}"

    SetOutPath "$INSTDIR\bin"

    ;Create desktop shortcut
    CreateShortCut "$DESKTOP\${MUI_PRODUCT}.lnk" "$INSTDIR\bin\${MUI_FILE}.exe" "" "$INSTDIR\icon.ico" 0

    ;Create start menu items
    CreateDirectory "$SMPROGRAMS\${MUI_PRODUCT}"
    CreateShortCut "$SMPROGRAMS\${MUI_PRODUCT}\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
    CreateShortCut "$SMPROGRAMS\${MUI_PRODUCT}\${MUI_PRODUCT}.lnk" "$INSTDIR\bin\${MUI_FILE}.exe" "" "$INSTDIR\icon.ico" 0

    ;Store installation folder
    WriteRegStr HKCU "Software\${MUI_PRODUCT}" "" $INSTDIR

    ;Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd


;Uninstaller section
Section "Uninstall"
    ;Delete Files
    RMDir /r "$INSTDIR\*.*"
    Delete "$INSTDIR\Uninstall.exe"

    ;Remove the installation directory
    RMDir "$INSTDIR"

    ;Delete Shortcuts
    Delete "$DESKTOP\${MUI_PRODUCT}.lnk"
    Delete "$SMPROGRAMS\${MUI_PRODUCT}\*.*"
    RMDir  "$SMPROGRAMS\${MUI_PRODUCT}"

    DeleteRegKey /ifempty HKCU "Software\${MUI_PRODUCT}"
SectionEnd
