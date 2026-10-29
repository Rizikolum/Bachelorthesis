param (
    [string]$binaryStr = "010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001",
    $iso = [System.Text.Encoding]::GetEncoding(28591), #default is iso-8859-1
    $datalength = 8 # iso-8859-1 is 8-bit
)

#translate back - adds whitespace after each subword, then converts to Integer
for ($i = $datalength; $i -lt $binaryStr.Length; $i += ($datalength+1)) { $binaryStr = $binaryStr.Insert($i, ' ')}
$binaryArr = $binaryStr.split(' ')

for ($i = 0; $i -lt $binaryArr.Length; $i++) { if ($binaryArr[$i].Length -eq $datalength) { $binaryArr[$i] = [Convert]::ToInt32($binaryArr[$i], 2) } }

$bytes = foreach ($value in $binaryArr) {
    try { [byte]$value }
    catch {
        Write-Warning "Invalid byte value: '$value'"
        32
    }
}
$out = $iso.GetString([byte[]]$bytes)
return $out