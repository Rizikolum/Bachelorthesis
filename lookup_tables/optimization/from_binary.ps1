$x = Get-Content -AsByteStream -Path ".\lookup_table_A(7,6,15)_simple.bin"
[String] $line = ''
for ($i = 0; $i -lt $x.length; $i++) {
    if (($i + 1) % 4-eq 0 -and $i -ne 0) {
        $y = [Convert]::ToString($x[$i],2).PadLeft(8,'0').substring(0,3)
        $line += $y
        Add-Content -Path ".\lookup_table_(27,6,15)_simple.txt" -Value $line
        $line = ''
    } else {
        $y = [Convert]::ToString($x[$i],2).PadLeft(8,'0')
        $line += $y
    }
}

$x = Get-Content -AsByteStream -Path ".\lookup_table_(27,6,15)_short.bin"
[String] $binary = ''
for ($i = 0; $i -lt $x.length; $i++) {
    $word = [Convert]::ToString($x[$i],2).PadLeft(8,'0')
    $binary += $word
}
for ($i = 0; $i -lt $($binary.length-27); $i+= 27) {
    $out = $binary.substring($i, 27)
    Add-Content -Path ".\lookup_table_(27,6,15)_short.txt" -Value $out
}