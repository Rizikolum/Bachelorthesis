param (
    [string]$content = "010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001",
    [string]$table = '.\lookup_tables\lookup_table(9,4,6).csv'
    )

$lookup_table = Import-Csv -Path "$table" -Delimiter ';'
$datalength = $lookup_table[0].data.length #
$binaryStr = $content
[string] $c = $null

# ensure k = n / m - is divisible by two
$k = [Math]::ceiling($binaryStr.length / $datalength)

# pads the data to the next possible value
while ($binaryStr.length % $datalength -ne 0) { $binaryStr += '0' }

#cuts the binarystr into k equal subwords of length m and encodes them
for ($i = 0; $i -lt $k; $i++) {
    $c += $lookup_table.Where({$_.data -eq $binaryStr.substring(0, $datalength) }, 'First').code
    $binaryStr = $binaryStr.substring($datalength)
}

return [PSCustomObject]@{
    encoded = $c
    text = $content
    datalength = $datalength
    subwordlength = $lookup_table[0].code.length
    codesize = $lookup_table.length
    subwords = $k
}