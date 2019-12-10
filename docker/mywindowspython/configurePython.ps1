# Get the path where python.exe is located
$pythonPath = (Get-ChildItem `
    -Path C:\Python `
    -Filter python.exe `
    -Recurse | Select-Object -ExpandProperty DirectoryName)

$pythonPath | ForEach-Object {
    $dllLocation = Get-ChildItem -Path $_ -Filter *.dll
    if ($dllLocation) {
        $env:Path += "$_;$_\Scripts"
    }
}

& SETX PATH $env:Path /M
& python -m pip install -U pip
& python -m pip install requests
