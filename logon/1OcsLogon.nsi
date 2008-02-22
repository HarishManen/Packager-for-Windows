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
;4042
; new compress method
;4040
; new service testing
; new parse method
;4035
; /folder: bug patched
; Win9x Deploy service bug patched
; /url: bug patched
; Added /editlog
;4032
;4031
;NO HARDCODED /DEBUG OPTION
; right in c:\ocs-ng folder issue patched
;4027
; /folder popup issue patched
; Added /UNINSTALL
; Added /URL:[url]
; Added /install (so try downloading OcsPackage.exe) ---> Fait
; no longer label download-------------------------------------> Fait
;4026
; Added /folder: ---------------------------------------------> Fait
; /RegRun option eventually ----------------------------------> Reported
; Added /
; Replaced "NSISdl::download" by "NSISdl::download_quiet" ----> Fait
;4004-4014
; Normal roadmapped improvments
;
;###############################################################################
setcompressor /SOLID lzma
!include "MUI.nsh"
;!include "WinMessages.nsh"
!insertmacro MUI_LANGUAGE "english"
!define OCSserver "ocsinventory-ng"
!define TimeOut "600000"
!define Compile_version "4.0.4.2"
!define hard_option "" ; i.e. "/debug /deploy:4040 /install /url:http://MyOCSserverFQDNorIP/deploy/"
 var url
 var version
 var OcsLogon_v ; to complete the debug option
 var http_port_number ;it means what it says
 var /GLOBAL AgentExeName
# /debug = debug option
# /np = No proxy use
# /pnum:[POTR NUMBER] = http port number (only for the deploy)
# /local = Local .ocs export
# /deploy:[VERSION NUMBER] force to deploy at least this version
# /tag:[Value or !systemvarable] force tag taking defined value

BRANDINGTEXT "OCS Inventory NG ${Compile_version}"
Icon "ocs.ico"
;ShowInstDetails hide
Name "OcsLogon"
OutFile "OcsLogon.exe"
;$R7 became the install folder
SilentInstall silent
; Page instfiles
Page custom customOCSFloc ValidatecustomOCSFloc ""
page instfiles
;--------------------------------
;Version Information
  VIProductVersion "${Compile_version}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "OcsLogon"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Logon script for OCS Inventory"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Ocs Inventory ng Team"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "OcsLogon is a part of ocs Inventory NG Application. Under GNU Licence."
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "OCS Inventory Team http://ocsinventory.sourceforge.net"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "OcsLogon.exe"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${Compile_version}"
;--------------------------------

Function Write_Log
  ClearErrors
  Push "$CMDLINE"
  Push " /debug"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  ;messagebox mb_ok $0
  intcmp $0 6 +2 0 +2
  goto done
  strcmp $OcsLogon_v "" done 0
  FileOpen $0 "$R7\OcsLogon.log" a
  FileSeek $0 END END
  IfErrors done
  FileWrite $0 "$OcsLogon_v"
  strcpy $OcsLogon_v ""
  FileClose $0
done:
FunctionEnd

Function .onInit
  InitPluginsDir
  File /oname=$PLUGINSDIR\OCSFloc.ini "OCSFloc.ini"
  strcpy $CMDLINE "$CMDLINE ${hard_option}"
; Prevent Multiple Instances
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "OcsLogonNG") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 not_running
  strcpy $OcsLogon_v "OcsLogon.exe is already running!$\r$\n"
  call Write_Log
  Abort
not_running:
; :url option here!
  Push "/url:"
  Push ""   ; push a default value onto the stack
  Call GetParameterValue
  Pop $R0
  strcpy $URL $R0
; VRIFYING IF NOT NT
; ClearErrors
; ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
; IfErrors 0 lbl_winnt
; writeregstr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OCS Inventory NG" "$cmdline"
; lbl_winnt:
  call test-folder
  SetOutPath "$R7"
  delete "$R7\OcsLogon.log"
  StrCpy $R8 ${OCSserver}
  ; test exe Name
  ; if exeName <> OcsLogon.exe then OCSserver variable = exeName
  System::Call 'kernel32::GetModuleFileNameA(i 0, t .R0, i 1024) i r1'
  ;$R0 will contain the installer filename
  pop $R0
  Strlen $0 $exedir
  intop $0 $0 + 1
  StrCpy $R0 $R0 -4 $0 ; $RO is the exeName without "\" and ".exe"
  strcmp "OcsLogon" $R0 no_server_change 0
  StrCpy $R8 $R0
no_server_change:
  strcmp "ocslocal" $R0  0 no_add_local_option
  StrCpy $cmdline '$cmdline /local'
no_add_local_option:

 ;****************************************
 ; Force deploying version number option ;*
 ;****************************************
  Push "/deploy:"
  Push ""   ;push a default value onto the stack
  Call GetParameterValue
  Pop $R9
 ; be shure only numbers...
  intop $R9 $R9 + 0
  strcpy $version $R9
 ;****************************
 ;  Port Number option ;*
 ;****************************
  Push "/pnum:"
  Push "80"   ;push a default value onto the stack
  Call GetParameterValue
  Pop $R9
  intop $R9 $R9 + 0
  strcpy $OcsLogon_v  "$OcsLogon_vCmd Line: $CMDLINE $\r$\n"
  strcpy $http_port_number $R9
  strcpy $OcsLogon_v  "$OcsLogon_vOCS server port number: $R9"

 ;*******************************
 ;     Build the url string
 ;*******************************
  strcpy $OcsLogon_v  "$OcsLogon_v$\r$\n"
  strcmp $url "" 0 c_url
  strcpy $url "http://$R8:$http_port_number/ocsinventory/deploy/"
  goto d_url
c_url:
  strcpy $OcsLogon_v  "$OcsLogon_v URL used : $url$\r$\n"
d_url:

 ;***************************************************************************
 ;      write install folder, server and version in log if /debug
 ;***************************************************************************
  call Write_Log
  strcpy $OcsLogon_v "Deploy folder : $R7$\r$\n"
  call Write_Log
  strcpy $OcsLogon_v "OCSserver is set to:  $R8$\r$\n"
  call Write_Log
  strcpy $OcsLogon_v "Internal Ocslogon version: ${Compile_version}$\r$\n"
  call Write_Log
  ;**********************
  ;  UNINSTALL option   ;*
  ;**********************
  Push "$CMDLINE"
  Push " /UNinstall"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 10 0 noUNinstall_requested 0
  strcpy $OcsLogon_v "$OcsLogon_vUNinstall Requested.$\r$\n"
  call UNinstall
  ABORT
noUNinstall_requested:

  ;**********************
  ;  Install option     ;*
  ;**********************
  call test_install
  ;**********************
  ;  No proxy option   ;*
  ;**********************
  Push "$CMDLINE"
  Push " /np"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 3 0 proxy_use 0
  StrCpy $OcsLogon_v "$OcsLogon_v No proxy use.$\r$\n"
  goto proxy_end
proxy_use:
  StrCpy $OcsLogon_v "$OcsLogon_v Proxy use.$\r$\n"
proxy_end:
 call Write_Log
 Push "$CMDLINE"
  Push " /local"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 6 local_ok 0 local_ok
  call test_installed_service
;*************************
;  BUG WITH /LOCAL not the right place for the 2 folowing lines
;  call test_install
;  SetOutPath "$R7"
; ***********************
  Push "$CMDLINE"
  Push "/"
  Call StrStr
  Pop $1
  call Write_Log
  strcpy $OcsLogon_v "Launching : $R7\OCSInventory.exe $1 /server:$R8$\r$\n"
  call Write_Log
  Exec "$R7\OCSInventory.exe $1 /server:$R8"
local_ok:
  call Write_Log
  strcpy $OcsLogon_v "Cmdline option is :$cmdline$\r$\n$OcsLogon_v $\r$\n"
  call Write_Log
  ClearErrors
FunctionEnd

function test_installed_service
 ; Si /install ok
 ;tESTER SI LE service est ok, si oui, on quitte
 ;messagebox mb_ok "test_installed_service"
  strcpy $OcsLogon_v "$OcsLogon_vTesting Service...$\r$\n"
  services::GetServiceNameFromDisplayName 'OCS INVENTORY'
  Pop $R0
  ;ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Services\OCS INVENTORY" "start"
  strcmp $R0 "1" 0 lbl_test98
  strcpy $OcsLogon_v "$OcsLogon_vService is installed.$\r$\n" ;"Exiting OcsLogon.$\r$\n"
  services::IsServiceRunning 'OCS INVENTORY'
  Pop $R0
  strcpy $OcsLogon_v "$OcsLogon_vIs Service Running : $R0$\r$\n" ;"Exiting OcsLogon.$\r$\n"
  strcmp $R0 "Yes" normal_ending 0
  ;WriteRegDword HKLM "SYSTEM\CurrentControlSet\Services\OCS INVENTORY" "start" "2"
  ;WriteRegDword HKLM "SYSTEM\ControlSet001\Services\OCS INVENTORY" "start" "2"
  services::SendServiceCommand 'start' 'OCS INVENTORY'
  Pop $R0
  strcpy $OcsLogon_v "$OcsLogon_vTry start service : $R0$\r$\n"
  strcmp $R0 "Ok" normal_ending 0
  strcpy $OcsLogon_v "$OcsLogon_vERROR WITH service : $R0$\r$\n PLEASE CHECK CONFIGURATION...$\r$\n"
normal_ending:
  strcpy $OcsLogon_v "$OcsLogon_vExiting OcsLogon.$\r$\n"
  call Write_Log
  call showlog
abort
lbl_test98:
  ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices" "OCS Inventory NG"
  strlen $0 $R0
  ;messagebox mb_ok "cl� =$0 --- $R0"
  intcmp $0 21 lbl_fintestservice lbl_fintestservice 0
  strcpy $OcsLogon_v "$OcsLogon_vService installed on Widows 9x.$\r$\nExiting OcsLogon.$\r$\n"
  call Write_Log
  call showlog
abort

lbl_fintestservice:
 strcpy $OcsLogon_v "$OcsLogon_vService missing "
 call Write_Log
FunctionEnd

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

Function donwnload
  pop $1
  pop $2
  NSISdl::download_quiet /TIMEOUT=600000 "$2" "$1.new"
  pop $0
  strcmp $0 "success" 0 snorm
  delete "$1"
  rename "$1.new" "$1"
 snorm:
  strcpy $OcsLogon_v "$OcsLogon_v$2 : $0$\r$\n"
FunctionEnd

Function donwnloadnp
  pop $1
  pop $2
  NSISdl::download_quiet /TIMEOUT=600000 /NOIEPROXY "$2" "$1.new"
  pop $0
  strcmp $0 "success" 0 snormnp
  delete "$1"
  rename "$1.new" "$1"
snormnp:
  strcpy $OcsLogon_v "$OcsLogon_v$2 : $0$\r$\n"
FunctionEnd


Function UNinstall
  strcpy $1 "ocsuninstall.exe"
  Push "$CMDLINE"
  Push " /np"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 3 0 Udownload_withProxy 0
  push "$url$1"
  push "$R7\ocsuninstall.exe"
  call donwnloadnp
  goto Udownload_end
Udownload_withProxy:
  push "$url$1"
  push "$R7\ocsuninstall.exe"
  call donwnload
Udownload_end:
  call Write_Log
  execwait "$R7\ocsuninstall.exe"
FunctionEnd

Function install
; messagebox mb_ok "Install!"
  call Write_Log
  strcpy $OcsLogon_v "Ocs Inventory NG ($version) was not previously installed.$\r$\nStart deploying OCS$\r$\n"
  call Write_Log
  SetOutPath "$R7"
;:::::::::::/install option
  Push "$CMDLINE"
  Push " /install"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 8 0 set_install 0
  strcpy $AgentExeName "ocspackage.exe"
  goto telech
  set_install:
  strcpy $AgentExeName "ocsagent.exe"
telech:
; messagebox mb_ok $R9
;:::::::::::::::::::::::: End /install option
  Push "$CMDLINE"
  Push " /np"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 3 0 download_withProxy 0
  push "$url$AgentExeName"
  push "$R7\ocsagent.exe"
  call donwnloadnp
  ; push "http://$R8$http_port_number/ocsinventory/deploy/label"
  ;push "$R7\label"
  ;call donwnloadnp
  goto download_end
download_withProxy:
  push "$url$AgentExeName"
  push "$R7\ocsagent.exe"
  call donwnload
 ; push "http://$R8$http_port_number/ocsinventory/deploy/label"
 ; push "$R7\label"
 ; call donwnload
download_end:
;::::::::::::::::::::::::::::::::::::*

  ;strcpy $R6 "$R6$\r$\n$OcsLogon_v"
  ;*****************************************************************
  ;       install success if verbose option (/debug) ;*
  ;*****************************************************************
  call Write_Log
  strcpy $OcsLogon_v "End Deploying$\r$\n"
  call Write_Log
  ClearErrors
  ; SetShellVarContext all
  ; createdirectory "$SMPROGRAMS\ocs-ng"
  ; CreateShortCut "$SMPROGRAMS\OCS-NG\OCS-NG.lnk" "$PROGRAMFILES\ocs-ng\OcsLogon.exe" "/local" '' 0 SW_SHOWNORMAL ALT|CONTROL|i "Lancement de OCS-NG en local."
  SetShellVarContext current
  ; SetShellVarContext all
  ; createdirectory "$SMPROGRAMS\ocs-ng"
  ; CreateShortCut "$R7 local.lnk" "$R7\OcsLogon.exe" "/local" '' 0 SW_SHOWNORMAL ALT|CONTROL|i "Lancement de OCS-NG en local."
FunctionEnd

Function test-folder
 ; *************************************
 ;  if /local do not calculate exedir  *
 ; *************************************
  Push "$CMDLINE"
  Push " /local"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  intcmp $0 6 0 no_local 0
  strcpy $R7 $exedir
goto suite
no_local:
 ; *****************************
 ;  giving the good directory  *
 ; *****************************
  strcpy $R7 $WINDIR 2
  strcpy $R7 "$R7\ocs-ng"
  Push "/folder:"
  Push ""   ;push a default value onto the stack
  Call GetParameterValue
  Pop $R9
;  testing /folder: option
  intcmp $0 3 folder_use 0 folder_use
  goto folder_end
folder_use:
  delete $R7 ; Just if it is a file ;)
  createdirectory "$R7"
  goto suite
folder_end:
  ; end testing /folder option
  ; test deploy foldr
  delete $R7 ; Just if it is a file ;)
  createdirectory "$R7"
  FileOpen $1 "$R7\file.dat" w
  FileWrite $1 "OCS_NG"
  Fileclose $1
  FileOpen $0 "$R7\file.dat" r
  FileRead $0 $1
 ; Tested the entered vallue
  FileClose $0
  strcmp $1 "OCS_NG"  0    PB
 ; Writing OK so $R7 = c:\ocs-ng
  SetFileAttributes "$R7\file.dat" NORMAL
  delete "$R7\file.dat"
;  goto suite
;PB: ; Can not Write so giving $R7 the user temp value
  IfFileExists "$R7\ocsagent.exe" 0 et1
  delete "$R7\ocsagent.new"
  IfFileExists "$R7\ocsagent.new" PB 0
  rename "$R7\ocsagent.exe" "$R7\ocsagent.old"
  IfFileExists "$R7\ocsagent.old" 0 PB
  delete "$R7\ocsagent.old"
et1:
  IfFileExists "$R7\ocsinventory.exe" 0 suite
  rename "$R7\ocsinventory.exe" "$R7\ocsinventory.old"
  IfFileExists "$R7\ocsinventory.old" 0 PB
  IfFileExists "$R7\ocsinventory.exe" PB 0
  rename "$R7\ocsinventory.old" "$R7\ocsinventory.exe"
  goto suite
PB:
  strcpy $R7 "$TEMP"
  ;messagebox mb_ok $R7
  createdirectory "$R7\ocs-ng"
  strcpy $R7 "$R7\ocs-ng"
  FileOpen $1 "$R7\file.dat" w
  FileWrite $1 "OCS_NG"
  Fileclose $1
  FileOpen $0 "$R7\file.dat" r
  FileRead $0 $1
  ; Tested the entered vallue
  ; messagebox mb_ok 3--$1
  FileClose  $0
  strcmp $1 "OCS_NG"  PASPBt PBt
PASPBt:  ; Can Write so temp user
  ;messagebox mb_ok "$1  ok sur temp"
  delete "$R7\file.dat"
  goto suite
PBt: ; Can not Write so exit and try to alert server
 ; messagebox mb_ok "$R8"
  NSISdl::download_quiet /TIMEOUT=600000 /NOIEPROXY "http://$R8$http_port_number/ocsinventory/deploy/nodeploy" "$R7\nodeploy"
  abort
suite:
FunctionEnd

Function test_install
  ; Test all files.
  ; if one is missing then dowload all
push $R7
; VRIFYING IF NOT NT
   ClearErrors
   ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
   IfErrors 0 lbl_winnt
;  NOT NT SO WIN9X
   ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices" "OCS Inventory NG"
   strlen $1 $0
   ;messagebox mb_ok "longueur cl� runservices :$1 $0"
   intop $1 $1 - 22
   strcpy $0 $0 $1 0
   ;messagebox mb_ok "reste $0"
   strcmp $0 "" normalop 0
   strcpy $OcsLogon_v  "$OcsLogon_v Service Win9x is installed on: $0$\r$\n"
   strcpy $R7 $0
   ;messagebox MB_ok "$OcsLogon_v Service Win9x is installed on: $0$\r$\n"
   goto normalop
;/////////////////////////////////////////////////
lbl_winnt:
   ClearErrors
   ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Services\OCS INVENTORY" "imagepath"
   strlen $1 $0
   intop $1 $1 - 17
   strcpy $0 $0 $1 1
   ;messagebox MB_ok $0
   strcmp $0 "" normalop 0
   strcpy $OcsLogon_v  "$OcsLogon_v Service is installed on: $0$\r$\n"
   strcpy $R7 $0
normalop:
   strcmp $0 "" 0 normalop1
   Push "$CMDLINE"
   Push " /install"
   Call StrStr
   Pop $R9
  ;messagebox mb_ok x$R9
   Strlen $0 $R9
  ;messagebox mb_ok $0
   intcmp $0 8 set_install normalop1 set_install
normalop1:
   strcpy $OcsLogon_v  "$OcsLogon_vTesting: $R7\BIOSINFO.EXE$\r$\n"
   IfFileExists "$R7\BIOSINFO.EXE" 0 set_install
   strcpy $OcsLogon_v  "$OcsLogon_vTesting: $R7\OCSInventory.exe$\r$\n"
   IfFileExists "$R7\OCSInventory.exe" 0 set_install
   strcpy $OcsLogon_v  "$OcsLogon_vTesting: $R7\OcsWmi.dll$\r$\n"
   IfFileExists "$R7\OcsWmi.dll" 0 set_install
   strcpy $OcsLogon_v  "$OcsLogon_vTesting: $R7\SysInfo.dll$\r$\n"
   IfFileExists "$R7\SysInfo.dll" 0 set_install
    strcpy $OcsLogon_v  "$OcsLogon_vTesting: $R7\MFC42.DLL$\r$\n"
   IfFileExists "$R7\MFC42.DLL" 0 set_install
   ; veriying potenial corrupted dll
   GetDllVersion "$R7\MFC42.DLL" $R0 $R1
   IntOp $R2 $R0 / 0x00010000
   IntOp $R3 $R0 & 0x0000FFFF
   IntOp $R4 $R1 / 0x00010000
   IntOp $R5 $R1 & 0x0000FFFF
   StrCpy $0 "$R2$R3$R4$R5"
   strcpy $OcsLogon_v  "$OcsLogon_vTesting MFC42.DLL version ($0)$\r$\n"
   strcmp "$R0$R1" "" set_install 0
   GetDllVersion "$R7\OCSInventory.exe" $R0 $R1
   IntOp $R2 $R0 / 0x00010000
   IntOp $R3 $R0 & 0x0000FFFF
   IntOp $R4 $R1 / 0x00010000
   IntOp $R5 $R1 & 0x0000FFFF
   StrCpy $0 "$R2$R3$R4$R5"
   strcpy $OcsLogon_v  "$OcsLogon_vTesting OCSInventory.exe version ($0)$\r$\n"
   intcmp  $0 $version no_install  set_install  no_install
set_install:
   pop $R7
   push $r7
   call install
   GetDllVersion "$R7\ocsagent.exe" $R0 $R1
   IntOp $R2 $R0 / 0x00010000
   IntOp $R3 $R0 & 0x0000FFFF
   IntOp $R4 $R1 / 0x00010000
   IntOp $R5 $R1 & 0x0000FFFF
   StrCpy $0 "$R2$R3$R4$R5"
   strcmp $0 "0000" err_download No_err_download
err_download:
   strcpy $OcsLogon_v  "$OcsLogon_vTesting ocsagent.exe version:$0$\r$\n"
   strcpy $OcsLogon_v  "$OcsLogon_vERROR downloading agent on: $url$AgentExeName  $\r$\nPlease check this URL.$\r$\n"
   call Write_Log
   call Showlog
   abort
No_err_download:
   strcpy $OcsLogon_v  "$OcsLogon_vTesting ocsagent.exe version:$0$\r$\n"
   Push "$CMDLINE"
   Push "/"
   Call StrStr
   Pop $1
   call Write_Log
   strcpy $OcsLogon_v "Launching : $R7\ocsagent.exe $1$\r$\n"
   call Write_Log
   ExecWAIT "$R7\ocsagent.exe $1"
   ; strcpy $OcsLogon_v "$OcsLogon_vResult: $2$\r$\n"
   ;call Write_Log
   ;*****************************
   ;:::::::::::/install option
   ;***************************
   Push "$CMDLINE"
   Push " /install"
   Call StrStr
   Pop $R9
   Strlen $0 $R9
   intcmp $0 8 0 NOlaunchinstaller 0
  ;exec "$R7\ocsagent.exe"
  ; strcpy $OcsLogon_v "$OcsLogon_vStarting OCS Installer: $R7\ocsagent.exe$\r$\n"
  ;*********************
  ; TEST install pending
  ;********************
  strcpy $R9 "1"
start_install:
  intcmp $R9 120 OcsSetupNG_Failed 0
  sleep 900
  call test_installed_service
  IntOp $R9 $R9 + 1
  strcpy $OcsLogon_v  "$OcsLogon_v Install pending $R9$\r$\n"
 ; messagebox mb_ok $R0
  strcmp $R0 "2" 0 start_install
 ;messagebox mb_ok "Must never arrive here!"
OcsSetupNG_Failed:
  strcpy $OcsLogon_v  "$OcsLogon_v Failed to install Service. Try Classic process...$\r$\n"
  call write_log
; end test install pending

nolaunchinstaller:
  goto no_install
  Execwait "$R7\ocsagent.exe $1"
no_install:
  ClearErrors
pop $R7
FunctionEnd

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



Function customOCSFloc
   ;****************************************************
   ;          popup to export the .ocs file           ;*
   ; ***************************************************
 Push "$CMDLINE"
 Push " /local"
 Call StrStr
 Pop $R9
 ;strcmp " /local" $R9 local_ok 0
 Strlen $0 $R9
 ;messagebox mb_ok $0
 intcmp $0 6 0 customOCSFloc_endprocess 0
   !insertmacro MUI_HEADER_TEXT "Local inventory" "Inventory target:"
 InstallOptions::dialog "$PLUGINSDIR\OCSFloc.ini"
 customOCSFloc_endprocess:
FunctionEnd

Function ValidatecustomOCSFloc
  ; destination choice and control
   ReadINIStr $R0 "$PLUGINSDIR\OCSFloc.ini" "Field 2" "State"
   StrCmp $R0 "" 0 ValidatecustomOCSFloc_done
   MessageBox MB_ICONEXCLAMATION "Select a target directory."
   abort
ValidatecustomOCSFloc_done:
   ;****************************************************
   ;          destination  test                       ;*
   ;        Verify if string R0 has got 2 "\"         ;*
   Strlen $0 $R0                                      ;*
   intcmp $0 3 0 0 +2                                 ;*
   StrCpy $R0 $R0 2                                   ;*
   ; Si oui en supprimer un                           ;*
   ;****************************************************
   FileOpen $1 "$R0\file.dat" w
   FileWrite $1 "OK$\r$\n"
   Fileclose $1
;MessageBox MB_ICONEXCLAMATION "$R0\file.dat"
   IfFileExists "$R0\file.dat" ValidatecustomOCSFloc_ok ValidatecustomOCSFloc_err
ValidatecustomOCSFloc_err:
   MessageBox MB_iconstop "Target directory not writable!"
   abort
ValidatecustomOCSFloc_ok:
   delete "$R0\file.dat"
   ;*************************
   ;* For local option only *
   ;*************************
   ;messagebox mb_iconexclamation "EXPORT ..."
   # read  DESTINATION in the ini file
   ReadINIStr $R0 "$PLUGINSDIR\OCSFloc.ini" "Field 2" "State"
   Strlen $0 $R0
   intcmp $0 3 0 0 +2
   StrCpy $R0 $R0 2
   SetOutPath "$R7"
   delete "$R7\*.ocs"
   Push "$CMDLINE"
   Push "/"
   Call StrStr
   Pop $1
   Execwait "$R7\OCSInventory.exe $1"
   ClearErrors
   CopyFiles "*.ocs" "$R0\"
   IfErrors bad_copy good_copy
bad_copy:
   MessageBox MB_iconexclamation "Error writing output file on:$\r$\n$R0"
   abort
good_copy:
   MessageBox MB_OK "Inventory export on :$\r$\n$R0$\r$\ndone."
FunctionEnd

Section
   hidewindow
   setautoclose true
SectionEnd

function showlog
  Push $CMDLINE
  Push "/editlog"
  Call StrStr
  Pop $R9
  Strlen $0 $R9
  ;MESSAGEBOX MB_ok "$0 edit OK :$R9"
  intcmp $0 8 editlog 0 editlog
  goto editlogend
editlog:
  Execshell open "$R7\ocslogon.log"
editlogend:
;***************FIN
functionend

Section -Post
  call showlog
SectionEnd