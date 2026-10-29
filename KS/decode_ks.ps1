param (
    [string]$received = '001001100101101001001101000001011011001110000011001110001110000011001110001110001110110000000100101010110011001011010101001100001110001110110000001110110001001001001110000011001110001100111001000110000100110101010011001000011101110100000110010111101000000110000101110110000110010000111011001100100001110101',
    [string]$table = '.\lookup_tables\lookup_table(18,6,8).csv'
    )

$lookup_table = Import-Csv -Path "$table" -Delimiter ';'
$table_weight = (.\weight.ps1($lookup_table[0].code)+1)
$codelength = $lookup_table[0].code.length
[string]$binaryStr = '' #result gets stored here
[string]$encStr = ''
[int]$correctedErrors = 0
$decode_output = ''
$decode_data_output = ''
$decode_output = [string[]]@()

#checks the lookup table to incrementally find the closest candidate to the given word a
function find-closest($a) {
$best_dist = [int]::MaxValue
$best_idx = 0
 for ($i = 0; $i -lt $lookup_table.Length; $i++) {
        $candidate = $lookup_table[$i].'code'
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
    $out = [PSCustomObject]@{d = $best_dist; code = $lookup_table[$best_idx].code}
return $out
}

function decode_data($block) {
    #counts the number of changes
    $fixed = 0
    $candidate = find-closest $block
    $row = $lookup_table | Where-Object { $_.'code' -eq $candidate.code }
    $decode_data_output += "$block -> $($row.code) - fixed $($candidate.d) => $($row.data)`n"
    $fixed += $candidate.d #Increment found errors
    $ret = [PSCustomObject]@{data = $row.data; code = $row.code; fixed = $fixed; decode_data_output = $decode_data_output}
    return $ret
}

function recurse_fix_deletion {
    param(
       [string]$subword,
       [int] $missing,
       [System.Collections.Generic.HashSet[string]] $seen
       )
    if ($seen -eq $null) {
        $Seen = [System.Collections.Generic.HashSet[string]]::new()
    }
    if ($missing -eq 0) {
        [PSCustomObject]@{
            Code = $subword.substring(0, $codelength)
            Carry = $subword.substring($codelength)
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
        [int] $missing,
        [string] $subword
    )
    $best_dist = [int]::MaxValue
    $best_cd = $null
    $carry = $null
    $matchCache = @{}

    $candidates = recurse_fix_deletion -subword $subword -missing $missing
    foreach ($candidate in $candidates) {
        if (-not $matchCache.ContainsKey($candidate.code)) { $matchCache[$candidate.Code] = find-closest $candidate.code }
        $match = $matchCache[$candidate.code]
        if ($match.d -lt $best_dist) {
            $best_cd = $candidate.code
            $carry = $candidate.carry
            $best_dist = $match.d
            if ($best_dist -eq 0) {break}
        }
    }
    return [PSCustomObject]@{candidate = $best_cd; carry = $carry; dist = $best_dist}
}
#check for deletions by verifying a correct block length, not finished, does nothing if the block length is correct
if ($received.length % $codelength -ne 0) { 
    $deletions = $codelength - ($received.length % $codelength) 
    Write-Host "KS: at least $deletions deletion(s) detected"
    
    #work in progress
    while ($received.length % $codelength -ne 0) {
        $subwords = 
        for ($i = 0; $i -lt $received.length; $i+= $codelength) {
            $l = [Math]::Min($codelength, $received.length -$i)
            $received.substring($i, $l)
        }
        #check weights and try to guess where the errors are
        for ($i = 0; $i -lt $subwords.length; $i++) {
            $w = .\weight.ps1 $subwords[$i]
            #current subword is valid
            if ($(find-closest $subwords[$i]).d -eq 0) { continue }
            $missing = [Math]::abs($w-$table_weight)
            $prevbest = $null
            while ($best_cd.dist -ne 0)
            {
                $best_cd = $(fix -missing $missing -subword $subwords[$i])
                $missing = $missing + 1
                Write-host $subwords[$i] $best_cd
                if ($prevbest -eq $best_cd.dist -and $prevbest -ne $null) { break } # stops searching for an exact match because there might have been an error on top of a deletion
                $prevbest = $best_cd.dist
            }
            if ($i -lt $subwords.length-1) { $received = $received.substring(0,$i*$codelength) + $($best_cd.candidate) + $best_cd.carry + $received.substring(($i+1)*$codelength) 
            } else { $received = $received.substring(0,$i*$codelength) + $($best_cd.candidate) }

            $best_cd = $null
            break #starts over the for loop after a change because subwords moved
        }
    }
}

while ($received.length -ge $codelength) {
    $decode = decode_data $received.substring(0,$codelength)
    $decode_output += $decode.decode_data_output
    $binaryStr += $decode.data
    $encStr += $decode.code
    $correctedErrors += $decode.fixed
    $received = $received.substring($codelength)
}
return [PSCustomObject]@{binary = $encStr; text = $binaryStr; fixed = $correctedErrors; decode_output = $decode_output}