param (
    [string]$content = "010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001",
    [string]$table = '.\lookup_tables\lookup_table_A(16,4,8).csv',
    [string]$table_0 = '.\lookup_tables\lookup_table_A(18,6,8).csv',
    [string]$table_1 = '.\lookup_tables\lookup_table_A(18,6,10).csv',
    [boolean]$interleave = $true
    )

$lookup_table = Import-Csv -Path "$table" -Delimiter ';'
$lookup_table_0 = Import-Csv -Path "$table_0" -Delimiter ';'
$lookup_table_1 = Import-Csv -Path "$table_1" -Delimiter ';'
$k = $lookup_table[0].code.length
$m = $lookup_table_0[0].code.length
$controldatalength = $lookup_table[0].data.length
$datalength = $lookup_table_0[0].data.length 

$binaryStr = $content
$bintext = $binaryStr
[string] $interleaved = ''
[string] $c = ''

function encode_data($block) {
    [string]$result = ''

    $padding = ''
    while ($block.length -lt ($controldatalength + $k * $datalength)) { 
        $block += '0' 
        $padding += '0'
    }

    #search the data column of the controlword table for the first bits of our message 
    $controlword_data = $block.Substring(0,$controldatalength)
    $controlword_code = $lookup_table.Where({$_.data -eq $controlword_data }, 'First').'code'
    #the first bits are already in the controlword, we no longer need to encode those
    $block = $block.Substring($controldatalength)
    #inserts ' ' after each subword to enable splitting in the following step
    for ($i = $datalength; $i -lt $block.Length; $i += ($datalength+1)) { $block = $block.Insert($i, ' ')}
    $binary = $block.split(' ')

    #search a subword for each position of the controlword, choosing from the respecting lookup-table
    for ($i = 0; $i -lt $k; $i++) {
        if($controlword_code[$i] -eq '0') { $result += $lookup_table_0.Where({ $_.'data' -eq $binary[$i] }, 'First').code } 
        else { $result += $lookup_table_1.Where({ $_.'data' -eq $binary[$i] }, 'First').code }
    }
    return [PSCustomObject] @{result = $result; padding = $padding}
}

#cut the binarystr into blocks of length n
$done = $false
while (!$done) {
    #binaryStr length > blockcapacity
    if($binaryStr.length -gt ($controldatalength + $k * $datalength)) {
        $subword = encode_data $binaryStr.substring(0, ($controldatalength + $k * $datalength))
        $binaryStr = $binaryStr.Substring($controldatalength + $k * $datalength)
    } else { #binaryStr length <= blockcapacity
        $subword = encode_data $binaryStr
        $done = $true
    }
    $c += $subword.result
    $bintext += $subword.padding
    if ($interleave -eq $true) { $interleaved += .\interleave.ps1 -c $subword.result -m $m }
}
return [PSCustomObject]@{
    encoded = $c
    interleaved = $interleaved
    text = $bintext
    datalength = $datalength
    subwordlength = $lookup_table_0[0].code.length
    codesize = $lookup_table_0.length
    controlworddatalength = $lookup_table[0].data.length
    controlwordcodelength = $lookup_table[0].code.length
}