'
'   File Hash monitoring script
'   Kevin Holman 
'   5/2016
'

Option Explicit
dim oArgs, filepath, paramHashes, oAPI, oBag, strCommand, oShell
dim strHashCmd, strHashLine, strHashOut, strHash, HashesArray, Hash, strMatch

'Accept arguments for the file path, and known good hashes in comma delimited format
  Set oArgs=wscript.arguments
  filepath = oArgs(0)
  paramHashes = oArgs(1)

'Load MOMScript API and PropertyBag function
  Set oAPI = CreateObject("MOM.ScriptAPI")
  Set oBag = oAPI.CreatePropertyBag()

'Log script event that we are starting task
  Call oAPI.LogScriptEvent("filehashcheck.vbs", 3322, 0, "Starting hashfile script with filepath: " & filepath & " with known good hashes: " & paramHashes)

'build the command to run for CertUtil
  strCommand = "%windir%\system32\certutil.exe -hashfile " & filepath

'Create the Wscript Shell object and execute the command
  Set oShell = WScript.CreateObject("WScript.Shell")
  Set strHashCmd = oShell.Exec(strCommand)

'Parse the output of CertUtil and output only on the line with the hash
  Do While Not strHashCmd.StdOut.AtEndOfStream
    strHashLine = strHashCmd.StdOut.ReadLine()
    If Instr(strHashLine, "SHA") Then
        'skip
    ElseIf Instr(strHashLine, "CertUtil") Then
	    'skip
    Else 
	  strHashOut = strHashLine
    End If
  Loop

'Remove spaces from the hash
  strHash = Replace(strHashOut, " ", "")

'Split the comma seperated hashlist parameter into an array
  HashesArray = split(paramHashes,",")

'Loop through the array and see if our file hash matches any known good hash
  For Each Hash in HashesArray
    'wscript.echo Hash
    If strHash = Hash Then
      'wscript.echo "Match found"
      Call oAPI.LogScriptEvent("filehashcheck.vbs", 3323, 0, "Good match found.  The file " & filepath & " was found to have hash " & strHash & " which was found in the supplied known good hashes: " & paramHashes)
      Call oBag.AddValue("Match","GoodHashFound")
      Call oBag.AddValue("CurrentFileHash",strHash)  	
      Call oBag.AddValue("FilePath",filepath)
      Call oBag.AddValue("GoodHashList",paramHashes)
      oAPI.Return(oBag)
      wscript.quit
    Else
      'wscript.echo "Match not found"
      strMatch = "missing"
    End If
  Next

'If we get to this part of the script a hash was not found.  Output a bad propertybag
  If strMatch = "missing" Then
    Call oAPI.LogScriptEvent("filehashcheck.vbs", 3324, 2, "This file " & filepath & " does not match any known good hashes.  It was found to have hash " & strHash & " which was NOT found in the supplied known good hashes: " & paramHashes)  
    Call oBag.AddValue("Match","HashNotFound")
    Call oBag.AddValue("CurrentFileHash",strHash)
    Call oBag.AddValue("FilePath",filepath)
    Call oBag.AddValue("GoodHashList",paramHashes)  
    oAPI.Return(oBag)
  End If

wscript.quit