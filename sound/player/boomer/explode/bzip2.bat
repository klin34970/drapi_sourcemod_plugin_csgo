@Echo Off
:Start
If [%1==[ Goto :EOF
PushD %~pd1
"C:\Program Files (x86)\7-Zip\7z.exe" u -tbzip2 -mx9 %1.bz2 %1
Shift
PopD
Goto Start