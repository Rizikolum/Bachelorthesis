param (
    [string]$received,
    [string]$table = '.\lookup_tables\lookup_table_A(16,4,8).csv',
    [string]$table_0 = '.\lookup_tables\lookup_table_A(18,6,8).csv',
    [string]$table_1 = '.\lookup_tables\lookup_table_A(18,6,10).csv',
    [boolean]$interleave = $false
    )

$lookup_table = Import-Csv -Path "$table" -Delimiter ';'
$lookup_table_0 = Import-Csv -Path "$table_0" -Delimiter ';'
$lookup_table_1 = Import-Csv -Path "$table_1" -Delimiter ';'
$table_0_weight = .\weight.ps1 -str $($lookup_table_0[0].code)
$table_1_weight = .\weight.ps1 -str $($lookup_table_1[0].code)
$m = $lookup_table_0[0].code.length
$k = $lookup_table[0].code.length
$datalength = $lookup_table_0[0].data.length
[string]$binaryStr = '' #result gets stored here
[string]$encStr = ''
[int]$correctedErrors = 0
$decode_output = ''
$decode_data_output = ''
$decode_output = [string[]]@()

#checks the lookup tables to incrementally find the closest candidate to the given word a
function find-closest($a,$lookup) {
    $best_dist = [int]::MaxValue
    $best_idx = 0

    for ($i = 0; $i -lt $lookup.Length; $i++) {
            $candidate = $lookup[$i].'code'
            $d = 0
            for ($j = 0; $j -lt $a.Length; $j++) {
                if ($a[$j] -ne $candidate[$j]) {
                    $d++
                    if ($d -ge $best_dist) { break }
                }
            }
            if ($d -lt $best_dist) {
                $best_dist = $d
                $best_idx = $i
            }
            # if we find an exact match we can stop searching
            if ($best_dist -eq '0') { break }
    }
    $out = [PSCustomObject]@{d = $best_dist; code = $lookup[$best_idx].code}
    return $out
}

function decode_data($block) {
    $controlword_code = ''
    $fixed = 0
    #inserts whitespace to be able to split the words
    for ($i = $m; $i -lt $block.Length; $i += ($m+1)) { $block = $block.Insert($i, ' ')}
    $subwords = $block -split(' ')
    #$array = $subwords.Clone()
    $array = [object[]]::new($subwords.Length)

    #loops through all subwords
    for ($i = 0; $i -lt $subwords.length; $i++) {
        #we dont have to search both arrays if we find an exact match, if we search the correct table first we can skip a full array
        if ((.\weight.ps1 -str $subwords[$i]) -le $table_0_weight) {
            $candidate0 = find-closest $subwords[$i] $lookup_table_0
            if ($candidate0.d -eq 0) { $candidate1 = [PSCustomObject]@{d = $($table_1_weight - $table_0_weight)}}
            else { $candidate1 = find-closest $subwords[$i] $lookup_table_1}
        } else {
            $candidate1 = find-closest $subwords[$i] $lookup_table_1
            if ($candidate1.d -eq 0) { $candidate0 = [PSCustomObject]@{d = $($table_1_weight - $table_0_weight)}}
            else { $candidate0 = find-closest $subwords[$i] $lookup_table_0 }
        }

        if ($candidate0.d -le $candidate1.d) {
            $array[$i] = $lookup_table_0.Where({$_.code -eq $($candidate0.code) }, 'First') | Select-Object *
            $controlword_code += '0'
            $decode_data_output += "$($subwords[$i]) -> $($array[$i].code) - fixed $($candidate0.d) => $($array[$i].data)`n" #debug
            $fixed += $candidate0.d
        } else {
            $array[$i] = $lookup_table_1.Where({$_.code -eq $($candidate1.code) }, 'First') | Select-Object *
            $controlword_code += '1'
            $decode_data_output += "$($subwords[$i]) -> $($array[$i].code) - fixed $($candidate1.d) => $($array[$i].data)`n" #debug
            $fixed += $candidate1.d
        }
    }

    $decode_data_output += "expected controlword: $controlword_code`n" #debug
    $controlword_data = $lookup_table.Where({$_.code -eq $controlword_code }, 'First').'data'
    #controlword error correction if there is no exact match
    if ($controlword_data -eq $null) {
        $decode_data_output += "Controlword $controlword_code broken, Trying to fix`n" #debug
        $controlword_fixed_code = find-closest $controlword_code $lookup_table
        $controlword_data = $lookup_table.Where({$_.code -eq $controlword_fixed_code }, 'First').'data'
        $decode_data_output += "fixed Controlword: $($controlword_fixed_code.code) " #debug
        for ($i = 0; $i -lt $controlword_code.length; $i++) {
            # go through the fixed controlword and try to correct the wrong indices
            if ($controlword_code[$i] -ne $controlword_fixed_code.code[$i]) {
                #fix the wrong subword(s) that caused  the wrong controlword
                if ($controlword_fixed_code.code[$i] -eq '1') {
                    $array[$i] = $lookup_table_1.Where({$_.code -eq $((find-closest $subwords[$i] $lookup_table_1).code)}, 'First')| Select-Object *
                } else { 
                    $array[$i] = $lookup_table_0.Where({$_.code -eq $((find-closest $subwords[$i] $lookup_table_0).code)}, 'First')| Select-Object * 
                }
                $decode_data_output += "Position: $i $($subwords[$i]) -> $($array[$i].code) => $($array[$i].data)`n"#debug
            }
        }
    }
    $joinedCode = ($array | ForEach-Object { if ($_ -match 'code=([01]+)') { $matches[1] } }) -join ""
    $joinedData = ($array | ForEach-Object { if ($_ -match 'data=([01]+)') { $matches[1] } }) -join ""
    $ret = [PSCustomObject]@{data = $($controlword_data + $joinedData); code = $joinedCode; fixed = $fixed; decode_data_output = $decode_data_output}
    return $ret
}

<# incomplete, does nothing if del = 0
function recurse_fix_deletion {
    param(
       [string]$subword,
       [int] $missing,
       [System.Collections.Generic.HashSet[string]] $seen
       )
    if ($seen -eq $null) { $Seen = [System.Collections.Generic.HashSet[string]]::new() }
    if ($missing -eq 0) {
        [PSCustomObject]@{
            Code = $subword.substring(0, $m)
            Carry = $subword.substring($m)
        }
        return
    }
    foreach ($bit in '0','1') {
        for ($i = 0; $i -le $subword.length; $i++) {
             $candidate = $subword.substring(0, $i)+$bit+$subword.substring($i)

             if ($seen.add("$missing|$candidate")) {
                recurse_fix_deletion -subword $candidate -missing ($missing-1) -seen $seen
             }
        }
    }
}

function fix {
    param(
        [int] $missing0,
        [int] $missing1,
        [string] $subword
    )
    $best_dist = [int]::MaxValue
    $best_cd = $null
    $carry = $null
    if ($missing0 -lt $missing1) {
        $matchCache0 = @{}
        $candidates0 = recurse_fix_deletion -subword $subword -missing $missing0
        foreach ($candidate in $candidates0) {
            if (-not $matchCache0.ContainsKey($candidate.code)) { $matchCache0[$candidate.Code] = find-closest -a $($candidate.code) -sw_cw 0 }
            $match = $matchCache0[$candidate.code]
            if ($match.d -lt $best_dist) {
                $best_cd = $candidate.code
                $carry = $candidate.carry
                $best_dist = $match.d
                if ($best_dist -eq 0) {break}
            }
        }
    } else {
        $matchCache1 = @{}
        $candidates1 = recurse_fix_deletion -subword $subword -missing $missing1
        foreach ($candidate in $candidates1) {
            if (-not $matchCache1.ContainsKey($candidate.code)) { $matchCache1[$candidate.Code] = find-closest -a $candidate.code -sw_cw 1}
            $match = $matchCache1[$candidate.code]
            if ($match.d -lt $best_dist) {
                $best_cd = $candidate.code
                $carry = $candidate.carry
                $best_dist = $match.d
                if ($best_dist -eq 0) {break}
            }
        }
    }
    return [PSCustomObject]@{candidate = $best_cd; carry = $carry; dist = $best_dist}
}

#check if the block length is correct - incomplete, does nothing if del = 0
while ($received.length % ($m*$k) -ne 0) {
    $deletions = $m - ($received.length % $m) 
    Write-Host "SWTC: at least $deletions deletion(s) detected"
    #cave: interleaving / errors
    while ($received.length % ($m*$k) -ne 0) {
        $subwords = 
        for ($i = 0; $i -lt $received.length; $i+= $m) {
            $l = [Math]::Min($m, $received.length -$i)
            $received.substring($i, $l)
        }
        #check weights and try to guess error positions
        for ($i = 0; $i -lt $subwords.length; $i++) {
            $w = .\weight.ps1 -str $subwords[$i]

            #current subword is valid
            if ($(find-closest -a $subwords[$i] -sw_cw 0).d -eq 0) { continue } 
            elseif ($(find-closest -a $subwords[$i] -sw_cw 1).d -eq 0) { continue }

            $missing0 = [Math]::abs($w-$table_0_weight)
            $missing1 = [Math]::abs($w-($m-$table_0_weight))

            $prevbest = $null
            while ($best_cd.dist -ne 0)
            {
                $best_cd = $(fix -missing0 $missing0 -missing1 $missing1 -subword $subwords[$i])
                $missing0 = $missing + 1
                $missing1 = $missing + 1
                if ($prevbest -eq $best_cd.dist -and $prevbest -ne $null) { break } # stops searching for an exact match because there might have been an error on top of a deletion
                $prevbest = $best_cd.dist
            }
                
            if ($i -lt $subwords.length-1) { $received = $received.substring(0,$i*$m) + $($best_cd.candidate) + $best_cd.carry + $received.substring(($i+1)*$m) 
            } else { $received = $received.substring(0,$i*$m) + $($best_cd.candidate) }

            $best_cd = $null
            break #starts over the for loop after a change because subwords moved
        }
    }
}#>

#if multiple codewords arrive at the same time decodes each individually
$disinterleaved = ''
$tmp = ''
while ($received.length -ge ($m*$k)) {
    $tmp = $received.substring(0,$m*$k)
    if ($interleave) {
        $tmp = .\disinterleave.ps1 -wi $tmp -k $k
        $disinterleaved += $tmp
    }
    $decode = decode_data $tmp
    $decode_output += $decode.decode_data_output
    $binaryStr += $decode.data
    $encStr += $decode.code
    $correctedErrors += $decode.fixed
    $received = $received.substring($m*$k)
}

return [PSCustomObject]@{
    binary = $encStr
    disinterleaved = $disinterleaved
    text = $binaryStr
    fixed = $correctedErrors
    decode_output = $decode_output
}