//
// TOSMBConstants.m
// Copyright 2015-2016 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#import "TOSMBConstants.h"
#import "netbios_defs.h"
#import "smb_defs.h"

NSString * const TOSMBClientErrorDomain = @"TOSMBClient";

TONetBIOSNameServiceType TONetBIOSNameServiceTypeForCType(char type)
{
    switch (type) {
        default:
        case NETBIOS_WORKSTATION:   return TONetBIOSNameServiceTypeWorkStation;
        case NETBIOS_MESSENGER:     return TONetBIOSNameServiceTypeMessenger;
        case NETBIOS_FILESERVER:    return TONetBIOSNameServiceTypeFileServer;
        case NETBIOS_DOMAINMASTER:  return TONetBIOSNameServiceTypeDomainMaster;
    }
}

char TONetBIOSNameServiceCTypeForType(char type)
{
    switch (type) {
        default:
        case TONetBIOSNameServiceTypeWorkStation:   return NETBIOS_WORKSTATION;
        case TONetBIOSNameServiceTypeMessenger:     return NETBIOS_MESSENGER;
        case TONetBIOSNameServiceTypeFileServer:    return NETBIOS_FILESERVER;
        case TONetBIOSNameServiceTypeDomainMaster:  return NETBIOS_DOMAINMASTER;
    }
}

NSString *localizedStringForErrorCode(TOSMBSessionErrorCode errorCode)
{
    NSString *errorMessage;
    
    switch (errorCode) {
        case TOSMBSessionErrorNotOnWiFi:
            errorMessage = @"Device isn't on a WiFi network.";
            break;
        case TOSMBSessionErrorCodeUnableToResolveAddress:
            errorMessage = @"Unable to resolve device address.";
            break;
        case TOSMBSessionErrorCodeUnableToConnect:
            errorMessage = @"Unable to connect to device.";
            break;
        case TOSMBSessionErrorCodeAuthenticationFailed:
            errorMessage = @"Login authentication failed.";
            break;
        case TOSMBSessionErrorCodeShareConnectionFailed:
            errorMessage = @"Unable to connect to share.";
            break;
        case TOSMBSessionErrorCodeFileNotFound:
            errorMessage = @"Unable to locate file.";
            break;
        case TOSMBSessionErrorCodeDirectoryDownloaded:
            errorMessage = @"Unable to download a directory.";
            break;
        case TOSMBSessionErrorCodeFileReadFailed:
            errorMessage = @"Read failed - check your connection.";
            break;
        case TOSMBSessionErrorCodeUnknown:
        default:
            errorMessage = @"Unknown Error Occurred.";
            break;
    }
    
    return NSLocalizedString(errorMessage, @"");
}



NSString * localizedStatusCode(uint32_t status)
{
    NSString *statusString = @"Undefined";
    if (status == NT_STATUS_SUCCESS)
    {
        statusString = @"Success";
    }
    else if (status == NT_STATUS_INVALID_SMB)
    {
        statusString = @"Invalid SMB";
    }
    else if (status == NT_STATUS_SMB_BAD_TID)
    {
        statusString = @"Invalid share ID";
    }
    else if (status == NT_STATUS_SMB_BAD_UID)
    {
        statusString = @"Bad UID";
    }
    else if (status == NT_STATUS_NOT_IMPLEMENTED)
    {
        statusString = @"Not implemented";
    }
    else if (status == NT_STATUS_INVALID_DEVICE_REQUEST)
    {
        statusString = @"Invalid device request";
    }
    else if (status == NT_STATUS_NO_SUCH_DEVICE)
    {
        statusString = @"No such device";
    }
    else if (status == NT_STATUS_NO_SUCH_FILE)
    {
        statusString = @"No such file";
    }
    else if (status == NT_STATUS_MORE_PROCESSING_REQUIRED)
    {
        statusString = @"More processing requaired";
    }
    else if (status == NT_STATUS_INVALID_LOCK_SEQUENCE)
    {
        statusString = @"Invalid lock sequence";
    }
    else if (status == NT_STATUS_INVALID_VIEW_SIZE)
    {
        statusString = @"Invalid view size";
    }
    else if (status == NT_STATUS_ALREADY_COMMITTED)
    {
        statusString = @"Already commited";
    }
    else if (status == NT_STATUS_ACCESS_DENIED)
    {
        statusString = @"Access denied";
    }
    else if (status == NT_STATUS_OBJECT_NAME_NOT_FOUND)
    {
        statusString = @"Object name not found";
    }
    else if (status == NT_STATUS_OBJECT_NAME_COLLISION)
    {
        statusString = @"Object name collision";
    }
    else if (status == NT_STATUS_OBJECT_PATH_INVALID)
    {
        statusString = @"Object path invalid";
    }
    else if (status == NT_STATUS_OBJECT_PATH_NOT_FOUND)
    {
        statusString = @"Object path not found";
    }
    else if (status == NT_STATUS_OBJECT_PATH_SYNTAX_BAD)
    {
        statusString = @"Bad object path syntax";
    }
    else if (status == NT_STATUS_PORT_CONNECTION_REFUSED)
    {
        statusString = @"Connection refused";
    }
    else if (status == NT_STATUS_THREAD_IS_TERMINATING)
    {
        statusString = @"Tread is terminated";
    }
    else if (status == NT_STATUS_DELETE_PENDING)
    {
        statusString = @"Delete pending";
    }
    else if (status == NT_STATUS_PRIVILEGE_NOT_HELD)
    {
        statusString = @"Privilege not held";
    }
    else if (status == NT_STATUS_LOGON_FAILURE)
    {
        statusString = @"Logon failure";
    }
    else if (status == NT_STATUS_DFS_EXIT_PATH_FOUND)
    {
        statusString = @"DFS exit path found";
    }
    else if (status == NT_STATUS_MEDIA_WRITE_PROTECTED)
    {
        statusString = @"Media write protected";
    }
    else if (status == NT_STATUS_ILLEGAL_FUNCTION)
    {
        statusString = @"Illigal function";
    }
    else if (status == NT_STATUS_FILE_IS_A_DIRECTORY)
    {
        statusString = @"File is directory";
    }
    else if (status == NT_STATUS_FILE_RENAMED)
    {
        statusString = @"File renamed";
    }
    else if (status == NT_STATUS_REDIRECTOR_NOT_STARTED)
    {
        statusString = @"Redirector not started";
    }
    else if (status == NT_STATUS_DIRECTORY_NOT_EMPTY)
    {
        statusString = @"Directory not empty";
    }
    else if (status == NT_STATUS_PROCESS_IS_TERMINATING)
    {
        statusString = @"Process is terminating";
    }
    else if (status == NT_STATUS_TOO_MANY_OPENED_FILES)
    {
        statusString = @"Too many opened files";
    }
    else if (status == NT_STATUS_CANNOT_DELETE)
    {
        statusString = @"Cannot delete";
    }
    else if (status == NT_STATUS_FILE_DELETED)
    {
        statusString = @"File deleted";
    }
    else if (status == NT_STATUS_INSUFF_SERVER_RESOURCES)
    {
        statusString = @"Insuff server resources";
    }
    return statusString;
}

NSError *errorForErrorCode(TOSMBSessionErrorCode errorCode)
{
    return [NSError errorWithDomain:@"TOSMBClient" code:errorCode userInfo:@{NSLocalizedDescriptionKey:localizedStringForErrorCode(errorCode)}];
}
