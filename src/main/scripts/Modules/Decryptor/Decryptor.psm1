
# ********************************************************************
# Ericsson Radio Systems AB                                     Module
# ********************************************************************
#
#
# (c) Ericsson Inc. 2015 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Inc. The programs may be used and/or copied only with
# the written permission from Ericsson Inc. or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : Decryptor.psm1
# Date    : 07/03/2015
# Revision: PA1
# Purpose : #  Decryption module for Ericsson Network Analytic Server
#
# ### Function: Decrypt-File ###
#
#   This function uses Rijndael .NET library to encrypt files.
#
# Arguments:
#   $fileName[string] the absolute path of the file to be decrypted.

# Return Values:
#   [list] - @($true|$false, [string] $message) 
#
#           
#

#---------------------------------------------------------------------------------

# The following parameter must match the parameters used in the encryption file.
# Password is the CXC number
$Script:password = "CXC4011993"
# Salt should be randomly generated and be the same as used in the decrypt function
$Script:salt = "NxCSfD^0XecvER"
# Init should be randomly generated and should be the same as used in the decrypt function
$Script:init = "7d49cr^aYa739gH%0rq@M3"

function Decrypt-File { 
    param (
    [Parameter(Mandatory=$true)][string]$encryptedFile
    )

    if (Test-Path $encryptedFile) {
        try {
            $rijndaelProvider = New-Object System.Security.Cryptography.RijndaelManaged

            #encode variables into UTF-8
            $pass = [Text.Encoding]::UTF8.GetBytes($password)
            $salt = [Text.Encoding]::UTF8.GetBytes($salt)

            # create key and vector for decryption
            $rijndaelProvider.Key = (New-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) 
            $rijndaelProvider.IV = (New-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]
	 
            $decryptor = $rijndaelProvider.CreateDecryptor()

            # Open a file input stream, initialise the decryption stream
            $inputFileStream = New-Object System.IO.FileStream($encryptedFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $decryptStream = New-Object Security.Cryptography.CryptoStream $inputFileStream, $decryptor, "Read"
    
            #Read in the decrypted file and store in the contents in the $inputFileData buffer
            [int]$dataLen = $inputFileStream.Length
            [byte[]]$inputFileData = New-Object byte[] $dataLen

            try {
                [int]$decryptLength = $decryptStream.Read($inputFileData, 0, $dataLen)
            } catch {
                return @($False, "Error with the decryption procedure.")
            }

            $decryptStream.Close()
            $inputFileStream.Close()

            #output the decrypted contents to file
            $outputFileStream = New-Object System.IO.FileStream($encryptedFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            $outputFileStream.Write($inputFileData, 0, $decryptLength)
            $outputFileStream.Close()

            $rijndaelProvider.Clear()
            return @($True, "File decrypted succesfully.")
        } catch {
            return @($False, "Failed to decrypt the file.")
        }
    } else {
        return @($False, "File $encryptedFile not found.")
    }
}

Export-ModuleMember "Decrypt-File"