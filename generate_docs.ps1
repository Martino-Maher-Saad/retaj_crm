$OutputFilePath = "d:\Flutter Projects\retaj_crm\FULL_PROJECT_DOCUMENTATION.md"
$BaseDir = "d:\Flutter Projects\retaj_crm\lib"

"# Retaj CRM - Full Project Documentation`n" | Out-File -FilePath $OutputFilePath -Encoding utf8

"## Directory Structure`n" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
"```text" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
Get-ChildItem -Path $BaseDir -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Substring($BaseDir.Length + 1)
    $indent = "  " * ($relativePath.Split('\').Count - 1)
    "$indent- $($_.Name)/" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
}
"````n" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8

"## Files & Classes Detailed Map`n" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8

Get-ChildItem -Path $BaseDir -Recurse -Filter *.dart | ForEach-Object {
    $relativePath = $_.FullName.Substring($BaseDir.Length + 1)
    "### File: `$relativePath`n" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
    "```dart" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
    
    $content = Get-Content $_.FullName -Raw
    
    # Simple regex to find classes, mixins, enums
    $matches = [regex]::Matches($content, "(?m)^(?:abstract\s+)?class\s+(\w+)(?:.*?)\{")
    foreach ($m in $matches) {
        "class $($m.Groups[1].Value)" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
    }
    
    $cubitMatches = [regex]::Matches($content, "(?m)class\s+(\w+Cubit)\s+extends\s+Cubit")
    foreach ($m in $cubitMatches) {
        "Cubit: $($m.Groups[1].Value)" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
    }

    $stateMatches = [regex]::Matches($content, "(?m)class\s+(\w+State)\s+")
    foreach ($m in $stateMatches) {
        "State: $($m.Groups[1].Value)" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
    }
    
    $methodMatches = [regex]::Matches($content, "(?m)^\s*(?:Future<[\w\s<>]+>|void|[\w<>]+)\s+(\w+)\s*\([^)]*\)\s*(?:async)?\s*\{")
    foreach ($m in $methodMatches) {
        if ($m.Groups[1].Value -ne "build" -and $m.Groups[1].Value -ne "initState" -and $m.Groups[1].Value -ne "dispose" -and $m.Groups[1].Value -ne "toJson" -and $m.Groups[1].Value -ne "fromJson") {
             "  - Method: $($m.Groups[1].Value)" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
        }
    }

    "````n" | Out-File -FilePath $OutputFilePath -Append -Encoding utf8
}
