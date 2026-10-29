param(
    [int] $payloadlength=96,
    [double] $p = 1/14,
    $zbase = 1.64
)
$z = $zbase # can be reduced if no lowerbound is found

$variancesingle = $p * (1-$p)
$comparisoncode_l = ''
$comparisoncode_u = ''
$c_l = $null
$c_u = $null

$codelength_l = $payloadlength + [Math]::Ceiling($payloadlength * $p)
while ($comparisoncode_l.capacity -lt $payloadlength) {
    $variancetotal_l = $codelength_l * $variancesingle
    $stdev_l = [Math]::Sqrt($variancetotal_l)

    $t_l = $z * $stdev_l + $p * $codelength_l
    $compare_d_l = 2*[Math]::ceiling($t_l) + 2
    $comparisoncode_l = .\codeselect\lowerbound -n $codelength_l -ee $([Math]::ceiling($t_l))
    $codelength_l++
    if ($comparisoncode_l.lowerbound -eq '0') {
        if($z -eq $zbase) { # tries lowering the expected error count once
            $z = 0
            $codelength_l--
        } else { break } # skips if called the second time
    }
    if ($codelength_l -gt (50*$payloadlength)) { #forces a stop if the only options would be coderates below 0,1
        $comparisoncode_l = ''
        break
    }
}
$codelength_u = $payloadlength + [Math]::Ceiling($payloadlength * $p)
while ($comparisoncode_u.capacity -lt $payloadlength) {
    $variancetotal_u = $codelength_u * $variancesingle
    $stdev_u = [Math]::Sqrt($variancetotal_u)

    $t_u = $zbase * $stdev_u + $p * $codelength_u
    $compare_d_u = 2*[Math]::ceiling($t_u) + 2
    $comparisoncode_u = .\codeselect\upperbound -n $codelength_u -ee $([Math]::ceiling($t_u))
    $codelength_u++
    if ($codelength_u -gt (50*$payloadlength)) { #forces a stop if the only options would be coderates below 0,1
        $comparisoncode_u = ''
        break
    }
}

$codelength_l -= 1
$coderate_l = $(([Math]::floor($comparisoncode_l.capacity)/$codelength_l).toString("0.000"))
if ($coderate_l -ne "0,000"){
    if ($z -ne $zbase) { $coderate_l += '*'}
    $c_l = [PSCustomObject]@{n = $codelength_l; d=$compare_d_l; w=$([Math]::Ceiling($codelength_l/2)); e = $t_l; capacity = $([Math]::floor($comparisoncode_l.capacity)); Redundancy = $($codelength_l-[Math]::floor($comparisoncode_l.capacity)); Coderate=$coderate_l}
}

$codelength_u -= 1
$coderate_u = $(([Math]::floor($comparisoncode_u.capacity)/$codelength_u).toString("0.000"))
if ($coderate_u -ne "0,000") {
    $c_u = [PSCustomObject]@{n = $codelength_u; d=$compare_d_u; w=$([Math]::Ceiling($codelength_u/2)); e = $t_u; capacity = $([Math]::floor($comparisoncode_u.capacity)); Redundancy = $($codelength_u-[Math]::floor($comparisoncode_u.capacity)); Coderate=$coderate_u}
}

return [PSCustomObject]@{
    lowerbound = $c_l
    upperbound = $c_u
}