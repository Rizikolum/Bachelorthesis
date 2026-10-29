$x = Get-Content -Path ".\lookup_table_(27,6,15).txt"
for ($i = 0; $i -lt $x.length; $i++) {
    $1 = [Convert]::Tobyte($x[$i].Substring(0,8),2)
    $2 = [Convert]::Tobyte($x[$i].Substring(8,8),2)
    $3 = [Convert]::Tobyte($x[$i].Substring(16,8),2)
    $4 = [Convert]::Tobyte($x[$i].Substring(24).PadRight(8, '0'),2)
    [byte[]]$line = @($1,$2,$3,$4)
    Add-Content -AsByteStream -Path ".\lookup_table_(27,6,15)_simple.bin" -Value $line
}

$x = Get-Content -Raw -Path ".\lookup_table_(27,6,15)_oneline.txt"
for ($i = 0; $i -lt $x.length; $i+= 8) {
    $1 = [Convert]::ToByte($($x[$i]+$x[$i+1]+$x[$i+2]+$x[$i+3]+$x[$i+4]+$x[$i+5]+$x[$i+6]+$x[$i+7]),2)
    Add-Content -AsByteStream -Path ".\lookup_table_(27,6,15)_short.bin" -Value $1
}