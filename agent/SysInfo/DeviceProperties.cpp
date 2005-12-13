// Document modified at : Sunday, January 04, 2004 7:37:06 PM , by user : Didier LIROULET , from computer : SNOOPY-XP-PRO

//====================================================================================
// Open Computer and Software Inventory
// Copyleft Didier LIROULET 2003
// Web: http://ocsinventory.sourceforge.net
// E-mail: ocsinventory@tiscali.fr

// This code is open source and may be copied and modified as long as the source
// code is always made freely available.
// Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
//====================================================================================

// DeviceProperties.cpp: implementation of the CDeviceProperties class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "sysinfo.h"
//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CDeviceProperties::CDeviceProperties()
{
	Clear();
}

CDeviceProperties::~CDeviceProperties()
{
	Clear();
}

void CDeviceProperties::Clear()
{
	COleDateTime oleTimeNow;

	m_csDeviceID.Empty();		// Device unique ID
	m_csDeviceName.Empty();		// Device netbios name
	m_csDomain.Empty();			// Domain or workgroup
	m_csOSName.Empty();			// OS Name of the device (ex "Windows NT")
	m_csOSVersion.Empty();		// OS Version of the device (ex "4.0 Build 1381")
	m_csOSComment.Empty();		// OS Comment of the device (ex "Service Pack 6")
	m_csProcessorType.Empty();	// First Processor type of the device (ex "Intel Pentium II Model 1280 Stepping 2")
	m_csProcessorSpeed.Empty(); // Processor speed
	m_dwNumberOfProcessor = 0;	// Number of processor of the device
	m_ulPhysicalMemory = 0;		// Physical memory of the device
	m_ulSwapSize = 0;		// Page File Size of the device
	m_csIPAddress.Empty();		// IP Address of the device if available (ex "192.3.4.1" or "Unavailable")
	m_csExecutionDuration = _T( "00:00:00"); // Duration of the inventory check
	m_csLoggedOnUser.Empty();	// Logged on user when device has been checked
	m_csDescription.Empty();	// Device description extracted from OS
	m_csWinRegCompany.Empty();	// Windows registered company
	m_csWinRegOwner.Empty();	// Windows registered owner
	m_csWinRegProductID.Empty();// Windows registered product ID
	oleTimeNow.SetDate( 1970, 1, 1);
	m_csLastCheckDate = oleTimeNow.Format( _T( "%Y-%m-%d"));
	m_BIOS.Clear();
	m_CommentList.RemoveAll();
	m_DriveList.RemoveAll();
	m_InputList.RemoveAll();
	m_InventoryList.RemoveAll();
	m_MemoryList.RemoveAll();
	m_ModemList.RemoveAll();
	m_MonitorList.RemoveAll();
	m_NetworkList.RemoveAll();
	m_PortList.RemoveAll();
	m_PrinterList.RemoveAll();
	m_RegistryList.RemoveAll();
	m_RepairList.RemoveAll();
	m_SlotList.RemoveAll();
	m_SoftwareList.RemoveAll();
	m_SoundList.RemoveAll();
	m_StorageList.RemoveAll();
	m_SystemControllerList.RemoveAll();
	m_VideoList.RemoveAll();
	m_uType = NEW_DEVICE;
}

void CDeviceProperties::GenerateUID()
{
	AddLog( _T( "Generating Unique ID for device <%s>..."), m_csDeviceName);
	COleDateTime myDate = COleDateTime::GetCurrentTime();

	m_csDeviceID.Format( _T( "%s-%s"),
						m_csDeviceName, 
						myDate.Format( _T( "%Y-%m-%d-%H-%M-%S")));
	AddLog( _T( "OK (%s)\n"), m_csDeviceID);
}

void CDeviceProperties::SetDeviceID(LPCTSTR lpstrDeviceID)
{
	m_csDeviceID = lpstrDeviceID;
	StrForSQL( m_csDeviceID);
}

void CDeviceProperties::SetDeviceName(LPCTSTR lpstrName)
{
	m_csDeviceName = lpstrName;
	StrForSQL( m_csDeviceName);
}

void CDeviceProperties::SetOS(LPCTSTR lpstrName, LPCTSTR lpstrVersion, LPCTSTR lpstrComment)
{
	m_csOSName = lpstrName;
	StrForSQL( m_csOSName);
	m_csOSVersion = lpstrVersion;
	StrForSQL( m_csOSVersion);
	m_csOSComment = lpstrComment;
	StrForSQL( m_csOSComment);
}

void CDeviceProperties::SetProcessor(LPCTSTR lpstrName, LPCTSTR lpstrSpeed, DWORD dwNumber)
{
	m_csProcessorType = lpstrName;
	StrForSQL( m_csProcessorType);
	m_csProcessorSpeed = lpstrSpeed;
	StrForSQL( m_csProcessorSpeed);
	m_dwNumberOfProcessor = dwNumber;
}

void CDeviceProperties::SetMemory(ULONG ulPhysical, ULONG ulPageFile)
{
	m_ulPhysicalMemory = ulPhysical;
	m_ulSwapSize = ulPageFile;
}

void CDeviceProperties::SetIPAddress(LPCTSTR lpstrIP)
{
	m_csIPAddress = lpstrIP;
	StrForSQL( m_csIPAddress);
}

void CDeviceProperties::SetLastCheckDate( LPCTSTR lpstrDate)
{
	m_csLastCheckDate = lpstrDate;
	StrForSQL( m_csLastCheckDate);
}

void CDeviceProperties::SetExecutionDuration( CTime &cBeginTime, CTime &cEndTime)
{
	CTimeSpan	cTimeExec;				// Time of execution

	// Format time execution
	cTimeExec = cEndTime - cBeginTime;
	// Format SQL query
	m_csExecutionDuration.Format( _T( "%.02d:%.02d:%.02d"), cTimeExec.GetHours(), cTimeExec.GetMinutes(), cTimeExec.GetSeconds());
}

void CDeviceProperties::SetExecutionDuration( LPCTSTR lpstrDuration)
{
	m_csExecutionDuration = lpstrDuration;
	StrForSQL( m_csExecutionDuration);
}

void CDeviceProperties::SetLoggedOnUser( LPCTSTR lpstrUser)
{
	m_csLoggedOnUser = lpstrUser;
	StrForSQL( m_csLoggedOnUser);
}

void CDeviceProperties::SetDescription( LPCTSTR lpstrDescription)
{
	m_csDescription = lpstrDescription;
	StrForSQL( m_csDescription);
}

void CDeviceProperties::SetDomainOrWorkgroup( LPCTSTR lpstrDomain)
{
	m_csDomain = lpstrDomain;
	StrForSQL( m_csDomain);
}

void CDeviceProperties::SetWindowsRegistration( LPCTSTR lpstrCompany, LPCTSTR lpstrOwner, LPCTSTR lpstrProductID)
{
	m_csWinRegCompany = lpstrCompany;
	StrForSQL( m_csWinRegCompany);
	m_csWinRegOwner = lpstrOwner;
	StrForSQL( m_csWinRegOwner);
	m_csWinRegProductID = lpstrProductID;
	StrForSQL( m_csWinRegProductID);
}

void CDeviceProperties::SetDeviceType( UINT uType)
{
	m_uType = uType;
}

LPCTSTR CDeviceProperties::GetDeviceID()
{
	return m_csDeviceID;
}

LPCTSTR CDeviceProperties::GetDeviceName()
{
	return m_csDeviceName;
}

LPCTSTR CDeviceProperties::GetOSName()
{
	return m_csOSName;
}

LPCTSTR CDeviceProperties::GetOSVersion()
{
	return m_csOSVersion;
}

LPCTSTR CDeviceProperties::GetOSComment()
{
	return m_csOSComment;
}

LPCTSTR CDeviceProperties::GetProcessorType()
{
	return m_csProcessorType;
}

LPCTSTR CDeviceProperties::GetProcessorSpeed()
{
	return m_csProcessorSpeed;
}


DWORD CDeviceProperties::GetNumberOfProcessors()
{
	return m_dwNumberOfProcessor;
}


ULONG CDeviceProperties::GetPhysicalMemory()
{
	return m_ulPhysicalMemory;
}


ULONG CDeviceProperties::GetPageFileSize()
{
	return m_ulSwapSize;
}


LPCTSTR CDeviceProperties::GetIPAddress()
{
	return m_csIPAddress;
}

LPCTSTR CDeviceProperties::GetExecutionDuration()
{
	return m_csExecutionDuration;
}

LPCTSTR CDeviceProperties::GetLastCheckDate()
{
	return m_csLastCheckDate;
}

LPCTSTR CDeviceProperties::GetLoggedOnUser()
{
	return m_csLoggedOnUser;
}

LPCTSTR CDeviceProperties::GetDescription()
{
	return m_csDescription;
}

LPCTSTR CDeviceProperties::GetDomainOrWorkgroup()
{
	return m_csDomain;
}

LPCTSTR CDeviceProperties::GetWindowsRegisteredCompany()
{
	return m_csWinRegCompany;
}

LPCTSTR CDeviceProperties::GetWindowsRegisteredOwner()
{
	return m_csWinRegOwner;
}

LPCTSTR CDeviceProperties::GetWindowsProductID()
{
	return m_csWinRegProductID;
}

UINT CDeviceProperties::GetDeviceType()
{
	return m_uType;
}

BOOL CDeviceProperties::RetrieveHardwareAndOS(SysInfo * myPC, BOOL hkcu)
{
	// Get logged on user
	myPC->getUserName( m_csLoggedOnUser);
	// Get OS informations and device type (windows station or windows server)
	m_uType = myPC->getOS( m_csOSName, m_csOSVersion, m_csOSComment, m_csDescription);
	// Check if it is a notebook
	if (myPC->isNotebook())
		m_uType = WINDOWS_NOTEBOOK;
	AddLog( _T( "Detected device type: %u.\n"), m_uType);
	// Get NT Domain or Workgroup
	myPC->getDomainOrWorkgroup( m_csDomain);
	// Get BIOS informations
	myPC->getBiosInfo( &m_BIOS);
	// Get Processor infos
	m_dwNumberOfProcessor = myPC->getProcessors( m_csProcessorType, m_csProcessorSpeed);
	// Get memory informations
	myPC->getMemory( &m_ulPhysicalMemory, &m_ulSwapSize);
	myPC->getMemorySlots( &m_MemoryList);
	// Get Input Devices
	myPC->getInputDevices( &m_InputList);
	// Get System ports
	myPC->getSystemPorts( &m_PortList);
	// Get System Slots
	myPC->getSystemSlots( &m_SlotList);
	// Get System controlers
	myPC->getSystemControllers( &m_SystemControllerList);
	// Get Physical storage devices
	myPC->getStoragePeripherals( &m_StorageList);
	// Get Sound Devices
	myPC->getSoundDevices( &m_SoundList);
	// Get Modems
	myPC->getModems( &m_ModemList);
	// Get network adapter(s) hardware and IP informations
	myPC->getNetworkAdapters( &m_NetworkList);
	// Get Printer(s) informations
	myPC->getPrinters( &m_PrinterList);
	// Get Video adapter(s) informations
	myPC->getVideoAdapters( &m_VideoList);
	myPC->getMonitors( &m_MonitorList);
	// Get the primary local IP Address 
	m_csIPAddress = myPC->getLocalIP();
	// Get Windows registration infos
	myPC->getWindowsRegistration( m_csWinRegCompany, m_csWinRegOwner, m_csWinRegProductID);
	// Get apps from registry
	myPC->getRegistryApplications( &m_SoftwareList, hkcu);
	return TRUE;
}

BOOL CDeviceProperties::ParseFromCSV(CString &csCSV)
{
	CString		csBuffer = csCSV,
				csTemp,
				csData;
	int			nPos;

	// Read Device netbios Name
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csDeviceName = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read OS Name
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csOSName = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read OS Version
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csOSVersion = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read OS Comment
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csOSComment = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read processor type
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csProcessorType = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read processor speed
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csProcessorSpeed = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read number of processors
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	csData = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	m_dwNumberOfProcessor = _tcstoul( csData, NULL, 10);
	// Read physical memory
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	csData = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	m_ulPhysicalMemory = _tcstoul( csData, NULL, 10);
	// Read paging file
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	csData = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	m_ulSwapSize = _tcstoul( csData, NULL, 10);
	// Read IP address
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csIPAddress = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read execution duration
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csExecutionDuration = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read last check date
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csLastCheckDate = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read logged on user
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csLoggedOnUser = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read device type
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	csTemp = csBuffer.Left( nPos);
	m_uType = _tcstoul( csBuffer, NULL, 10);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read computer description
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csDescription = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read device UID
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csDeviceID = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read the domain or workgroup
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csDomain = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read windows registered company
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csWinRegCompany = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read windows registered owner
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csWinRegOwner = csBuffer.Left( nPos);
	csTemp = csBuffer.Mid( nPos + 1);
	csBuffer = csTemp;
	// Read windows product ID
	if ((nPos = csBuffer.Find(_T( ";"))) == -1)
		return FALSE;
	m_csWinRegProductID = csBuffer.Left( nPos);
	return TRUE;
}

BOOL CDeviceProperties::FormatXML(CMarkup* pX)
{
		
	pX->AddElem("HARDWARE");
	pX->IntoElem();
		pX->AddElemNV("NAME",m_csDeviceName);
		pX->AddElemNV("WORKGROUP",m_csDomain);
		pX->AddElemNV("OSNAME",m_csOSName);
		pX->AddElemNV("OSVERSION",m_csOSVersion);
		pX->AddElemNV("OSCOMMENTS",m_csOSComment);
		pX->AddElemNV("PROCESSORT",m_csProcessorType);
		pX->AddElemNV("PROCESSORS",m_csProcessorSpeed);
		pX->AddElemNV("PROCESSORN",m_dwNumberOfProcessor);
		pX->AddElemNV("MEMORY",m_ulPhysicalMemory);
		pX->AddElemNV("SWAP",m_ulSwapSize);
		pX->AddElemNV("IPADDR",m_csIPAddress);
		pX->AddElemNV("ETIME",m_csExecutionDuration);
		pX->AddElemNV("LASTDATE",m_csLastCheckDate);
		pX->AddElemNV("USERID",m_csLoggedOnUser);
		pX->AddElemNV("TYPE",m_uType);
		pX->AddElemNV("DESCRIPTION",m_csDescription);
		pX->AddElemNV("WINCOMPANY",m_csWinRegCompany);
		pX->AddElemNV("WINOWNER",m_csWinRegOwner);
		pX->AddElemNV("WINPRODID",m_csWinRegProductID);
	pX->OutOfElem();
	return TRUE;

}