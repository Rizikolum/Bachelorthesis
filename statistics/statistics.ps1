param (
 [string]$msgcontent = "01001000011001010110110001101100011011110010000001010111011011110111001001101100011001000011000100110010001100110010000100111111", #Hello World123!?
 [double]$errorrate = 0,
 [double]$p_gb = 0.04,
 [double]$p_bg = 0.2,
 [double]$b_err = 0.6,
 [double]$del = 0.0,
 [double] $pg = $p_bg/($p_bg+$p_gb),
 [double] $pb = $p_gb/($p_bg+$p_gb),
 [double] $pne = (1-$errorrate-$del)*$pg + (1-$b_err-$del)*$pb,
 [double] $pe = $errorrate*$pg+$b_err*$pb,
 [double] $pdel = $del,
 [double] $ble = 1/$p_bg, #burstlength
 [string] $table = '.\lookup_tables\lookup_table(6,6,3).csv',
 [string] $table_0 = '.\lookup_tables\lookup_table(26,14,10).csv', # swtc 1
 [string] $table_1 = '.\lookup_tables\lookup_table(26,14,16).csv', # swtc 2
 [string] $table_2 = '.\lookup_tables\lookup_table(10,10,5).csv', # ks
 [boolean] $interleave = $true,
 [int] $cnt = 500
)

$str_swtc = @()
$str_ks = @()
$str_comp_lower = [System.Collections.Generic.List[int]]::new()
$str_comp_upper = [System.Collections.Generic.List[int]]::new()

#regex n, d, w, k, m
if ($table -match '.*\((\d+),(\d+),(\d+)\).*') {
 $size_ = [int]::Parse($Matches[1])
 $dist_ = [int]::Parse($Matches[2])
 $weight_ = [int]::Parse($Matches[3])
}
if ($table_0 -match '.*\((\d+),(\d+),(\d+)\).*') {
 $size0 = [int]::Parse($Matches[1])
 $dist0 = [int]::Parse($Matches[2])
 $weight0 = [int]::Parse($Matches[3])
}
if ($table_1 -match '.*\((\d+),(\d+),(\d+)\).*') {
 $size1 = [int]::Parse($Matches[1])
 $dist1 = [int]::Parse($Matches[2])
 $weight1 = [int]::Parse($Matches[3])
}
if ($table_2 -match '.*\((\d+),(\d+),(\d+)\).*') {
 $size_ks = [int]::Parse($Matches[1])
 $dist_ks = [int]::Parse($Matches[2])
 $weight_ks = [int]::Parse($Matches[3])
}

# run the encoding only once instead on each loop
$encode_swtc =    .\SWTC\encode_swtc.ps1 -content $msgcontent -interleave $interleave -table $table -table_0 $table_0 -table_1 $table_1 
$encode_ks =      .\KS\encode_ks.ps1     -content $msgcontent -interleave $interleave -table $table_2
$comparisoncodes = .\codeselect\comparisoncode_setdata.ps1 -payloadlength $msgcontent.length -p $pe -zbase 1.64
$comp_lower_errortolerance = $comparisoncodes.lowerbound.d / 2 -1
$comp_upper_errortolerance = $comparisoncodes.upperbound.d / 2 -1
$codeword_lower = '0' * $comparisoncodes.lowerbound.n
$codeword_upper = '0' * $comparisoncodes.upperbound.n
$encodelength_swtc = $encode_swtc.encoded.length
$encodelength_ks   = $encode_ks.encoded.length

# calculate expected errors
$ee_swtc     = $pe*$encodelength_swtc #SWTC Expected Errors
$edel_swtc   = $del*$encodelength_swtc #SWTC Expected Erasures
$ee_ks       = $pe * $encodelength_ks #KS Expected Errors
$edel_ks     = $del*$encodelength_ks #KS Expected Erasures

$ee_comp_l   = $pe * $comparisoncodes.lowerbound.n #Comparison lowerbound
$edel_comp_l = $del * $comparisoncodes.lowerbound.n  #Comparison lowerbound
$ee_comp_u   = $pe * $comparisoncodes.upperbound.n #Comparison upperbound
$edel_comp_u = $del * $comparisoncodes.upperbound.n  #Comparison upperbound

#parameters for the main runs
$baseparam = @{
 msgcontent = $msgcontent;
 errorrate = $errorrate;
 p_gb  = $p_gb;
 p_bg  = $p_bg;
 b_err = $b_err;
 del   = $del;
 interleave = $interleave
 }

# run the code with a new seed on each run, then compare the result to the original message
for ($x = 0; $x -lt $cnt; $x++) {
    $result_swtc = .\SWTC\main_swtc.ps1 @baseparam -encode $encode_swtc -table $table -table_0 $table_0 -table_1 $table_1 -seed $x
    $result_ks   = .\KS\main_ks.ps1     @baseparam -encode $encode_ks -table $table_2 -seed $x
    #$result_comp = .\comparison\main.ps1 @baseparam -seed $x
    $result_comp_lower = .\channel.ps1 -seed $x -in $codeword_lower -p_gb $p_gb -p_bg $p_bg -errorrate $errorrate -b_err $b_err -del $del
    $result_comp_upper = .\channel.ps1 -seed $x -in $codeword_upper -p_gb $p_gb -p_bg $p_bg -errorrate $errorrate -b_err $b_err -del $del
    $stats_swtc = .\compare.ps1 -a $($result_swtc.decoded.binary) -b $($encode_swtc.encoded)
    $stats_ks   = .\compare.ps1 -a $($result_ks.decoded.binary)   -b $($encode_ks.encoded)
    #$result_swtc.decoded.text = .\source_decoding.ps1 -binaryStr $($result_swtc.decoded.text) - would decode the text if we did send any
    #$result_ks.decoded.text   = .\source_decoding.ps1 -binaryStr $($result_ks.decoded.text) - would decode the text if we did send any
    $result_swtc | Add-Member -NotePropertyName "comp" -NotePropertyValue $stats_swtc
    $result_ks   | Add-Member -NotePropertyName "comp" -NotePropertyValue $stats_ks
    $str_swtc += $result_swtc
    $str_ks   += $result_ks
    $str_comp_lower.Add($result_comp_lower.errors)
    $str_comp_upper.Add($result_comp_upper.errors)
}

#check if the sample size was big enough
$eval = .\statistics\evaluate_monte_carlo.ps1 -str_swtc $str_swtc -str_ks $str_ks -ee_swtc $ee_swtc -ee_ks $ee_ks

# checks each run and counts errors
$brokenresults_swtc = 0
$brokenresults_ks = 0
$brokenresults_lower = 0
$brokenresults_upper = 0
$totalerrors_swtc = 0
$totalerrors_ks = 0
$swtc_errors = ''
$ks_errors = ''

for ($x = 0; $x -lt $cnt; $x++) {
 $fixed_swtc = $str_swtc[$x].decoded.fixed
 $fixed_ks   = $str_ks[$x].decoded.fixed
 if ($($str_comp_lower[$x]) -gt $comp_lower_errortolerance) { $brokenresults_lower++ }
 if ($($str_comp_upper[$x]) -gt $comp_upper_errortolerance) { $brokenresults_upper++ }
 if ($($str_swtc[$x].comp.err) -eq $true) {
     $brokenresults_swtc++
     $swtc_errors += "`nswtc run: $x, seed: $($str_swtc[$x].received.seed), errors: $($str_swtc[$x].received.errors), detected: $fixed_swtc, longest burst: $($str_swtc[$x].received.longestburst), Errors: $($str_swtc[$x].comp.indexes.count/$str_swtc[$x].encoded.encoded.length), result: $($str_swtc[$x].decoded.text)"
 }
 if ($($str_ks[$x].comp.err) -eq $true) {
     $brokenresults_ks++
     $ks_errors+= "`nks run: $x, seed: $($str_ks[$x].received.seed), errors: $($str_ks[$x].received.errors), detected: $fixed_ks, longest burst: $($str_ks[$x].received.longestburst), Errors: $($str_ks[$x].comp.indexes.count/$str_ks[$x].encoded.encoded.length), result: $($str_ks[$x].decoded.text)"
 }
 $totalerrors_swtc += $str_swtc[$x].comp.indexes.count
 $totalerrors_ks += $str_ks[$x].comp.indexes.count
}
$resultingErrorRate_swtc = $totalerrors_swtc / ($cnt * $encode_swtc.encoded.length)
$resultingErrorRate_ks =   $totalerrors_ks   / ($cnt * $encode_ks.encoded.length)

#Comparison - Lowerbound
Write-Host "---------Comparison L`($($comparisoncodes.lowerbound.n),$($comparisoncodes.lowerbound.d),$($comparisoncodes.lowerbound.w)`)--------"
Write-host "expected Errors: $ee_comp_u, expected deletions: $edel_comp_u"
Write-host "Capacity: $($comparisoncodes.lowerbound.Capacity), Redundancy: $($comparisoncodes.lowerbound.redundancy)"
Write-Host "Coderate: $($comparisoncodes.lowerbound.Coderate)"
Write-Host "L: affected codewords: $brokenresults_lower / $cnt = $($brokenresults_lower / $cnt)`n"

# Capacity & Redundancy - Shoehammer Immink
$codecapacity_swtc = [Math]::log($encode_swtc.codesize,2)
$coderedundancy_swtc = $($encode_swtc.subwordlength) - $codecapacity_swtc
$totalcoderedundancy_swtc = $coderedundancy_swtc * $encode_swtc.controlwordcodelength
Write-host "--------SWTC C`($($encodelength_swtc),$dist0,$(($weight0+$weight1)/2*$encodelength_swtc/$encode_swtc.subwordlength)`)---------"
Write-host "CW: C`($size_,$dist_,$weight_`), 0: C`($size0,$dist0,$weight0`), 1: C`($size1,$dist1,$weight1`)"
Write-Host "expected Errors: $ee_swtc, expected deletions: $edel_swtc"
Write-Host "bits/subword: $codecapacity_swtc, redundancy/subword: $coderedundancy_swtc, total bits: $($encodelength_swtc-$totalcoderedundancy_swtc), total redundancy: $totalcoderedundancy_swtc" 
Write-Host "Coderate: $codecapacity_swtc / $($encode_swtc.subwordlength) = $($codecapacity_swtc/$encode_swtc.subwordlength) `(Subword`)"
#Write-Host "Coderate: $codecapacity_swtc * $($encode_swtc.controlwordcodelength) / $($encode_swtc.encoded.length) = $($codecapacity_swtc*$encode_swtc.controlwordcodelength/$encode_swtc.encoded.length) `(Concatenated`)"
Write-Host "Coderate: `($codecapacity_swtc * $($encode_swtc.controlwordcodelength) + $($encode_swtc.controlworddatalength)`) / $($encode_swtc.encoded.length) = $(($codecapacity_swtc*$encode_swtc.controlwordcodelength+$encode_swtc.controlworddatalength)/$encode_swtc.encoded.length) `(including Controlword`)"
Write-host "Confidence Interval: $($eval.swtc.confinterval)"
Write-Host "swtc: total bit error rate: $resultingErrorRate_swtc, affected codewords: $brokenresults_swtc / $cnt = $($brokenresults_swtc / $cnt)"

# Capacity & Redundancy - KS
$codecapacity_ks = [Math]::log($encode_ks.codesize,2)
$coderedundancy_ks = $($encode_ks.subwordlength) - $codecapacity_ks
$totalcoderedundancy_ks = $coderedundancy_ks * $($encodelength_ks/$encode_ks.subwordlength)
Write-host "`n---------KS C`($encodelength_ks,$dist_ks,$($weight_ks*$encodelength_ks/$encode_ks.subwordlength)`)--------"
Write-Host "2: C`($($size_ks),$($dist_ks),$($weight_ks)`)"
Write-Host "expected Errors: $ee_ks, expected deletions: $edel_ks"
Write-Host "bits/subword: $codecapacity_ks, redundancy/subword: $coderedundancy_ks, total bits: $($encodelength_ks-$totalcoderedundancy_ks), total redundancy: $totalcoderedundancy_ks" 
#Write-Host "Coderate: $codecapacity_ks / $($encode_ks.subwordlength) = $($codecapacity_ks/$encode_ks.subwordlength) `(Subword`)"
Write-Host "Coderate: $codecapacity_ks * $($encodelength_ks/$encode_ks.subwordlength) / $encodelength_ks = $($codecapacity_ks*($encodelength_ks/$encode_ks.subwordlength)/$encodelength_ks) `(Concatenated`)"
Write-Host "Confidence Interval: $($eval.ks.confinterval)"
Write-Host "ks:   total bit error rate: $resultingErrorRate_ks, affected codewords: $brokenresults_ks / $cnt = $($brokenresults_ks / $cnt)`n"

#Comparison - Upperbound
Write-Host "---------Comparison U`($($comparisoncodes.upperbound.n),$($comparisoncodes.upperbound.d),$($comparisoncodes.upperbound.w)`)--------"
Write-host "expected Errors: $ee_comp_u, expected deletions: $edel_comp_u"
Write-host "Capacity: $($comparisoncodes.upperbound.Capacity), Redundancy: $($comparisoncodes.upperbound.redundancy)"
Write-Host "Coderate: $($comparisoncodes.upperbound.Coderate)"
Write-Host "U: affected codewords: $brokenresults_upper / $cnt = $($brokenresults_upper / $cnt)"

return [PSCustomObject]@{str_swtc = $str_swtc; str_ks = $str_ks; channel_eval = $eval; swtc_errors = $swtc_errors; ks_errors = $ks_errors; comparisoncodes = $comparisoncodes}