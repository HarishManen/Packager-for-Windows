################################################################################
##OCSInventory Version NG 1.02 Production
##Copyleft Emmanuel GUILLORY 2008
##Web : http://ocsinventory.sourceforge.net
##
##This code is open source and may be copied and modified as long as the source
##code is always made freely available.
##Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################
;
;                             ###############
;                             #  CHANGELOG  #
;                             ###############
;
;
;
;4044
; Cleaning /upgrade when used
;4042
; New compressor method
;4040
; agent bug when no link to OCS server Patched
;4038
; On LAN card event inventory
;
;4035
; Do not uninstall service when upgrading, just stop service, and kill all processes
; Added /NOW command line switch to force inventory just after setup
; New argument parsing method
; Now produce a log file OcsAgentSetup.log
;
;4033
; win98 Sevice.ini bug
; win98 uninstall bug
;
;4031
; Added /nosplash
; Added stopservice and kill function before uninstall
; Added /upgrade (auto upgrade with deployment)
;
;4030
; added stopservice function before uninstall
;
;4027 win 9x service reboot issue patched
; ocsdat reading file option added
; Silent uninstall [/S] added
; Script partially generated by the HM NIS Edit Script Wizard.
setcompressor /SOLID lzma
; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "OCS Inventory Agent"
!define PRODUCT_VERSION "4.0.4.4"
!define PRODUCT_PUBLISHER "OCS Inventory NG Team"
!define PRODUCT_WEB_SITE "http://ocsinventory.sourceforge.net"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\OCSInventory.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!include "FileFunc.nsh"
!include "WordFunc.nsh"
;!insertmacro GetOptionsS
;!insertmacro GetOptions
!insertmacro GetTime
!insertmacro WordReplace

; MUI 1.67 compatible ------
!include "MUI.nsh"
ICON "aocs2.ico"
; MUI Settings
!define MUI_HEADERIMAGE
!define MUI_WELCOMEPAGE_TITLE_3LINES
;!define MUI_HEADERIMAGE_BITMAP "banner-ocs.bmp"
!define MUI_HEADERIMAGE_BITMAP "lOCS-ng-48.bmp" ; optional
;!define MUI_WELCOMEFINISHPAGE_BITMAP "lOCS-ng-48-2.bmp"

!define MUI_AbortWARNING
!define MUI_ICON "aocs2.ico"
!define MUI_UNICON "uocs2.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
!insertmacro MUI_PAGE_LICENSE "license.txt"
;!insertmacro MUI_PAGE_COMPONENTS

; Directory page
Page custom customOCSFloc ValidatecustomOCSFloc ""

!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"

; Registry values for checking service
!define WIN_9X_SERVICE_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices"
!define WIN_9X_SERVICE_VALUE "OCS Inventory NG"
!define WIN_NT_SERVICE_KEY "System\CurrentControlSet\Services\OCS INVENTORY"
!define WIN_NT_SERVICE_VALUE "ImagePath"

; Registry value to determine if Windows NT based
!define WIN_NT_KEY "SOFTWARE\Microsoft\Windows NT\CurrentVersion"
!define WIN_NT_VALUE "CurrentVersion"

; Setup log file
!define SETUP_LOG_FILE "$exedir\OcsAgentSetup.log"

; MUI end ------
  VIProductVersion "${PRODUCT_VERSION}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Setup OCS Inventory NG Agent for Windows as a service"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${PRODUCT_PUBLISHER}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "OcsServiceAgent is a part of OCS Inventory NG Application. Distributed under GNU GPL Licence."
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "${PRODUCT_PUBLISHER} ${PRODUCT_WEB_SITE}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "OCS Inventory NG Agent for Windows installed as a service"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${PRODUCT_VERSION}"

  BRANDINGTEXT "OCS Inventory NG"
  Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
  OutFile "OcsAgentSetup.exe"
  InstallDir "$PROGRAMFILES\OCS Inventory Agent"
  InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
  ShowUnInstDetails show

#####################################################################
# Global variables
#####################################################################
  var /GLOBAL OcsLogon_v ; To complete the setup log file
  var /GLOBAL OcsService ; To store if service was previously installed (TRUE) or not (FALSE)
  var /GLOBAL OcsNoSplash ; To store if setup must display spash screen (FALSE) or not (TRUE)
  var /GLOBAL OcsSilent ; To store if setup must be silent (TRUE) or not (FALSE)
  var /GLOBAL OcsUpgrade ; To store if /UPGRADE option used (TRUE) or not (FALSE)

#####################################################################
# GetParameters
# input, none
# output, top of stack (replaces, with e.g. whatever)
# modifies no other variables.
#####################################################################
Function GetParameters
  Push $R0
  Push $R1
  Push $R2
  Push $R3
  StrCpy $R2 1
  StrLen $R3 $CMDLINE
  ;Check for quote or space
  StrCpy $R0 $CMDLINE $R2
  StrCmp $R0 '"' 0 +3
  StrCpy $R1 '"'
  Goto loop
  StrCpy $R1 " "
loop:
  IntOp $R2 $R2 + 1
  StrCpy $R0 $CMDLINE 1 $R2
  StrCmp $R0 $R1 get
  StrCmp $R2 $R3 get
  Goto loop
get:
  IntOp $R2 $R2 + 1
  StrCpy $R0 $CMDLINE 1 $R2
  StrCmp $R0 " " get
  StrCpy $R0 $CMDLINE "" $R2
  Pop $R3
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

#####################################################################
# GetParameterValue
# Chris Morgan<cmorgan@alum.wpi.edu> 5/10/2004
# -Updated 4/7/2005 to add support for retrieving a command line switch
#  and additional documentation
#
# Searches the command line input, retrieved using GetParameters, for the
# value of an option given the option name.  If no option is found the
# default value is placed on the top of the stack upon function return.
#
# This function can also be used to detect the existence of just a
# command line switch like /OUTPUT  Pass the default and "/OUTPUT"
# on the stack like normal.  An empty return string "" will indicate
# that the switch was found, the default value indicates that
# neither a parameter or switch was found.
#
# Inputs - Top of stack is default if parameter isn't found,
#  second in stack is parameter to search for, ex. "/OUTPUT:"
# Outputs - Top of the stack contains the value of this parameter
#  So if the command line contained /OUTPUT:somedirectory, "somedirectory"
#  will be on the top of the stack when this function returns
#
# USAGE:
#  Push "/OUTPUT:"       ; push the search string onto the stack
#  Push "DefaultValue"   ; push a default value onto the stack
#  Call GetParameterValue
#  Pop $2
#  MessageBox MB_OK "Value of OUTPUT parameter is '$2'"
#####################################################################
Function GetParameterValue
  Exch $R0  ; get the top of the stack(default parameter) into R0
  Exch      ; exchange the top of the stack(default) with
            ; the second in the stack(parameter to search for)
  Exch $R1  ; get the top of the stack(search parameter) into $R1

  ;Preserve on the stack the registers used in this function
  Push $R2
  Push $R3
  Push $R4
  Push $R5

  Strlen $R2 $R1      ; store the length of the search string into R2

  Call GetParameters  ; get the command line parameters
  Pop $R3             ; store the command line string in R3

  # search for quoted search string
  StrCpy $R5 '"'      ; later on we want to search for a open quote
  Push $R3            ; push the 'search in' string onto the stack
  Push '"$R1'         ; push the 'search for'
  Call StrStr         ; search for the quoted parameter value
  Pop $R4
  StrCpy $R4 $R4 "" 1   ; skip over open quote character, "" means no maxlen
  StrCmp $R4 "" "" next ; if we didn't find an empty string go to next

  # search for non-quoted search string
  StrCpy $R5 ' '      ; later on we want to search for a space since we
                      ; didn't start with an open quote '"' we shouldn't
                      ; look for a close quote '"'
  Push $R3            ; push the command line back on the stack for searching
  Push '$R1'          ; search for the non-quoted search string
  Call StrStr
  Pop $R4

  ; $R4 now contains the parameter string starting at the search string,
  ; if it was found
next:
  StrCmp $R4 "" check_for_switch ; if we didn't find anything then look for
                                 ; usage as a command line switch
  # copy the value after $R1 by using StrCpy with an offset of $R2,
  # the length of 'OUTPUT'
  StrCpy $R0 $R4 "" $R2  ; copy commandline text beyond parameter into $R0
  # search for the next parameter so we can trim this extra text off
  Push $R0
  Push $R5            ; search for either the first space ' ', or the first
                      ; quote '"'
                      ; if we found '"/output' then we want to find the
                      ; ending ", as in '"/output=somevalue"'
                      ; if we found '/output' then we want to find the first
                      ; space after '/output=somevalue'
  Call StrStr         ; search for the next parameter
  Pop $R4
  StrCmp $R4 "" done  ; if 'somevalue' is missing, we are done
  StrLen $R4 $R4      ; get the length of 'somevalue' so we can copy this
                      ; text into our output buffer
  StrCpy $R0 $R0 -$R4 ; using the length of the string beyond the value,
                      ; copy only the value into $R0
  goto done           ; if we are in the parameter retrieval path skip over
                      ; the check for a command line switch

; See if the parameter was specified as a command line switch, like '/output'
check_for_switch:
  Push $R3            ; push the command line back on the stack for searching
  Push '$R1'         ; search for the non-quoted search string
  Call StrStr
  Pop $R4
  StrCmp $R4 "" done  ; if we didn't find anything then use the default
  StrCpy $R0 ""       ; otherwise copy in an empty string since we found the
                      ; parameter, just didn't find a value

done:
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Exch $R0 ; put the value in $R0 at the top of the stack
FunctionEnd

#####################################################################
# This function try to find a string in another one
# Case insensitive
#####################################################################
Function StrStr
  Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
loop:
  StrCpy $R5 $R2 $R3 $R4
  StrCmp $R5 $R1 done
  StrCmp $R5 "" done
  IntOp $R4 $R4 + 1
  Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd

#####################################################################
# This function try to find a string in another one, when uninstalling
# Case insensitive
#####################################################################
Function un.StrStr
  Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
loop:
  StrCpy $R5 $R2 $R3 $R4
  StrCmp $R5 $R1 done
  StrCmp $R5 "" done
  IntOp $R4 $R4 + 1
  Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd

#####################################################################
# This function parse command line arguments
#####################################################################
Function ParseCmd
  ; Save used registers
  Push $R0
  Push $R1
  ; Get command line paramaters
  Call GetParameters
  Pop $9
  ; Server address
  Push "/SERVER:"          ; push the search string onto the stack
  Push "ocsinventory-ng"   ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 3" "State" "$R0"
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/SERVER:$R0" "" "+" $R1
  StrCpy $9 $R1
  ; Server port
  Push "/PNUM:"          ; push the search string onto the stack
  Push "80"              ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 5" "State" "$R0"
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/PNUM:$R0" "" "+" $R1
  StrCpy $9 $R1
  ; No IE proxy
  Push "/NP"             ; push the search string onto the stack
  Push "1"               ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  StrCmp "$R0" "1" ParseCmd_IE_Proxy
  ; Disable IE proxy
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 6" "State" "1"
  Goto ParseCmd_Proxy_end
ParseCmd_IE_Proxy:
  ; Enable IE proxy
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 6" "State" "0"
ParseCmd_Proxy_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/NP" "" "+" $R1
  StrCpy $9 $R1
  ; Enable debug log
  Push "/DEBUG"             ; push the search string onto the stack
  Push "1"                  ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  StrCmp "$R0" "1" ParseCmd_Use_Debug
  ; Enable debug
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 7" "State" "1"
  Goto ParseCmd_Debug_end
ParseCmd_Use_Debug:
  ; Disable debug
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 7" "State" "0"
ParseCmd_Debug_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/DEBUG" "" "+" $R1
  StrCpy $9 $R1
  ; Launch immediate inventory
  Push "/NOW"             ; push the search string onto the stack
  Push "1"                ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  StrCmp "$R0" "1" ParseCmd_Launch_Now
  ; Do not launch
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 8" "State" "1"
  Goto ParseCmd_Launch_end
ParseCmd_Launch_Now:
  ; Launch now
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 8" "State" "0"
ParseCmd_Launch_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/NOW" "" "+" $R1
  StrCpy $9 $R1
  ; Silent install option
  Push "$9"
  Push "/S"
  Call StrStr
  Pop $R0
  StrCpy $R1 $R0 3
  StrCmp "$R1" "/S" ParseCmd_Silent
  StrCmp "$R1" "/S " ParseCmd_Silent
  ; Use silent setup
  StrCpy $OcsSilent "FALSE"
  Goto ParseCmd_Silent_end
ParseCmd_Silent:
  ; Use normal setup
  StrCpy $OcsSilent "TRUE"
ParseCmd_Silent_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/S" "" "+" $R1
  StrCpy $9 $R1
  ; No splash option
  Push "/NOSPLASH"        ; push the search string onto the stack
  Push "1"                ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  StrCmp "$R0" "1" ParseCmd_Splash
  ; Do not display spash screen
  StrCpy $OcsNoSplash "TRUE"
  Goto ParseCmd_Splash_end
ParseCmd_Splash:
  ; Display spash screen
  StrCpy $OcsNoSplash "FALSE"
ParseCmd_Splash_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/NOSPLASH" "" "+" $R1
  StrCpy $9 $R1
  ; /UPGRADE switch to set deployment status
  Push "/UPGRADE"         ; push the search string onto the stack
  Push "1"                ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  StrCmp "$R0" "1" ParseCmd_NoUpgrade
  ; Write deployement status file
  StrCpy $OcsUpgrade "TRUE"
  Goto ParseCmd_Upgrade_end
ParseCmd_NoUpgrade:
  ; Do not write deployement status file
  StrCpy $OcsUpgrade "FALSE"
ParseCmd_Upgrade_end:
  ; Remove parsed arg from command line
  ${WordReplace} "$9" "/NOSPLASH" "" "+" $R1
  StrCpy $9 $R1
  ${WordReplace} "$9" "/UPGRADE" "" "+" $R1
  StrCpy $9 $R1
  ; Miscellaneous options
  WriteINIStr "$PLUGINSDIR\options.ini" "Field 10" "State" "$9"
  ; Restore used registers
  Pop $R1
  Pop $R0
FunctionEnd

#####################################################################
# This function try to stop service when installing/upgrading
#####################################################################
Function StopService
   ; Save used register
   Push $R0
   ; Stop service
  nsExec::Exec 'net stop "OCS INVENTORY"'
  sleep 3000
  ; KillProcDLL �2003 by DITMan, based upon the KILL_PROC_BY_NAME function programmed by Ravi, reach him at: http://www.physiology.wisc.edu/ravi/
  ;* 0 = Process was successfully terminated
  ;* 603 = Process was not currently running
  ;* 604 = No permission to terminate process
  ;* 605 = Unable to load PSAPI.DLL
  ;* 602 = Unable to terminate process for some other reason
  ;* 606 = Unable to identify system type
  ;* 607 = Unsupported OS
  ;* 632 = Invalid process name
  ;* 700 = Unable to get procedure address from PSAPI.DLL
  ;* 701 = Unable to get process list, EnumProcesses failed
  ;* 702 = Unable to load KERNEL32.DLL
  ;* 703 = Unable to get procedure address from KERNEL32.DLL
  ;* 704 = CreateToolhelp32Snapshot failed
  KillProcDLL::KillProc "OCSInventory.exe"
  Pop $R0
  IntCmp $R0 603 0 StopService_download StopService_download
  StrCpy $R0 "0"
StopService_download:
  SetErrorLevel $R0
  KillProcDLL::KillProc "download.exe"
  Pop $R0
  IntCmp $R0 603 0 StopService_inst32 StopService_inst32
  StrCpy $R0 "0"
StopService_inst32:
  KillProcDLL::KillProc "inst32.exe"
  Pop $R0
  IntCmp $R0 603 0 StopService_OcsService StopService_OcsService
  StrCpy $R0 "0"
StopService_OcsService:
  KillProcDLL::KillProc "OcsService.exe"
  Pop $R0
  IntCmp $R0 603 0 StopService_end StopService_end
  StrCpy $R0 "0"
StopService_end:
  SetErrorLevel $R0
  ; Restore used register
  Pop $R0
FunctionEnd

#####################################################################
# This function try to stop service when uninstalling
#####################################################################
Function un.StopService
   ; Save used register
   Push $R0
   ; Stop service
   nsExec::Exec 'net stop "OCS INVENTORY"'
   sleep 3000
  ; KillProcDLL �2003 by DITMan, based upon the KILL_PROC_BY_NAME function programmed by Ravi, reach him at: http://www.physiology.wisc.edu/ravi/
  ;* 0 = Process was successfully terminated
  ;* 603 = Process was not currently running
  ;* 604 = No permission to terminate process
  ;* 605 = Unable to load PSAPI.DLL
  ;* 602 = Unable to terminate process for some other reason
  ;* 606 = Unable to identify system type
  ;* 607 = Unsupported OS
  ;* 632 = Invalid process name
  ;* 700 = Unable to get procedure address from PSAPI.DLL
  ;* 701 = Unable to get process list, EnumProcesses failed
  ;* 702 = Unable to load KERNEL32.DLL
  ;* 703 = Unable to get procedure address from KERNEL32.DLL
  ;* 704 = CreateToolhelp32Snapshot failed
  KillProcDLL::KillProc "OCSInventory.exe"
  Pop $R0
  IntCmp $R0 603 0 unStopService_download unStopService_download
  StrCpy $R0 "0"
unStopService_download:
  SetErrorLevel $R0
  KillProcDLL::KillProc "download.exe"
  Pop $R0
  IntCmp $R0 603 0 unStopService_inst32 unStopService_inst32
  StrCpy $R0 "0"
unStopService_inst32:
  KillProcDLL::KillProc "inst32.exe"
  Pop $R0
  IntCmp $R0 603 0 unStopService_OcsService unStopService_OcsService
  StrCpy $R0 "0"
unStopService_OcsService:
  KillProcDLL::KillProc "OcsService.exe"
  Pop $R0
  IntCmp $R0 603 0 unStopService_end unStopService_end
  StrCpy $R0 "0"
unStopService_end:
  SetErrorLevel $R0
  ; Restore used register
  Pop $R0
FunctionEnd

#####################################################################
# This function install service if needed, and start it
# Uses OcsService variable initialized in TestInstall function
#####################################################################
Function StartSvc
  ; Save used register
  Push $R0
 ; Is there any old install to convert ?
  StrCpy $R0 $WINDIR 2
  IfFileExists "$R0\ocs-ng\ocsconv.dat" StartSvc_NoConv
  IfFileExists "$R0\ocs-ng\ocsinventory.dat" 0 StartSvc_NoDat
  CopyFiles "$R0\ocs-ng\ocsinventory.dat" "$INSTDIR\ocsinventory.dat"
  Rename "$R0\ocs-ng\ocsinventory.dat" "$R0\ocs-ng\ocsconv.dat"
  Goto StartSvc_NoConv
StartSvc_NoDat:
  IfFileExists "$R0\ocs-ng\ocsinventory.conf" 0 StartSvc_NoConv
  CopyFiles "$R0\ocs-ng\ocsinventory.conf" "$INSTDIR\ocsinventory.conf"
  Rename "$R0\ocs-ng\ocsinventory.conf" "$R0\ocs-ng\ocsconv.dat"
StartSvc_NoConv:
  ; Verifying if not Windows NT
  ClearErrors
  ReadRegStr $R0 HKLM "${WIN_NT_KEY}" "${WIN_NT_VALUE}"
  IfErrors StartSvc_9x StartSvc_nt
StartSvc_9x:
  ; Install 9X service
  WriteRegStr HKLM "${WIN_9X_SERVICE_KEY}" "${WIN_9X_SERVICE_VALUE}" "$INSTDIR\ocsservice.exe -debug"
  ; Start 9X service
  Exec "$INSTDIR\ocsservice -debug"
  Goto StartSvc_end
StartSvc_nt:
  ; check if NT service was previously installed
  StrCmp "$OcsService" "TRUE" StartSvc_nt_skip_install 0
  ; NT service not installed, first install it
  ExecWait "$INSTDIR\ocsservice -install" $R0
StartSvc_nt_skip_install:
  ; Start NT service
  ExecWait "$INSTDIR\ocsservice -start" $R0
StartSvc_end:
  ; Read Launch [/now]
  ReadINIStr $R0 "$PLUGINSDIR\options.ini" "Field 8" "State"
  ; launch
  StrCmp "$R0" "1" ocsinventory_launch ocsinventory_launch_end
ocsinventory_launch:
  ReadINIStr $R0 "$INSTDIR\service.ini" "OCS_SERVICE" "Miscellaneous"
  ExecWait "$INSTDIR\ocsinventory.exe $R0 /force" $R0
ocsinventory_launch_end:
  ; Restore used register
  Pop $R0
FunctionEnd

#####################################################################
# This function try to find if logged in user has admin rights
#####################################################################
Function IsUserAdmin
  Push $R0
  Push $R1
  Push $R2
  ClearErrors
  UserInfo::GetName
  IfErrors IsUserAdmin_Win9x
  ; Assuming Windows NT
  Pop $R1
  UserInfo::GetAccountType
  Pop $R2
  StrCmp $R2 "Admin" 0 IsUserAdmin_Continue
; Observation: I get here when running Win98SE. (Lilla)
; The functions UserInfo.dll looks for are there on Win98 too,
; but just don't work. So UserInfo.dll, knowing that admin isn't required
; on Win98, returns admin anyway. (per kichik)
; MessageBox MB_OK 'User "$R1" is in the Administrators group'
  StrCpy $R0 "true"
  Goto IsUserAdmin_end
IsUserAdmin_Continue:
; You should still check for an empty string because the functions
; UserInfo.dll looks for may not be present on Windows 95. (per kichik)
  StrCmp $R2 "" IsUserAdmin_Win9x
  StrCpy $R0 "false"
;MessageBox MB_OK 'User "$R1" is in the "$R2" group'
  Goto IsUserAdmin_end
IsUserAdmin_Win9x:
; comment/message below is by UserInfo.nsi author:
; This one means you don't need to care about admin or
; not admin because Windows 9x doesn't either
;MessageBox MB_OK "Error! This DLL can't run under Windows 9x!"
  StrCpy $R0 "true"
IsUserAdmin_end:
 ;MessageBox MB_OK 'User= "$R1"  AccountType= "$R2"  IsUserAdmin= "$R0"'
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

#####################################################################
# This function checks if logged in user has admin rights and if
# service was previously installed
#####################################################################
Function TestInstall
  ; Save used register
  Push $R0
  ; Does service exist ?
  StrCpy $OcsLogon_v "Trying to determine if service was previously installed..."
  Call Write_Log
  ; Verifying if not Windows NT
  ClearErrors
  ReadRegStr $R0 HKLM "${WIN_NT_KEY}" "${WIN_NT_VALUE}"
  IfErrors TestInstall_9x TestInstall_winnt
TestInstall_winnt:
  ClearErrors
  ReadRegStr $R0 HKLM "${WIN_NT_SERVICE_KEY}" "${WIN_NT_SERVICE_VALUE}"
  IfErrors TestInstall_No_Service 0
  StrCpy $OcsService "TRUE"
  StrCpy $OcsLogon_v "Yes$\r$\n"
  Call Write_Log
  Goto TestInstall_end
TestInstall_9x:
  ClearErrors
  ReadRegStr $R0 HKLM "${WIN_9X_SERVICE_KEY}" "${WIN_9X_SERVICE_VALUE}"
  IfErrors TestInstall_No_Service 0
  StrCpy $OcsService "TRUE"
  StrCpy $OcsLogon_v "Yes$\r$\n"
  Call Write_Log
  Goto TestInstall_end
TestInstall_No_Service:
  StrCpy $OcsService "FALSE"
  StrCpy $OcsLogon_v "No$\r$\n"
  Call Write_Log
TestInstall_end:
; If yes, stop it and kill processes
  StrCpy $OcsLogon_v "Trying to stop service and kill processes..."
  Call Write_Log
  Call StopService
  StrCpy $OcsLogon_v "OK$\r$\n"
  Call Write_Log
  ; Restore used register
  Pop $R0
FunctionEnd

#####################################################################
# This function write service initialisation file
#####################################################################
Function WriteServiceIni
  ; Save used registers
  Push $R0
  Push $R1
  ; Read Miscellaneous
  ReadINIStr $R0 "$PLUGINSDIR\options.ini" "Field 10" "State"
  ; Read server address
  ReadINIStr $R1 "$PLUGINSDIR\options.ini" "Field 3" "State"
  ; Write server address
  WriteINIStr "$INSTDIR\service.ini" "OCS_SERVICE" "Server" "$R1"
  StrCpy $R0 "$R0 /SERVER:$R1"
  ; Read server port
  ReadINIStr $R1 "$PLUGINSDIR\options.ini" "Field 5" "State"
  ; Write server port
  WriteINIStr "$INSTDIR\service.ini" "OCS_SERVICE" "Pnum" "$R1"
  StrCpy $R0 "$R0 /PNUM:$R1"
  ; Read IE proxy
  ReadINIStr $R1 "$PLUGINSDIR\options.ini" "Field 6" "State"
  ; Write IE proxy
  WriteINIStr "$INSTDIR\service.ini" "OCS_SERVICE" "NoProxy" "$R1"
  StrCmp "$R1" "1" WriteServiceIni_no_proxy WriteServiceIni_proxy_end
WriteServiceIni_no_proxy:
  StrCpy $R0 "$R0 /NP"
WriteServiceIni_proxy_end:
  ; Read Debug
  ReadINIStr $R1 "$PLUGINSDIR\options.ini" "Field 7" "State"
  ; Write debug
  StrCmp "$R1" "1" WriteServiceIni_debug WriteServiceIni_debug_end
WriteServiceIni_debug:
  StrCpy $R0 "$R0 /DEBUG"
WriteServiceIni_debug_end:
  ; Write miscellaneous
  WriteINIStr "$INSTDIR\service.ini" "OCS_SERVICE" "Miscellaneous" "$R0"
  Sleep 1000
  ; Restore used register
  Pop $R1
  Pop $R0
FunctionEnd

#####################################################################
# This function write content of OcsLogon_v variable in log file in
# a log file OcsAgentSetup.log located in install directory
#####################################################################
Function Write_Log
  ; Save used register
  Push $R0
  ClearErrors
  ; Is there something to write ?
  StrCmp $OcsLogon_v "" WriteLog_end
  ; Open log file
  FileOpen $R0 ${SETUP_LOG_FILE} a
  ; Seek to end
  FileSeek $R0 END END
  IfErrors WriteLog_end
  ; Write
  FileWrite $R0 "$OcsLogon_v"
  StrCpy $OcsLogon_v ""
  ; Close file
  FileClose $R0
WriteLog_end:
  ; Restore used register
  Pop $R0
FunctionEnd

#####################################################################
# This function checks if no multiple setup launched, if setup
# launched as silent and without spash screen
#####################################################################
Function .onInit
  ; Init debug log
  Delete ${SETUP_LOG_FILE}
  StrCpy $OcsLogon_v "********************************************************$\r$\n"
  Call Write_Log
  ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
  StrCpy $OcsLogon_v "Starting ${PRODUCT_NAME} ${PRODUCT_VERSION} setup on $0/$1/$2 at $4:$5:$6$\r$\n"
  Call Write_Log
  StrCpy $OcsLogon_v "Checking if setup not already running..."
  Call Write_Log
  InitPluginsDir
  File /oname=$PLUGINSDIR\options.ini "options.ini"
  File /oname=$PLUGINSDIR\splash.bmp "banner-ocs.bmp"
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "OcsSetupNG") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 not_running
  StrCpy $OcsLogon_v "Yes$\r$\nABORT: Setup already running !"
  Call Write_Log
  Abort
not_running:
  FileOpen $9 "ocsdat" r
  FileRead $9 "$2"
  FileClose $9
  StrCmp $9 "" +2 0
  StrCpy $CMDLINE '"$PLUGINSDIR\" $2'
  StrCpy $OcsLogon_v "OK.$\r$\nCommand line is: $CMDLINE$\r$\n"
  Call Write_Log
  StrCpy $OcsLogon_v "Parsing command line arguments..."
  Call Write_Log
  Call ParseCmd
  StrCpy $OcsLogon_v "OK$\r$\n"
  Call Write_Log
  ; Checking if Silent mode enabled
  StrCpy $OcsLogon_v "Checking for silent mode..."
  Call Write_Log
  StrCmp "$OcsSilent" "TRUE" Enable_silent
  ; Disable_silent mode
  StrCpy $OcsLogon_v "Disabled.$\r$\n"
  Call Write_Log
  SetSilent normal
  Goto Check_no_splash
Enable_silent:
  StrCpy $OcsLogon_v "Enabled.$\r$\n"
  Call Write_Log
  SetSilent silent
  Goto Check_no_splash
Check_no_splash:
  ; Checking if /nosplash option
  StrCpy $OcsLogon_v "Checking for splash screen..."
  Call Write_Log
  StrCmp "$OcsNoSplash" "TRUE" Disable_splash
  ; Enable splash screen
  StrCpy $OcsLogon_v "Enabled.$\r$\n"
  Call Write_Log
  advsplash::show 900 160 840 0xFFFFF $PLUGINSDIR\splash
  Goto Check_User
Disable_splash:
  ; Splash disabled
  StrCpy $OcsLogon_v "Disabled.$\r$\n"
  Call Write_Log
Check_User:
; Detect is user has admin right
  StrCpy $OcsLogon_v "Checking if logged in user has Administrator privileges..."
  Call Write_Log
  Call IsUserAdmin
  Pop "$R0"
  StrCmp $R0 "true" Okadmin 0
  IfSilent 0 +2
    messagebox MB_ICONSTOP "Your are not logged on with Administrator privileges.$\r$\nYou cannot setup ${PRODUCT_NAME} as a Windows Service!"
  StrCpy $OcsLogon_v "NO$\r$\nABORT: unable to install Agent as a service without Administrator privileges !$\r$\n"
  Call Write_Log
  Abort
Okadmin:
  StrCpy $OcsLogon_v "OK$\r$\n"
  Call Write_Log
FunctionEnd

#####################################################################
# This function ask user for agent options
#####################################################################
Function customOCSFloc
  !insertmacro MUI_HEADER_TEXT "OCS Inventory NG Agent For Windows Options" "____________________"
  InstallOptions::dialog "$PLUGINSDIR\options.ini"
FunctionEnd

Function ValidatecustomOCSFloc
;call iniModif
FunctionEnd


#####################################################################
# This section copy files service, install and start service
#####################################################################
Section "OCS Inventory Agent" SEC01
  ; Test previous install
  Call TestInstall
  ; Copy files
  StrCpy $OcsLogon_v "Copying new files to directory <$INSTDIR>..."
  Call Write_Log
  SetOutPath "$INSTDIR"
  SetOverwrite on
  File "..\_Release\BIOSINFO.EXE"
  File "..\_Release\download.exe"
  File "..\_Release\inst32.exe"
  File "..\_Release\libeay32.dll"
  File "..\_Release\mfc42.dll"
  File "..\_Release\OCSInventory.exe"
  File "..\_Release\OcsService.dll"
  File "..\_Release\OcsService.exe"
  File "..\_Release\OcsWmi.dll"
  File "..\_Release\ssleay32.dll"
  File "..\_Release\SysInfo.dll"
  File "..\_Release\PSAPI.DLL"
  File "..\_Release\zlib.dll"
  ; Create service configuration file
  StrCpy $OcsLogon_v "OK$\r$\nUpdating service configuration..."
  Call Write_Log
  Call WriteServiceIni
  ; Install service
  StrCpy $OcsLogon_v "OK$\r$\nTrying to install and/or start service..."
  Call Write_Log
  call StartSvc
  StrCpy $OcsLogon_v "OK$\r$\n"
  Call Write_Log
SectionEnd


#####################################################################
# This section writes uninstall into Windows
#####################################################################
Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\OCSInventory.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\OCSInventory.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  ; write auth_user and auth_pwd to prevent warning event
  WriteINIStr "$INSTDIR\uninst.exe" "OCS_SERVICE"  "auth_user" ""
  WriteINIStr "$INSTDIR\uninst.exe" "OCS_SERVICE"  "auth_pwd" ""
  ; Write deployement status file if required
  StrCmp "$OcsUpgrade" "TRUE" 0 Post_end
  ; WRITE ../done
  SetOutPath "$exedir"
  FileOpen $1 "..\done" w
  FileWrite $1 "SUCCESS"
  FileClose $1
Post_end:
SectionEnd

#####################################################################
# This function writes install status into log file when sucessfull install
#####################################################################
Function .onInstSuccess
  StrCpy $OcsLogon_v "SUCESS: ${PRODUCT_NAME} ${PRODUCT_VERSION} successfuly installed ;-)$\r$\n"
  Call Write_Log
FunctionEnd

#####################################################################
# This function writes install status into log file when install failed
#####################################################################
Function .onInstFailed
  StrCpy $OcsLogon_v "ABORT: installation of ${PRODUCT_NAME} ${PRODUCT_VERSION} failed :-($\r$\n"
  Call Write_Log
FunctionEnd


#####################################################################
# This function ask uninstall confirmation, if not launched with
# silent argument /S
#####################################################################
Function un.onInit
  Push "$CMDLINE"
  Push " /S"
  Call un.StrStr
  Pop $R9
  StrLen $0 $R9
  IntCmp $0 2 unOnInit_silent 0 unOnInit_silent
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure to unistall $(^Name)?" IDYES +2
  Abort
unOnInit_silent:
FunctionEnd

#####################################################################
# This section stop service, uninstall service and remove files
#####################################################################
Section Uninstall
  call un.StopService
  ; Verifying if not Windows NT
  ClearErrors
  ReadRegStr $R0 HKLM "${WIN_NT_KEY}" "${WIN_NT_VALUE}"
  IfErrors Uninstall_9x Uninstall_nt
Uninstall_nt:
  ; Uninstall NT service
  ExecWait "$INSTDIR\ocsservice.exe -uninstall" $R0
  Goto Uninstall_files
Uninstall_9x:
  ; Uninstall 9X service
  DeleteRegValue HKLM "${WIN_9X_SERVICE_KEY}" "${WIN_9X_SERVICE_VALUE}"
Uninstall_files:
  ; Remove files
  Delete /REBOOTOK "$INSTDIR\uninst.exe"
  Delete /REBOOTOK "$INSTDIR\zlib.dll"
  Delete /REBOOTOK "$INSTDIR\SysInfo.dll"
  Delete /REBOOTOK "$INSTDIR\ssleay32.dll"
  Delete /REBOOTOK "$INSTDIR\OcsWmi.dll"
  Delete /REBOOTOK "$INSTDIR\OcsService.exe"
  Delete /REBOOTOK "$INSTDIR\OcsService.dll"
  Delete /REBOOTOK "$INSTDIR\OCSInventory.exe"
  Delete /REBOOTOK "$INSTDIR\mfc42.dll"
  Delete /REBOOTOK "$INSTDIR\libeay32.dll"
  Delete /REBOOTOK "$INSTDIR\inst32.exe"
  Delete /REBOOTOK "$INSTDIR\download.exe"
  Delete /REBOOTOK "$INSTDIR\BIOSINFO.EXE"
  Delete /REBOOTOK "$INSTDIR\PSAPI.DLL"
  ; Remove directory
  ; RMDir /r "$INSTDIR"
  ; Remove registry key
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

#####################################################################
# This function ask to restart computer when uninstalling, if not
# launched with silent argument /S
#####################################################################
Function un.onUninstSuccess
  HideWindow
  Push "$CMDLINE"
  Push " /S"
  Call un.StrStr
  Pop $R9
  StrLen $0 $R9
  IntCmp $0 2 unOnUninstSuccess_silent 0 unOnUninstSuccess_silent
  MessageBox MB_OK|MB_ICONEXCLAMATION "${PRODUCT_NAME} ${PRODUCT_VERSION} was successfully uninstalled.$\r$\nUnder Windows NT 4.0, restart of your computer is needed to complete uninstall process."
unOnUninstSuccess_silent:
FunctionEnd
