// Document modified at : Friday, March 31, 2006 2:15:53 PM , by user : didier , from computer : SNOOPY-XP-PRO

//====================================================================================
// Open Computer and Software Inventory
// Copyleft Didier LIROULET 2006
// Web: http://ocsinventory.sourceforge.net

// This code is open source and may be copied and modified as long as the source
// code is always made freely available.
// Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
//====================================================================================

// OCSInventoryState.h: interface for the COCSInventoryState class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_OCSINVENTORYSTATE_H__6E5FC8FF_1785_4745_A1A0_D2BEC9248343__INCLUDED_)
#define AFX_OCSINVENTORYSTATE_H__6E5FC8FF_1785_4745_A1A0_D2BEC9248343__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

// To apply to checksum with an OR
#define OCS_LAST_STATE_FILE			_T( "last_state")
#define OCS_CHECKSUM_HARDWARE		1
#define OCS_CHECKSUM_BIOS			2
#define OCS_CHECKSUM_MEMORIES		4
#define OCS_CHECKSUM_SLOTS			8
#define OCS_CHECKSUM_REGISTRY		16
#define OCS_CHECKSUM_CONTROLLERS	32
#define OCS_CHECKSUM_MONITORS		64
#define OCS_CHECKSUM_PORTS			128
#define OCS_CHECKSUM_STORAGES		256
#define OCS_CHECKSUM_DRIVES			512
#define OCS_CHECKSUM_INPUTS			1024
#define OCS_CHECKSUM_MODEMS			2048
#define OCS_CHECKSUM_NETWORKS		4096
#define OCS_CHECKSUM_PRINTERS		8192
#define OCS_CHECKSUM_SOUNDS			16384
#define OCS_CHECKSUM_VIDEOS			32768
#define OCS_CHECKSUM_SOFTWARES		65536


class COCSInventoryState  
{
public: // Methods
	//////////////////////////////////
	// Standard contructor/destructor
	//////////////////////////////////
	COCSInventoryState();
	virtual ~COCSInventoryState();

	//////////////////////////////////
	// Get attributes values
	//////////////////////////////////
	LPCTSTR GetHardware();
	LPCTSTR GetBios();
	LPCTSTR GetMemories();
	LPCTSTR GetSlots();
	LPCTSTR GetRegistry();
	LPCTSTR GetControllers();
	LPCTSTR GetMonitors();
	LPCTSTR GetPorts();
	LPCTSTR GetStorages();
	LPCTSTR GetDrives();
	LPCTSTR GetInputs();
	LPCTSTR GetModems();
	LPCTSTR GetNetworks();
	LPCTSTR GetPrinters();
	LPCTSTR GetSounds();
	LPCTSTR GetVideos();
	LPCTSTR GetSoftwares();
	// Format informations in a XML string
	BOOL FormatXML( CMarkup* pX );

	//////////////////////////////////
	// Set attributes values
	//////////////////////////////////

	// Clear BIOS infos
	void Clear();
	// Read informations in a XML string
	BOOL ParseFromXML(CString &xml);
	void SetHardware( LPCTSTR lpstrValue);
	void SetBios( LPCTSTR lpstrValue);
	void SetMemories( LPCTSTR lpstrValue);
	void SetSlots( LPCTSTR lpstrValue);
	void SetRegistry( LPCTSTR lpstrValue);
	void SetControllers( LPCTSTR lpstrValue);
	void SetMonitors( LPCTSTR lpstrValue);
	void SetPorts( LPCTSTR lpstrValue);
	void SetStorages( LPCTSTR lpstrValue);
	void SetDrives( LPCTSTR lpstrValue);
	void SetInputs( LPCTSTR lpstrValue);
	void SetModems( LPCTSTR lpstrValue);
	void SetNetworks( LPCTSTR lpstrValue);
	void SetPrinters( LPCTSTR lpstrValue);
	void SetSounds( LPCTSTR lpstrValue);
	void SetVideos( LPCTSTR lpstrValue);
	void SetSoftwares( LPCTSTR lpstrValue);

protected:
	CString m_csHardware;
	CString m_csBios;
	CString m_csMemories;
	CString m_csSlots;
	CString m_csRegistry;
	CString m_csControllers;
	CString m_csMonitors;
	CString m_csPorts;
	CString m_csStorages;
	CString m_csDrives;
	CString m_csInputs;
	CString m_csModems;
	CString m_csNetworks;
	CString m_csPrinters;
	CString m_csSounds;
	CString m_csVideos;
	CString m_csSoftwares;
};

#endif // !defined(AFX_OCSINVENTORYSTATE_H__6E5FC8FF_1785_4745_A1A0_D2BEC9248343__INCLUDED_)
