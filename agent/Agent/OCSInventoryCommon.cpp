// Document modified at : Tuesday, May 25, 2004 10:57:54 PM , by user : Didier LIROULET , from computer : SNOOPY-XP-PRO

//====================================================================================
// Open Computer and Software Inventory
// Copyleft Didier LIROULET 2003
// MODIFIED BY PIERRE LEMMET 2005
// Web: http://ocsinventory.sourceforge.net
// E-mail: ocsinventory@tiscali.fr

// This code is open source and may be copied and modified as long as the source
// code is always made freely available.
// Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
//====================================================================================

//  OCSInventory.cpp : Defines the class behaviors for the application.
//

#include "StdAfx.h"
#include "Resource.h"		// main symbols
#include "SysInfo.h"
#include "StoreInteract.h"
#include "XMLInteract.h"
#include "OCSInventory.h"
#include "afxinet.h"
#include "zlib\flate.h"
#include "utils.h"

//#include <winver.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// COCSInventoryApp

BEGIN_MESSAGE_MAP(COCSInventoryApp, CWinApp)
	//{{AFX_MSG_MAP(COCSInventoryApp)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG
	ON_COMMAND(ID_HELP, CWinApp::OnHelp)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// COCSInventoryApp construction

COCSInventoryApp::COCSInventoryApp()
{
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance
	m_pTheDB = NULL;
}

/////////////////////////////////////////////////////////////////////////////
// The one and only COCSInventoryApp object

COCSInventoryApp theApp;

/////////////////////////////////////////////////////////////////////////////
// COCSInventoryApp initialization

UINT threadWork( LPVOID pParam ) {

	UINT* pDep = ((UINT*)(pParam));								
	HRESULT hr;
	ULONG IpCur;
	ULONG ulLen=6;
	ULONG pulMac[2];
	in_addr ipa;
	CString csSent;
	BOOL	baliseIp = FALSE;
	COCSInventoryApp* pA = (COCSInventoryApp*)AfxGetApp();
	CMarkup * pXml = & pA->m_markupOCS;
	ULONG NetNumber = pA->m_netNumber;

	memset (pulMac, 0xff, sizeof (pulMac));
	IpCur = *pDep + NetNumber ;							
	//ARP sent to IpCur
	hr = pA->lpfn_SendARP(pA->lpfn_ntohl(IpCur), 0, pulMac, &ulLen) ;

	if( ulLen > 0 && hr == NO_ERROR && ulLen==6) {
		size_t i, j;
		char * szMac = new char[ulLen*3];
		PBYTE pbHexMac = (PBYTE) pulMac;
		
		// Convert the binary MAC address into human-readable
		for (i = 0, j = 0; i < ulLen - 1; ++i) {
			j += sprintf (szMac + j, "%02X:", pbHexMac[i]);
		}			

		sprintf (szMac + j, "%02X", pbHexMac[i]);

		ipa.S_un.S_addr = pA->lpfn_htonl(IpCur);
		csSent = pA->lpfn_inet_ntoa(ipa);		
		
		pA->m_cs.Lock();
		pA->m_hostFound++;
		pXml->AddElem("H");
		pXml->AddChildElem("I",csSent);
		pXml->AddChildElem("M",szMac);
		AddLog( _T( "\tIPDISCOVER: Computer found: IP:%s MAC:%s\n"),csSent,szMac);
		pA->m_cs.Unlock();		
		delete [] szMac;
	}
	delete pDep;
	return 0;
}


BOOL COCSInventoryApp::InitInstance()
{
	/*****
	 *
	 *	Checks wether another instance of ocsinventory.exe is 
	 *	already running.
	 *
	 ****/
    bool AlreadyRunning;

    HANDLE hMutexOneInstance = ::CreateMutex( NULL, TRUE,
	 _T("OCSINVENTORY-088FA840-B10D-11D3-BC36-006067709674"));

    AlreadyRunning = (GetLastError() == ERROR_ALREADY_EXISTS);

    if (hMutexOneInstance != NULL) {
        ::ReleaseMutex(hMutexOneInstance);
    }

    if ( AlreadyRunning ) {
	    return FALSE; // terminates the application
	}

	/*****
	 *
	 *	Main initinstance block 
	 *
	 ****/		
	try
	{
		AfxEnableControlContainer();

		// Standard initialization
		// If you are not using these features and wish to reduce the size
		//  of your final executable, you should remove from the following
		//  the specific initialization routines you do not need.

#ifdef _AFXDLL
		Enable3dControls();			// Call this when using MFC in a shared DLL
#else
		Enable3dControlsStatic();	// Call this when linking to MFC statically
#endif
		TCHAR				szExecutionFolder[_MAX_PATH+1],	// Local execution folder
							szDeviceName[MAX_COMPUTERNAME_LENGTH + 1]; // Local Device netbios name
		ULONG				ulBufferLength;	// Buffer length
		UINT				uIndex;			// Index
		CTime				cStartTime;		// Start time of the inventory check
		CTime				cEndTime;		// End time of the inventory check
		CString				csMessage;		// User message
		CString				csUserName = NOT_AVAILABLE;	// Logged on user name
		CSoftware			cFile;
		CString				csServer;		
		BOOL				bServerUp = TRUE;
		CMarkup				xmlResp;
		CMarkup*			pXml = NULL;
		CString				csUserAgent;
		CHttpConnection*	pConnect = NULL;
		CMarkup				myMarkup;
		CString				csAgentVer;
		BOOL				bInventoryNeeded = FALSE;
		SysInfo*			pSysInfo = NULL;
		int					iProxy = INTERNET_OPEN_TYPE_PRECONFIG;	
		INTERNET_PORT		iPort = DEFAULT_PORT;
		CString				csMacs;
		CString				csDid;
		CString				csActualMac;
		BOOL				bOldFlag = FALSE;
		
		cStartTime = CTime::GetCurrentTime();
		CString cmdL = this->m_lpCmdLine;				
		
		/******************/		
		// Get application path
		if (GetModuleFileName( AfxGetInstanceHandle(), szExecutionFolder, _MAX_PATH) == 0)
		{
			//AfxMessageBox( IDS_ERROR_INIT_FAILED, MB_ICONSTOP);
			return FALSE;
		}
		// Get the Device netbios Name
		ulBufferLength = MAX_COMPUTERNAME_LENGTH+1;
		if (!GetComputerName( szDeviceName, &ulBufferLength))
		{
			//AfxMessageBox( IDS_ERROR_INIT_FAILED, MB_ICONSTOP);
			return FALSE;
		}
		//strcpy(szDeviceName, "TEST03");
		m_ThePC.SetDeviceName(szDeviceName);
		
		// Construct the execution folder
		for (uIndex = strlen( szExecutionFolder); (uIndex >= 0) && (szExecutionFolder[uIndex] != '\\') && (szExecutionFolder[uIndex] != ':'); uIndex --)
			szExecutionFolder[uIndex] = 0;
		// Open log file if needed
		csMessage.Format( _T( "%s%s"), szExecutionFolder, szDeviceName);
		OpenLog( csMessage,cmdL );

		/*****
		 *
		 *	Gets agent version
		 *
		 ****/
		csAgentVer=CUtils::getVersion();
		if(csAgentVer=="") {
			AddLog( _T("ERROR: NO agent version read. 1 assumed.\n"));
			csAgentVer="1";
		}
		
		/*****
		 *
		 *	Log file header
		 *
		 ****/
		if(CUtils::IsRequired(cmdL,"debug"))
		{
			m_ThePC.SetLastCheckDate( cStartTime.Format( _T( "%Y-%m-%d")));
			csMessage.Format( _T("\nOCS INVENTORY ver. %s "),csAgentVer);
			AddLog( csMessage);
			AddLog( _T( " Starting session for Device <%s> on %s...\nCommand line parameters: <<%s>>\n\n"),
							   szDeviceName,
							   cStartTime.Format( _T( "%#c")),
							   cmdL);	
		}

		/*****
		 *
		 *	Shows the tag requesting dialog, only if the "notag" option was not provided
		 *
		 ****/
		if(!CUtils::IsRequired(cmdL,"notag") && ! CUtils::IsRequired(cmdL,"test"))
		{
			CFile labelFile, adminFile;
			BOOL labelOpened = FALSE;
			BOOL adminOpened = FALSE;

			if( labelFile.Open(LABEL_FILE,CFile::modeRead) ) {
				labelOpened = TRUE;
				labelFile.Close();
			}

			if( adminFile.Open(OCS_ACCOUNTINFO_FILE,CFile::modeRead) ) {
				adminOpened = TRUE;
				adminFile.Close();
			}
			
			if( labelOpened && !adminOpened) {
				CString labelText = CUtils::readParamFile("tagDialog");
				if( labelText.GetLength()>0 ) {
					CInputDlg d;
					d.DoModal();
				/*	int valCu=atoi(d.m_ValV); TODO: contraintes
					char fin[50];
					itoa(valCu,fin,10);*/
					CUtils::writeParamFile("TAG",CString(d.m_ValV),FALSE,1);
				}
			}

		}

		if( ! CUtils::IsRequired(cmdL,"test") ) {

			/*****
			 *
			 *	Deviceid checkings and renewal if needed
			 *
			 ****/
			CString csDeviceID, csFileDeviceID, csFileMac, csFileHname;			
			//	WMI Connection
			pSysInfo=new SysInfo();
			//check deviceid

			CUtils::getMacDeviceid(csDeviceID, csFileMac, cmdL);
			csActualMac = CUtils::getMacs(pSysInfo, m_ThePC);
			csFileHname = csDeviceID.Left(csDeviceID.GetLength()-20);
			csFileDeviceID = csDeviceID;

			// No .dat file
			UINT oldAgentVer = atoi(CUtils::readParamFile("Agent").GetBuffer(0));
			if( csDeviceID.GetLength() < 1 && oldAgentVer < 4006 && oldAgentVer != 0 ) {
				// try to read old .conf file
				csDeviceID = CUtils::readParamFile("deviceid");
				AddLog("DID_CHECK: Old agent (ver %u), reading from ocsinventory.conf <%s> found\n", oldAgentVer, csDeviceID);
				try {
					// remove it
					CFile::Remove(OCS_IDENTIFICATION_FILE);
					AddLog("DID_CHECK: File %s deleted\n", OCS_IDENTIFICATION_FILE);					
				}
				catch( CException * pE) {
					pE->Delete();
				}
				try {
					// remove it
					CFile::Remove(VERSION_FILE);
					AddLog("DID_CHECK: File %s deleted\n", VERSION_FILE);					
				}
				catch( CException * pE) {
					pE->Delete();
				}
			}
			else if( CUtils::IsRequired(cmdL,"uid")) 
				csDeviceID.Empty();
			else if(csActualMac != csFileMac && szDeviceName != csFileHname) {
				csDeviceID.Empty();
				AddLog("DID_CHECK: Mac changed new:<%s> old:<%s>, hname changed new:<%s> old:<%s>\n", 
					csActualMac, csFileMac, szDeviceName, csFileHname ); 
			}
			else if( csActualMac != csFileMac || szDeviceName != csFileHname ) {
				bOldFlag = TRUE;
				csDeviceID.Empty();
				if( csActualMac != csFileMac )				
					AddLog("DID_CHECK: Mac changed new:<%s> old:<%s>\n",csActualMac, csFileMac);
				else
					AddLog("DID_CHECK: hname changed new:<%s> old:<%s>\n", szDeviceName, csFileHname);
			}

			if (csDeviceID.IsEmpty()) {
				// This is the first time we inventory the device => generate a new device unique ID
				m_ThePC.GenerateUID();				
			}
			else
				// Device already m_SetDeviceID
				m_ThePC.SetDeviceID( csDeviceID );	

			if( ! bOldFlag )
				CUtils::writeMacDeviceid( m_ThePC.GetDeviceID(), csActualMac, cmdL);

			/*****
			 *
			 *	XML beginning generation
			 *
			 ****/	
			pXml=&((((COCSInventoryApp*)AfxGetApp())->m_markupOCS));
			pXml->SetDoc(XML_HEADERS);
			pXml->AddElem("REQUEST");
			pXml->IntoElem();
			pXml->AddElem("QUERY","INVENTORY");
			pXml->AddElem("CONTENT");
			pXml->IntoElem();
			pXml->AddElemNV("DEVICEID",m_ThePC.GetDeviceID());
		if( bOldFlag )
				pXml->AddElemNV("OLD_DEVICEID",csFileDeviceID);

			pXml->AddElemNV("VERSIONCLIENT",CUtils::getVersion());
		}

		/*****
		 *
		 *	Looking for server name
		 *
		 ****/
		if( ! CUtils::IsRequired(cmdL,"local") ) {
			csServer=CUtils::getParamValue(cmdL,"server");	
			
			if( csServer.GetLength()==0 || csServer=="" ) {
				// Pas de serveur pass� en parametre
				csServer=DEFAULT_SERVER_NAME;
			}
		}

		/*****
		 *
		 *	Network dialog initialization
		 *
		 ****/		
		if( CUtils::IsRequired( cmdL, "np" ) ) {
				iProxy = INTERNET_OPEN_TYPE_DIRECT;
				AddLog( _T( "HTTP SERVER: Connection WITHOUT proxy\n"));
		}

		if( ! CUtils::IsRequired(cmdL,"local") &&  ! CUtils::IsRequired(cmdL,"test") ) {		
			AddLog( _T( "HTTP SERVER: Creating CInternetSession to get inventory parameters..."));
			csUserAgent.Format("%s_windows_client_v%s",USER_AGENT,csAgentVer);			
			AddLog( _T( "OK.\n"));

			iPort = CUtils::getPort( cmdL );
						
			CInternetSession sess(csUserAgent, 1, iProxy);			
			CString reponse,contentS;		
			
			AddLog( _T( "HTTP SERVER: Connecting to server %s port %i..."), csServer, iPort);
			try {				
				pConnect = sess.GetHttpConnection(csServer, iPort);
				AddLog( _T( "OK.\n"));
				myMarkup.SetDoc(XML_HEADERS);
				myMarkup.AddElem("REQUEST");
				myMarkup.IntoElem();
				myMarkup.AddElem("QUERY","PROLOG");
				myMarkup.AddElem("DEVICEID",m_ThePC.GetDeviceID());
						
				// Prolog query
				AddLog( _T( "HTTP SERVER: Sending prolog query..."));
				xmlResp = CUtils::sendXml(pConnect,&myMarkup);
				if( xmlResp.GetDoc() != "" ) {			
					AddLog( _T( "OK.\n"));
					// Prolog network response
					AddLog( _T( "HTTP SERVER: Receiving prolog response..."));
					CString rep=CUtils::getResponse(xmlResp);						
					AddLog( _T( "OK.\n"));
					if( !rep.CompareNoCase("stop") )
					{
						AddLog( _T("HTTP SERVER: INV : No inventory needed\n"));
						bInventoryNeeded=FALSE;
					}
					else if( !rep.CompareNoCase("send") )
					{
						AddLog( _T("HTTP SERVER: INV : Inventory requested by server\n"));
						bInventoryNeeded=TRUE;					
					}
					else
					{
						AddLog( _T("HTTP SERVER: INV : ERROR : Communication problem\n"));
						bServerUp=FALSE;
					}
				}
				else
					bServerUp=FALSE;
			}
			catch (CInternetException* pEx)
			{
				TCHAR sz[1024];
				pEx->GetErrorMessage(sz, 1024);
				AddLog( _T( "HTTP SERVER: Network initialization block: %s\n"), sz);
				pEx->Delete();			
			}
			AddLog( _T( "HTTP SERVER: Closing HTTP connection\n"));
			if(pConnect!=NULL)
			{
				pConnect->Close();			
				delete pConnect;
			}
			pConnect=NULL;
			sess.Close();
			//AddLog( _T( "OK.\n"));
		}

		// NO server, if the client is run in "local" mode
		if( CUtils::IsRequired(cmdL,"local") ) {
			AddLog( _T( "LOCAL MODE actived by /local argument: No network communication\n"));
			bServerUp = FALSE;
			bInventoryNeeded = TRUE ;
		}

		// NO inventory needed, if the client is run in "test" mode
		if( CUtils::IsRequired(cmdL,"test") )
		{
			AddLog( _T( "TEST MODE actived by /test argument\n"));
			bInventoryNeeded = FALSE;
		}
		else if( CUtils::IsRequired(cmdL,"force") )
		// Inventory forced if /force option is provided		
		{
			AddLog( _T( "INVENTORY forced by /force option\n"));
			bInventoryNeeded = TRUE;
		}

		/*****
		 *
		 *	Runs the automatic REGISTRY reading feature, only if the "REGISTRY" 
		 *	option was provided
		 *
		 ****/
		if(bServerUp && CUtils::isActivatedOption(xmlResp,"REGISTRY") && bInventoryNeeded ) {
			AddLog( _T( "Registry Values: function enabled by server...\n"));
			int cmpt=1;
			CMapStringToString* pM=NULL;
			do {
				CUtils::cleanCm(pM);
				pM=CUtils::getOptionAttributes(xmlResp,cmpt,"REGISTRY","REGTREE","REGKEY","NAME");
				
				if ( pM->GetCount() == 0 )
					break;

				CRegistry		myRegistry;
				CRegistryValue  myObject;
				CString	csName,
						csRegKey,
						csRegValue,
						csResult,
						csRegTree;
				int		nRegTree;

				pM->Lookup("REGTREE",csRegTree);
				pM->Lookup("VAL",csRegValue);
				pM->Lookup("REGKEY",csRegKey);
				pM->Lookup("NAME",csName);
				nRegTree = _ttoi( csRegTree );

				if (csRegValue == REGISTRY_ALL_VALUES_OF_KEY)
				{
					// Get all values of a key
					myRegistry.GetRegistryMultipleValues( m_ThePC.GetDeviceID(), csName, nRegTree, csRegKey, &(m_ThePC.m_RegistryList));
				}
				else
				{
					// Get single value
					if (myRegistry.GetRegistryValue( nRegTree, csRegKey, csRegValue, csResult))
					{
						// Add result to list
						myObject.SetDeviceID( m_ThePC.GetDeviceID());
						myObject.Set( csName, csResult);
						m_ThePC.m_RegistryList.AddTail( myObject);								
					}
				}
				cmpt++;							
			}
			while(pM->GetCount()>0);
			CUtils::cleanCm(pM);
			AddLog( _T( "Registry Values: scan finished (%d query executed)\n"), cmpt);
		}

		/*****
		 *
		 *	Main inventory function
		 *
		 ****/
		if( bInventoryNeeded ) {			
			// Get Device info
			AddLog( _T( "Retrieving Device informations...\n"));			
			if (!m_ThePC.RetrieveHardwareAndOS(pSysInfo, CUtils::IsRequired(cmdL,"hkcu"))) {
				// Can't get Device hardware and os => stop !
				AddLog( _T( "CANNOT RETRIEVE DEVICE INFORMATIONS !\nExiting\n\n\n"));
				return FALSE;
			}

			// bidouille pour 2000 pro sans nom
			if( ((CString)(m_ThePC.GetOSName())).GetLength() == 0 && m_ThePC.GetOSVersion()=="5.0.2195" )
				m_ThePC.SetOS("Microsoft Windows 2000 Professional", m_ThePC.GetOSVersion(), m_ThePC.GetOSComment());
			
			// Add OS to the list of detected Apps
			cFile.Set( _T( "Microsoft Corporation"), m_ThePC.GetOSName(),
					   m_ThePC.GetOSVersion(), NOT_AVAILABLE, m_ThePC.GetOSComment(), NOT_AVAILABLE, 0, TRUE);
			m_ThePC.m_SoftwareList.AddTail( cFile);
			// Connect to database and load settings
			ConnectDB( szExecutionFolder);
			// Get connected username
			if (m_pTheDB->GetLogAccess()) 
			{
				CAccessLog cAccessLog;
				AddLog( _T( "Retrieve logon informations needed...\n"));
				if (m_pTheDB->GetProcess())
					// Check for running processes
					cAccessLog.Retrieve( m_ThePC.GetDeviceID(), m_ThePC.GetLoggedOnUser(), m_pTheDB->GetProcessFilenames());
				else
					// Don't check for running processes
					cAccessLog.Retrieve( m_ThePC.GetDeviceID(), m_ThePC.GetLoggedOnUser(), NULL);
				AddLog( _T( "Retrieve logon informations OK (<%s> <%s> <%s>).\n"), cAccessLog.GetUserID(), cAccessLog.GetLogonDate(),
						cAccessLog.GetProcessesStatus());
				// Update the DB
				cAccessLog.SetDeviceName( m_ThePC.GetDeviceName());
				if (!m_pTheDB->AddAccessLog( &cAccessLog))
				{
					// Display error if required, but continue
					m_pTheDB->GetDisplayError();// && AfxMessageBox( IDS_ERROR_DB_ADDING_ACCESS_LOGS, MB_ICONEXCLAMATION);
				}
			}
			
			// Perform HDD search
			SearchLocalHDD();
			// Retrieve registry values if any
			m_pTheDB->RetrieveRegistryValues( m_ThePC);
			// Load external BIOS infos from CSV if needed
			LoadBIOS( cmdL, szExecutionFolder, m_ThePC);
			// Update the database
			if (!m_pTheDB->UpdateDevice( m_ThePC))
			{
				m_pTheDB->GetDisplayError();// && AfxMessageBox( IDS_ERROR_DB_UPDATING, MB_ICONSTOP);
			}
			
			// WMI Disconnection
			delete pSysInfo;
			pSysInfo=NULL;
		
			/*****
			 *
			 *	Runs the IPDISCOVERY feature, only if the "IPDISCOVER" option was provided
			 *
			 ****/
			CString forcedIpdisc = CUtils::getParamValue(cmdL,"ipdisc");

			if( (bServerUp && CUtils::isActivatedOption(xmlResp,"IPDISCOVER")) || forcedIpdisc.GetLength()>0 ) {

			// Update Didier LIROULET: To allow running under Win 95 or NT4 without iphlpapi.dll
				// Load the IPHLPAPI 32 bit and winsock 2 DLL
				HINSTANCE	hDllIpHlpApi,	hDllWS2;
				hDllIpHlpApi = LoadLibrary( _T( "iphlpapi.dll"));
				hDllWS2 = LoadLibrary( _T( "ws2_32.dll"));
				if ((hDllIpHlpApi == NULL) || (hDllWS2 == NULL))
				{
					// Tell the user that we could not find a usable WinSock DLL.                                  
					AddLog( _T( "IPDISCOVER: Failed to load <iphlpapi.dll> or <ws2_32.dll> !\n"));
				}
				else
				{
					// Load the SendARP, htonl, ntol, inet_addr and inet_ntoa functions
					if (((*(FARPROC*)&lpfn_SendARP = GetProcAddress( hDllIpHlpApi, _T( "SendARP"))) == NULL) ||
						((*(FARPROC*)&lpfn_htonl = GetProcAddress( hDllWS2, _T( "htonl"))) == NULL) ||
						((*(FARPROC*)&lpfn_ntohl = GetProcAddress( hDllWS2, _T( "ntohl"))) == NULL) ||
						((*(FARPROC*)&lpfn_inet_addr = GetProcAddress( hDllWS2, _T( "inet_addr"))) == NULL) ||
						((*(FARPROC*)&lpfn_inet_ntoa = GetProcAddress( hDllWS2, _T( "inet_ntoa"))) == NULL))
					{
						// Tell the user that we could not find a usable SetupAPI DLL or wsock32 DLL.                                  
						AddLog( _T( "IPDISCOVER: Failed to load <SendARP> function from iphlpapi.dll or <htonl/ntol/inet_addr/inet_ntoa> functions from ws2_32.dll !\n"));
					}
					else
					{						
						CMapStringToString* pM=NULL;	
						CString		nbr,mask;

						pM=CUtils::getOptionAttributes(xmlResp,1,"IPDISCOVER");
						pM->Lookup("VAL",nbr);
						if( forcedIpdisc.GetLength() == 0 )
							AddLog( _T( "IPDISCOVER: function required by HTTP server...\n"));
						else {
							nbr = forcedIpdisc;
							AddLog( _T( "IPDISCOVER: function forced by /ipdisc flag\n"));
						}
						
						mask=m_ThePC.m_NetworkList.GetMaskByNetNumber(nbr);		
						CUtils::cleanCm(pM);
						ULONG   IpCur=1;
						CObArray handles;
						DWORD errcode;

						if(mask.GetLength() == 0) {
							AddLog( _T("IPDISCOVER: ERROR: No mask is available for the given network number: %s\n"),nbr);
						}
						else {
							pXml->AddElem("IPDISCOVER");
							pXml->IntoElem();
							AddLog( _T("IPDISCOVER: Scanning to detect IP enabled hosts for the given network number: %s\n"),nbr);
							ULONG   ipMsk, maxIp;	
							CString csSent, csIncrIp;
							BOOL	baliseIp = FALSE;
							BOOL	fastIp = CUtils::IsRequired(cmdL, "fastip");
							UINT * pU;
							DOUBLE waitedMaxThreads = 0;
							UINT maxWaitTime = CUtils::IsRequired(cmdL, "nowait") ? 60 : 3600;

							ipMsk = lpfn_htonl( lpfn_inet_addr(mask));

							m_netNumber = lpfn_ntohl(lpfn_inet_addr (nbr));
							maxIp = ~ipMsk-1;		
							
							m_hostFound = 0;							
							//launching threads
							do {
								//cleaning dead threads
								int thdCount=0;
								while( thdCount < handles.GetSize() ) {
									GetExitCodeThread( ((CWinThread*)handles.GetAt(thdCount))->m_hThread, &errcode );
									if( errcode != STILL_ACTIVE ) {																			
										delete (CWinThread*)handles.GetAt(thdCount);
										handles.RemoveAt(thdCount);
										thdCount--;
									}
									thdCount++;
								}

								//too many threads for too long (1 hour)
								if( waitedMaxThreads > (maxWaitTime * 1000) ) {
									AddLog("IPDISCOVER: ERROR: Waited %s seconds with max threads, skipping ipdiscover\n",maxWaitTime);
									break;
								}

								//too many threads ?
								if( handles.GetSize()> (fastIp?MAX_FASTIP_THREADS:MAX_THREADS)-4) {
									Sleep(1);
									waitedMaxThreads += 1;
									continue;
								}

								pU = new UINT();
								*pU = IpCur;
								CWinThread* pT;								
								pT = AfxBeginThread(threadWork, LPVOID(pU), THREAD_PRIORITY_NORMAL,0,CREATE_SUSPENDED);
								handles.Add((CObject*)pT);
								pT->m_bAutoDelete = FALSE;
								pT->ResumeThread();
								IpCur++;
								if( !fastIp )
									Sleep(8);
							}
							while( IpCur < maxIp && IpCur <= NB_IP_MAX );
								
							UINT timeWaited = 0;
							UINT timeToWait = 10;
							UINT maxTimeToWait = 10000;
							BOOL allThreadsDead ;

							// waiting for threads to die
							do  {
								DWORD errcode;
								allThreadsDead = TRUE;
														
								int thdCount=0;
								while( thdCount < handles.GetSize() ) {								
									GetExitCodeThread( ((CWinThread*)handles.GetAt(thdCount))->m_hThread, &errcode );
									if( errcode == STILL_ACTIVE ) {
										//A thread still alive after %u msecs, waiting %u msecs more\n",  timeWaited, timeToWait);
										allThreadsDead = FALSE;
										break;
									}
									else {																		
										//A thread died after %u msecs\n",  timeWaited);
										delete (CWinThread*)handles.GetAt(thdCount);
										handles.RemoveAt(thdCount);
										thdCount--;
									}
									thdCount++;
								}
								Sleep(timeToWait);
								timeWaited += timeToWait;
							}
							while(!allThreadsDead && timeWaited < maxTimeToWait );

							//cleaning living threads
							if( timeWaited >= maxTimeToWait ) {
								for( int thdCount=0; thdCount < handles.GetSize(); thdCount++) {
									((CWinThread*)handles.GetAt(thdCount))->SuspendThread();
									delete (CWinThread*)handles.GetAt(thdCount);
									handles.RemoveAt(thdCount);
									AddLog("IPDISCOVER: ERROR: Thread still alive after %u msecs, thread killed\n",  timeWaited);
								}
							}
							else
								AddLog("IPDISCOVER: waited %u mseconds for the threads to die\n", timeWaited);
							
							AddLog( _T("IPDISCOVER: NETWORK scan finished, %u hosts found, %u scanned\n"),m_hostFound,IpCur);
							pXml->OutOfElem();
						}

						FreeLibrary( hDllIpHlpApi);
						FreeLibrary( hDllWS2);
					}
				}
			}
			else if(bServerUp)
				AddLog( _T( "IPDISCOVER: function not required by HTTP server...\n"));
			
			// Cleaning function to remove any binary character
			CUtils::cleanXml(pXml);

			/*****
			 *
			 *	Writes the plain xml file on disk (for debugging purpose)
			 *	 only if the "xml" option was provided
			 *
			 ****/
			if(CUtils::IsRequired(cmdL,"xml")) {
				AddLog( _T( "Writing results to standard XML file <ocsinventory.xml> required by argument -XML..."));
				CFile xm;
				try	{
					CString xmlFname;
					xmlFname.Format( "%s.xml",m_ThePC.GetDeviceID());
					xm.Open( xmlFname,CFile::modeCreate | CFile::modeWrite);
					xm.Write(pXml->GetDoc(),pXml->GetDoc().GetLength());
					xm.Close();
					AddLog( _T( "OK\n"));
				}
				catch(CException* pEx)
				{
					AddLog( _T( "Failed because <%s> !\n"), m_pTheDB->GetErrorMessage( pEx));
					pEx->Delete();
				}
			}

			/*****
			 *
			 *	Writes the compressed xml file on disk
			 *	 only if the "file" or the "local" option was provided
			 *
			 ****/
			if(CUtils::IsRequired(cmdL,"file") || CUtils::IsRequired(cmdL,"local"))	{
				AddLog( _T( "Writing results to compressed XML file <%s.ocs> required by argument -FILE or -LOCAL..."),
						m_ThePC.GetDeviceID());
				try {
					CString fichInventory;	
					CByteArray* aa=CUtils::compressStr(pXml->GetDoc());
					fichInventory.Format("%s.ocs",m_ThePC.GetDeviceID());
					CUtils::byteToFile(aa,fichInventory);
					delete aa;
					AddLog( _T( "OK\n"));
				}
				catch (CException* pEx)
				{
					AddLog( _T( "Failed because <%s> !\n"), m_pTheDB->GetErrorMessage( pEx));
					pEx->Delete();
				}
			}		
		}
		
		// WMI Disconnection
		if(pSysInfo != NULL ) {		
			delete pSysInfo;
			pSysInfo=NULL;
		}
		
		if (bServerUp)
		{
			try {
				AddLog( _T( "HTTP SERVER: Creating CInternetSession to send inventory results..."));

				CInternetSession sess2(csUserAgent, 1, iProxy);
				AddLog( _T( "OK.\n"));

				AddLog( _T( "HTTP SERVER: Connecting to server %s port %i..."), csServer, iPort);
				pConnect = sess2.GetHttpConnection(csServer, iPort);
				AddLog( _T( "OK\n"));
				
				if(bServerUp && ! CUtils::IsRequired(cmdL,"test") && bInventoryNeeded ) {				
					
					AddLog( _T( "HTTP SERVER: INV : SEND received, sending inventory..."));
					xmlResp=CUtils::sendXml(pConnect,pXml);
					AddLog( _T( "OK.\n"));
					// Inventory sent, writing down new deviceid
					if( bOldFlag )
						CUtils::writeMacDeviceid( m_ThePC.GetDeviceID(), csActualMac, cmdL);

					CString rep2=CUtils::getResponse(xmlResp);				
					if(!rep2.CompareNoCase("account_update"))
					{
						AddLog( _T( "HTTP SERVER: INV : account info update needed\n"));
						CUtils::parseAccountParams(xmlResp);
					}
					else if(!rep2.CompareNoCase("no_account_update"))
					{
						AddLog( _T( "HTTP SERVER: INV : no account info update\n"));
					}
					else
					{
						AddLog( _T( "HTTP SERVER: INV : ERROR : No server answer concerning the account update\n"));
						bServerUp=FALSE;
					}
				}					
				
				if(bServerUp) 
				{					
					myMarkup.SetDoc(XML_HEADERS);
					myMarkup.AddElem("REQUEST");
					myMarkup.IntoElem();
					myMarkup.AddElem("QUERY","UPDATE");
					myMarkup.AddElem("PLATFORM",PLATFORM_NAME);
					myMarkup.AddElem("AGENT",csAgentVer);

					// Asks wether an update is needed
					AddLog( _T( "HTTP SERVER: UPD : Sending update query..."));
					xmlResp=CUtils::sendXml(pConnect,&myMarkup);
					AddLog( _T( "OK.\n"));
					AddLog( _T( "HTTP SERVER: UPD : Receiving update response..."));
					CString rep3=CUtils::getResponse(xmlResp);
					AddLog( _T( "OK.\n"));

					if(!rep3.CompareNoCase("no_update"))
					{
						AddLog( _T( "HTTP SERVER: UPD : No update needed\n"));
						m_bNeedUpdate=FALSE;

						/*****
						 *
						 *	TEST mode used to test a newly downloaded client version
						 *	 only if the "test" option was provided
						 *
						 ****/
						if(CUtils::IsRequired(cmdL,"test"))
						{
							try {
								CFile::Remove("ok.ok");
							}
							catch (CException * pE) {
								pE->Delete();
							}
							
							AddLog("\tTEST: Client test OK\n");
							try {
								CFile okFile;
								okFile.Open("ok.ok",CFile::modeCreate|CFile::modeWrite);
								okFile.Close();
							}
							catch(CException * pEf) {
								pEf->Delete();
								AddLog("\tTEST: ERROR: Can't write ok.ok, update canceled\n");
							}
						}
					}
					else if(!rep3.CompareNoCase("update")&&!CUtils::IsRequired(cmdL,"test"))
					{
						m_bNeedUpdate=TRUE;
						xmlResp.ResetPos();
						xmlResp.FindElem("REPLY");
						xmlResp.FindChildElem("AGENT");
						CString agent=xmlResp.GetChildData();
						
						CString url;
						url.Format("%s/update/windows/agent/%s",URL_SUFFIX,agent);
						AddLog( _T( "HTTP SERVER: UPD : Update requested, getting file <%s>..."),url);
						
						CByteArray* reponseCompresse = CUtils::req(pConnect,NULL,0,FALSE,url);
						AddLog( _T( "OK.\n"));
						AddLog( _T( "HTTP SERVER: UPD : Uncompressing files..."));
						CByteArray* reponseDecompresse = CUtils::deCompressBin(reponseCompresse);	
						AddLog( _T( "OK.\n"));
						CUtils::byteToFile(reponseDecompresse,"upd.zip");					
						if(reponseCompresse!=NULL)	delete reponseCompresse;
						if(reponseDecompresse!=NULL) delete reponseDecompresse;
						AddLog( _T( "HTTP SERVER: UPD : File download\n"));
						
					}
					else if(CUtils::IsRequired(cmdL,"test")) {

						try {
							CFile::Remove("ok.ok");
						}
						catch (CException * pE) {
							pE->Delete();
						}

						AddLog( _T("HTTP SERVER: UPD: ERROR: Update asked during an update test\n"));
					}
					else
					{
						AddLog( _T( "HTTP SERVER: UPD : ERROR : Update server answer not understood:\n"));
					}
				}
				AddLog( _T( "HTTP SERVER: Closing HTTP connection...."));
				if(pConnect!=NULL)
				{
					pConnect->Close();			
					delete pConnect;
				}
				pConnect=NULL;
				sess2.Close();
				AddLog( _T( "OK.\n"));
			}
			catch (CInternetException* pEx)
			{
				TCHAR sz[1024];
				pEx->GetErrorMessage(sz, 1024);
				AddLog("ERREUR HTTP: BASE: %s\n", sz);
				pEx->Delete();			
			}
		}		
		
		if(bInventoryNeeded ) {
			m_pTheDB->CloseDB();
			delete m_pTheDB;
			m_pTheDB = NULL;
		}

		// Get the search end time
		cEndTime = CTime::GetCurrentTime();
		// Compute execution duration
		m_ThePC.SetExecutionDuration( cStartTime, cEndTime);
		AddLog( _T( "Execution duration: %s.\n"), m_ThePC.GetExecutionDuration());
	}
	catch( CException *pEx)
	{
		if (pEx->IsKindOf( RUNTIME_CLASS( CFileException)))
		{
			// CSV exception
			AddLog( _T( "Failed because file exception !\nExiting...\n\n\n"));
			if ((m_pTheDB != NULL) && m_pTheDB->GetDisplayError())
				CXMLInteract::DisplayXMLException( (CFileException *) pEx);
		}
		else
		{
			// Unknown
			AddLog( _T( "Failed because Unknown exception !\nExiting...\n\n\n"));
		}
		if ((m_pTheDB != NULL) && m_pTheDB->GetDisplayError())
			CStoreInteract::DisplayException( pEx);
		pEx->Delete();
		if (m_pTheDB != NULL)
		{
			if (m_pTheDB->IsOpen())
				m_pTheDB->CloseDB();
			delete m_pTheDB;
			m_pTheDB = NULL;
		}
		return FALSE;
	}
	return FALSE;
}

BOOL COCSInventoryApp::IsCheckDate()
{
	COleDateTime		cOleDateNow,
						cOleLastCheck;
	COleDateTimeSpan	cOleDateDiff;

	// Get the current time
	cOleDateNow = COleDateTime::GetCurrentTime();
	// Get the last check date
 	cOleLastCheck = m_pTheDB->GetLastCheckDate( m_ThePC.GetDeviceID());
	AddLog( _T( "\tLast inventory: %s, Today: %s, Frequency: %ld day(s).\n"),
					   cOleLastCheck.Format( _T( "%Y-%m-%d")),
					   cOleDateNow.Format( _T( "%Y-%m-%d")),
					   m_pTheDB->GetFrequency());
	// Substract the last check date from the current date
	cOleDateDiff = cOleDateNow - cOleLastCheck;
	// Check the diff
	if (cOleDateDiff.GetDays() < m_pTheDB->GetFrequency())
		// Don't run, the delay is not completed
		return FALSE;
	// Run !!!
	return TRUE;
}

void COCSInventoryApp::SearchFilesInDirectory(LPCTSTR lpstrDir)
{
	CString		csDir = lpstrDir;
	CFileFind	cFinder;
	BOOL		bWorking;
	CSoftware	cApp;
	CString		csPublisher,
				csName,
				csVersion,
				csComment;

	// Search for all files and directory
	csDir += "*.*";
	bWorking = cFinder.FindFile( csDir);
	while (bWorking)
	{
		bWorking = cFinder.FindNextFile();
		if (!cFinder.IsDots())
		{
			// Not "." or ".." directory
			if (cFinder.IsDirectory())
			{
				// This is a directory => recursive search if needed
				if (m_pTheDB->IsExcludeFolder( cFinder.GetFilePath()))
				{
					// Folder to exclude from search => skip
					AddLog( _T( "\t\tSkipping folder <%s>...\n"), cFinder.GetFilePath());
				}
				else
				{
					csDir = cFinder.GetFilePath() + "\\";
					SearchFilesInDirectory( csDir);
				}
			}
			else
			{
				// This a file => update total files number for this Device
				m_lNumberOfFiles ++;
				if (m_pTheDB->IsExtensionToSearch( cFinder.GetFileName()))
				{
					// This is an apps to search
					if (!getFileVersion( cFinder.GetFilePath(), csPublisher, csName, csVersion, csComment))
						// Unable to get version infos => use filename
						csName = cFinder.GetFileName();
					StrForSQL( csName);
					if (csName.IsEmpty())
						// Version info do not contains app name => use filename
						csName = cFinder.GetFileName();
					cApp.Clear();
					cApp.Set( csPublisher, csName, csVersion, cFinder.GetRoot(), csComment, cFinder.GetFileName(), cFinder.GetLength());
					m_ThePC.m_SoftwareList.AddTail( cApp);
				}
			}
		}
	}
}

void COCSInventoryApp::SearchLocalHDD()
{
	CString			csDrive,
					csMessage;
	UINT			uIndex;
	DWORD			dwLogicalDrives;
	CSoftware		cFile;
	CLogicalDrive	cLogicalDrive;

	AddLog( _T( "Scanning Device's Logical Drive(s) for informations and softwares...\n"));
	// Search Logical Drives
	if ((dwLogicalDrives = GetLogicalDrives()) == 0)
	{
		// Cannot find logical drives
		AddLog( _T( "Failed in call to <GetLogicalDrives> function !\n"));
		return;
	}
	for (uIndex=0; uIndex<=26; uIndex++)
	{
		// Check if the logical drive uIndex really exists
		if (dwLogicalDrives & 1)
		{
			// Yes => Construct the root directory
			csDrive.Format( _T( "%c:\\"), 'A'+uIndex);
			AddLog( _T( "\tGetting Logical Drive <%s> properties...OK\n"), csDrive);
			// Check if this is a local Hard Disk
			if (cLogicalDrive.RetrieveDriveInfo( csDrive))
			{
				// This a local Hard Disk
				if (m_pTheDB->IsSearchDiskEnabled())
				{
					// Search files in drive directories
					m_lNumberOfFiles = 0;
					AddLog( _T( "\tSearching Softwares on Logical Drive <%s>...\n"), csDrive);
					SearchFilesInDirectory( csDrive);
				}
				else
					// Do not search files in drive directories
					m_lNumberOfFiles = 0;
			}
			else
				// Not a local drive
				m_lNumberOfFiles = 0;
			// Set the logical drive file number
			cLogicalDrive.SetFilesNumber( m_lNumberOfFiles);
			// Add the logical drive to the list
			m_ThePC.m_DriveList.AddTail( cLogicalDrive);
		}
		// Bit shift the logical drives mask
		dwLogicalDrives >>= 1;
	}
}

BOOL COCSInventoryApp::LoadBIOS( LPCTSTR lpstrCommandLine, LPCTSTR lpstrExecutionFolder, CDeviceProperties &pPC)
{
	CString	csCommand = lpstrCommandLine,
			csFilename;
	CXMLInteract	myCsvDB;

	// Read BIOS from XML file
	// Optional; perhaps no BIOS infos
	if (!GetBiosFilename( csCommand, lpstrExecutionFolder, pPC, csFilename))
		// Loading BIOS from an external XML file is not asked
		return TRUE;
	// Try to load BIOS infos from CSV
	pPC.m_BIOS.Set( NOT_AVAILABLE, NOT_AVAILABLE, NOT_AVAILABLE, NOT_AVAILABLE, NOT_AVAILABLE, NOT_AVAILABLE, NOT_AVAILABLE);
	if (myCsvDB.ReadBIOS( csFilename, pPC))
	{
		// BIOS read => Try to find if laptop chassis
		if ((_tcsicmp( pPC.m_BIOS.GetMachineType(), _T( "Portable")) == 0) ||
			(_tcsicmp( pPC.m_BIOS.GetMachineType(), _T( "LapTop")) == 0) ||
			(_tcsicmp( pPC.m_BIOS.GetMachineType(), _T( "Notebook")) == 0) ||
			(_tcsicmp( pPC.m_BIOS.GetMachineType(), _T( "SubNotebook")) == 0))
			// Yes, it is
			pPC.SetDeviceType( WINDOWS_NOTEBOOK);
		// delete XML file
		try
		{
			// Delete imported file
			CFile::Remove( csFilename);
		}
		catch( CFileException *pFileEx)
		{
			// Ignore exception when removing files
			pFileEx->Delete();
		}
		return TRUE;
	}
	else
		// Unable to read BIOS file
		return FALSE;
}

BOOL COCSInventoryApp::GetBiosFilename( CString &csCommandLine, LPCTSTR lpstrExecutionFolder, CDeviceProperties &pPC, CString &csFilename)
{
	CString csBuffer;
	int		nPosStart,
			nPosEnd;

	csCommandLine.MakeLower();
	// Try to find -bios in the command line
	if ((nPosStart = csCommandLine.Find( _T( "-bios"))) < 0)
	{
		// -BIOS command line switch not used => Try to find /bios in the command line
		if ((nPosStart = csCommandLine.Find( _T( "/bios"))) < 0)
			// Do not import BIOS from a XML file
			return FALSE;
		// /BIOS command line switch used => Try to find if a filename is specified
		csBuffer = csCommandLine.Mid( nPosStart);
		if ((nPosStart = csBuffer.Find( _T( "="))) < 0)
			// No file name specified => use default location in the BIOS sub folder of the Agent folder
			csFilename.Format( _T( "%s%s%s.csv"), lpstrExecutionFolder, BIOS_FOLDER, pPC.GetDeviceName());
		else
		{
			// Filename specified => extract it 
			csFilename = csBuffer.Mid( nPosStart+1);
			if (csFilename.GetAt( 0) == '\"')
			{
				// Using quoted string for long filename => find next quote
				if ((nPosEnd = csFilename.Find( _T( "\""), 1)) < 0)
					// Quoted string not terminated
					return FALSE;
				// Extract filename from quotes
				csBuffer = csFilename.Mid( 1);
				csFilename = csBuffer.Left( nPosEnd-1);
			}
			else
			{
				// Not using quoted string => find next space to see if there is onather command line switch
				if ((nPosEnd = csFilename.Find( _T( ' '))) > 0)
				{
					// bios is not the last command line switch => filename go to the next space
					csBuffer = csFilename.Left( nPosEnd);
					csFilename = csBuffer;
				}
			}
		}
		csFilename.TrimRight();
		return TRUE;
	}
	// -BIOS command line switch used => Try to find if a filename is specified
	csBuffer = csCommandLine.Mid( nPosStart);
	if ((nPosStart = csBuffer.Find( _T( "="))) < 0)
		// No file name specified => use default location in the BIOS sub folder of the Agent folder
		csFilename.Format( _T( "%s%s%s.csv"), lpstrExecutionFolder, BIOS_FOLDER, pPC.GetDeviceName());
	else
	{
		// Filename specified => extract it 
		csFilename = csBuffer.Mid( nPosStart+1);
		if (csFilename.GetAt( 0) == '\"')
		{
			// Using quoted string for long filename => find next quote
			if ((nPosEnd = csFilename.Find( _T( "\""), 1)) < 0)
				// Quoted string not terminated
				return FALSE;
			// Extract filename from quotes
			csBuffer = csFilename.Mid( 1);
			csFilename = csBuffer.Left( nPosEnd-1);
		}
		else
		{
			// Not using quoted string => find next space to see if there is onather command line switch
			if ((nPosEnd = csFilename.Find( _T( ' '))) > 0)
			{
				// bios is not the last command line switch => filename go to the next space
				csBuffer = csFilename.Left( nPosEnd);
				csFilename = csBuffer;
			}
		}
	}
	csFilename.TrimRight();
	return TRUE;
}

int COCSInventoryApp::ExitInstance() 
{
	CString cmdL = this->m_lpCmdLine;	
	CString upd=CUtils::readParamFile("update");
	BOOL updateAllowed=   upd=="" || upd=="1" ;

	// update.exe launch if update is needed
	if(!CUtils::IsRequired(cmdL,"test")&&m_bNeedUpdate&&updateAllowed)
	{
		CString cmd;
		cmd.Format( "update.exe %s", cmdL );
		
		STARTUPINFO si;
		PROCESS_INFORMATION pi;

		ZeroMemory( &si, sizeof(si) );
		si.cb = sizeof(si);
		ZeroMemory( &pi, sizeof(pi) );

		si.dwFlags=STARTF_USESHOWWINDOW;
		si.wShowWindow=SW_HIDE;
		CreateProcess( NULL, cmd.GetBuffer(0), NULL, NULL, FALSE, 0, NULL, NULL, &si,&pi );
	}
	return CWinApp::ExitInstance();
}

CInputDlg::CInputDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CInputDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CInputDlg)
	m_ValV = _T("");
	m_LabelText = _T("");
	//}}AFX_DATA_INIT
}


void CInputDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CInputDlg)
	DDX_Control(pDX, IDC_VAL, m_ValC);
	DDX_Text(pDX, IDC_VAL, m_ValV);
	DDX_Text(pDX, IDC_LABEL_TEXT, m_LabelText);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(CInputDlg, CDialog)
	//{{AFX_MSG_MAP(CInputDlg)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CInputDlg message handlers

void CInputDlg::OnOK() 
{
	//TODO: specific
	UpdateData(TRUE);
/*	if(m_ValV.GetLength()<5) { TODO: checking
		AfxMessageBox("Votre code unit� doit �tre entr� sur 5 chiffres",MB_OK|MB_ICONEXCLAMATION);
	}
	else {	
		if(atoi(m_ValV)==0)	{
			AfxMessageBox("Votre code unit� doit �tre un nombre",MB_OK|MB_ICONEXCLAMATION);			
		}
		else*/
	CDialog::OnOK();
//	}
}


int CInputDlg::DoModal() 
{	
	return CDialog::DoModal();
}

void CInputDlg::OnPaint() 
{
	CPaintDC dc(this); // device context for painting
	
	if( label.GetLength() == 0 ) {
		m_LabelText = CUtils::readParamFile("tagDialog");
		UpdateData(FALSE);
	}
}