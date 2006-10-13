// ModuleIpdiscover.h: interface for the CModuleIpdiscover class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_MODULEIPDISCOVER_H__6FADA6D4_2076_47FC_9D2A_76E2A34DFDDC__INCLUDED_)
#define AFX_MODULEIPDISCOVER_H__6FADA6D4_2076_47FC_9D2A_76E2A34DFDDC__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "ModuleApi.h"
#include <Afxmt.h>
#include <Ws2tcpip.h>

class CModuleIpdiscover : public CModuleApi  
{
public: // privatiser


	CMarkup* pXmlResponse; // Prolog response from the server
	CMarkup* pMyXml;
	ULONG			 m_netNumber;
	ULONG			 m_hostFound;
	CCriticalSection m_cs;
	UINT			 m_currentIp;

	// CModuleIpdiscover constructor.
	// commandLine: command line
	CModuleIpdiscover(CString commandLine,CDeviceProperties * pC, CString serv, UINT prox, INTERNET_PORT port, CString http_user, CString http_pwd );

	// Function SendARP of IPHLPAPI.DLL (available on Windows 98 or higher and NT4 SP4 or higher)
	DWORD (WINAPI *lpfn_SendARP)(IPAddr DestIP, IPAddr SrcIP, PULONG pMacAddr, PULONG PhyAddrLen);
	// Functions from Winsock2
	u_long (WINAPI *lpfn_htonl)(u_long hostlong);
	u_long (WINAPI *lpfn_ntohl)(u_long netlong);
	unsigned long (WINAPI *lpfn_inet_addr)(const char* cp);
	char* FAR (WINAPI *lpfn_inet_ntoa)(struct in_addr in);

public:
	
	int response(CMarkup* pXml, CString* pRawResponse=NULL);
	int inventory(CMarkup* pXml, CDeviceProperties* pPc);	
	//UINT threadWork( LPVOID pParam ) ;

};

#endif // !defined(AFX_MODULEIPDISCOVER_H__6FADA6D4_2076_47FC_9D2A_76E2A34DFDDC__INCLUDED_)