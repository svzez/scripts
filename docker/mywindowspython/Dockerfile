FROM microsoft/powershell:latest
ADD https://aka.ms/nugetclidl c:\\buildtemp\\nuget.exe
ADD configurePython.ps1 c:\\buildtemp\\configurePython.ps1
RUN c:\buildtemp\nuget.exe install python -OutputDirectory C:\python
RUN ["powershell.exe", "-executionpolicy", "bypass", "c:\\buildtemp\\configurePython.ps1"]
CMD powershell
