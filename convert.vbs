' Launches convert.ps1 with no console window. Passes every argument through.
Dim a, i, tail, dir
Set a = WScript.Arguments
tail = ""
For i = 0 To a.Count - 1
    tail = tail & " """ & a(i) & """"
Next
dir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
CreateObject("WScript.Shell").Run _
    "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & dir & "\convert.ps1""" & tail, 0, False
