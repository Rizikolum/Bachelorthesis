param (
    [PSCustomObject] $str_swtc,
    [PSCustomObject] $str_ks,
    $ee_swtc,
    $ee_ks
)
#Konfidenzniveau 98.75%
$critval = 2.5

$cnt = $str_swtc.length

#empirsicher Mittelwert
$mean_swtc = 0.0
$mean_ks = 0.0
for ($i = 0; $i -lt $cnt; $i++) {
    $mean_swtc += $str_swtc[$i].received.errors
    $mean_ks += $str_ks[$i].received.errors
}
[double]$mean_swtc = $mean_swtc / $cnt
[double]$mean_ks = $mean_ks / $cnt

#empirische Varianz
$sqdev_swtc = 0.0
$sqdev_ks   = 0.0
for ($i = 0; $i -lt $cnt; $i++)
{
    $sqdev_swtc += [Math]::Pow(($str_swtc[$i].received.errors-$mean_swtc),2)
    $sqdev_ks   += [Math]::Pow(($str_ks[$i].received.errors-$mean_ks),2)
}
$var_swtc = $sqdev_swtc / ($cnt-1)
$var_ks =   $sqdev_ks   / ($cnt-1)

#empirische Standardabweichung
$stdev_swtc = [Math]::sqrt($var_swtc)
$stdev_ks = [Math]::sqrt($var_ks)

# standard error
$se_swtc = $stdev_swtc / [Math]::Sqrt($cnt)
$se_ks = $stdev_ks / [Math]::Sqrt($cnt)

# confidence intervals
$conflo_swtc = $mean_swtc - $critval * $se_swtc
$confhi_swtc = $mean_swtc + $critval * $se_swtc
$conflo_ks =   $mean_ks   - $critval * $se_ks
$confhi_ks =   $mean_ks   + $critval * $se_ks

Write-host "SWTC: $(($mean_swtc-$ee_swtc)/$se_swtc)"
Write-host "KS: $(($mean_ks-$ee_ks)/$se_ks)"

$conf_swtc = "$conflo_swtc <= $ee_swtc <= $confhi_swtc ($mean_swtc) $(($conflo_swtc -le $ee_swtc) -and ($confhi_swtc -ge $ee_swtc))"
$conf_ks =   "$conflo_ks <= $ee_ks <= $confhi_ks ($mean_ks) $(($conflo_ks -le $ee_ks) -and ($confhi_ks -ge $ee_ks))"

$swtc = [PSCustomObject]@{mean = $mean_swtc; variance = $var_swtc; stdeviation = $stdev_swtc; standarderror = $se_swtc; confinterval = $conf_swtc}
$ks = [PSCustomObject]@{mean = $mean_ks; variance = $var_ks; stdeviation = $stdev_ks; standarderror = $se_ks; confinterval = $conf_ks}
return [PSCustomObject]@{swtc = $swtc; ks = $ks}