$cnt = 5000 #5000
$testdata = '0' * 2048 #2048
$critval = 1.96 # Konfidenzintervall 95%

#Scenario 1
$errorrate_1 = 0.01
$b_err_1 = 0
$p_bg_1 = 1
$p_gb_1 = 0
$pg_1 = $p_bg_1/($p_bg_1+$p_gb_1)
$pb_1 = $p_gb_1/($p_bg_1+$p_gb_1)
$pe_1 = $errorrate_1*$pg_1+$b_err_1*$pb_1
$expected_1 = $pe_1 * $testdata.length 
$expected_total_1 = $expected_1 * $cnt
$totalerrors_1 = 0

#Scenario 2
$errorrate_2 = 0.05
$b_err_2 = 0.5
$p_gb_2 = 0.01
$p_bg_2 = 0.2
$pg_2 = $p_bg_2/($p_bg_2+$p_gb_2)
$pb_2 = $p_gb_2/($p_bg_2+$p_gb_2)
$pe_2 = $errorrate_2*$pg_2+$b_err_2*$pb_2
$expected_2 = $pe_2 * $testdata.length 
$expected_total_2 = $expected_2 * $cnt
$totalerrors_2 = 0

#Scenario 3
$errorrate_3 = 0
$b_err_3 = 0.6
$p_gb_3 = 0.04
$p_bg_3 = 0.2
$pg_3 = $p_bg_3/($p_bg_3+$p_gb_3)
$pb_3 = $p_gb_3/($p_bg_3+$p_gb_3)
$pe_3 = $errorrate_3*$pg_3+$b_err_3*$pb_3
$expected_3 = $pe_3 * $testdata.length 
$expected_total_3 = $expected_3 * $cnt
$totalerrors_3 = 0

for ($i = 0; $i -lt $cnt; $i++) {
    $result_1 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_1 -p_gb $p_gb_1 -p_bg $p_bg_1 -b_err $b_err_1
    $result_2 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_2 -p_gb $p_gb_2 -p_bg $p_bg_2 -b_err $b_err_2
    $result_3 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_3 -p_gb $p_gb_3 -p_bg $p_bg_3 -b_err $b_err_3
    $totalerrors_1 += $result_1.errors
    $totalerrors_2 += $result_2.errors
    $totalerrors_3 += $result_3.errors
}
$mean_1 = $totalerrors_1 / $cnt
$mean_2 = $totalerrors_2 / $cnt
$mean_3 = $totalerrors_3 / $cnt

$var_err_1 = 0
$var_err_2 = 0
$var_err_3 = 0

for ($i = 0; $i -lt $cnt; $i++) {
    $result_1 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_1 -p_gb $p_gb_1 -p_bg $p_bg_1 -b_err $b_err_1
    $result_2 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_2 -p_gb $p_gb_2 -p_bg $p_bg_2 -b_err $b_err_2
    $result_3 = .\channel.ps1 -in $testdata -seed $i -errorrate $errorrate_3 -p_gb $p_gb_3 -p_bg $p_bg_3 -b_err $b_err_3
    $var_err_1 += [Math]::Pow(($result_1.errors-$mean_1),2)
    $var_err_2 += [Math]::Pow(($result_2.errors-$mean_2),2)
    $var_err_3 += [Math]::Pow(($result_3.errors-$mean_3),2)    
}

$var_err_1 = 1/($cnt-1) * $var_err_1
$var_err_2 = 1/($cnt-1) * $var_err_2
$var_err_3 = 1/($cnt-1) * $var_err_3

$stdev_err_1 = [Math]::Sqrt($var_err_1)
$stdev_err_2 = [Math]::Sqrt($var_err_2)
$stdev_err_3 = [Math]::Sqrt($var_err_3)

$stderr_err1 = $stdev_err_1 / [Math]::Sqrt($cnt)
$stderr_err2 = $stdev_err_2 / [Math]::Sqrt($cnt)
$stderr_err3 = $stdev_err_3 / [Math]::Sqrt($cnt)

$lo_err1 = $mean_1 - $critval * $stderr_err1
$hi_err1 = $mean_1 + $critval * $stderr_err1
$lo_err2 = $mean_2 - $critval * $stderr_err2
$hi_err2 = $mean_2 + $critval * $stderr_err2
$lo_err3 = $mean_3 - $critval * $stderr_err3
$hi_err3 = $mean_3 + $critval * $stderr_err3

Write-host "ran $cnt simulations:`n"
Write-Host "Scenario 1:"
Write-Host "calculated`terror rate: $pe_1`nactual`t`terror rate: $($totalerrors_1/($cnt*$testdata.length))" 
Write-Host "expected mean: $expected_1`nreceived mean: $mean_1"
Write-Host "expected total: $expected_total_1`nreceived total: $totalerrors_1"
Write-host "Varianz: $var_err_1, Standardabweichung: $stdev_err_1, Standardfehler: $stderr_err1"
Write-host "$lo_err1 <= $expected_1 <= $hi_err1 = $($expected_1 -ge $lo_err1 -and $expected_1 -le $hi_err1)`n"

Write-Host "Scenario 2:"
Write-Host "calculated`terror rate: $pe_2`nactual`t`terror rate: $($totalerrors_2/($cnt*$testdata.length))" 
Write-Host "expected mean: $expected_2`nreceived mean: $mean_2"
Write-Host "expected total: $expected_total_2`nreceived total: $totalerrors_2"
Write-host "Varianz: $var_err_2, Standardabweichung: $stdev_err_2, Standardfehler: $stderr_err2"
Write-host "$lo_err2 <= $expected_2 <= $hi_err2 = $($expected_2 -ge $lo_err2 -and $expected_2 -le $hi_err2)`n"

Write-Host "Scenario 3:"
Write-Host "calculated`terror rate: $pe_3`nactual`t`terror rate: $($totalerrors_3/($cnt*$testdata.length))" 
Write-Host "expected mean: $expected_3`nreceived mean: $mean_3"
Write-Host "expected total: $expected_total_3`nreceived total: $totalerrors_3"
Write-host "Varianz: $var_err_3, Standardabweichung: $stdev_err_3, Standardfehler: $stderr_err3"
Write-host "$lo_err3 <= $expected_3 <= $hi_err3 = $($expected_3 -ge $lo_err3 -and $expected_3 -le $hi_err3)"

Write-host "1: $(($mean_1-$expected_1)/$stderr_err1)"
Write-host "2: $(($mean_2-$expected_2)/$stderr_err2)"
Write-host "3: $(($mean_3-$expected_3)/$stderr_err3)"

#######################################################################################################
# Scenario 1:
# calculated	error rate: 0.01
# actual		error rate: 0.00995205078125
# expected mean: 20.48
# received mean: 20.3818
# expected total: 102400
# received total: 101909
# Varianz: 20.0724432486499, Standardabweichung: 4.48022803534037, Standardfehler: 0.0633599925010252
# 20.257614414698 <= 20.48 <= 20.505985585302 = True
# t: -1.54987392080915
#
# Scenario 2:
# calculated	error rate: 0.0714285714285714
# actual		error rate: 0.071359375
# expected mean: 146.285714285714
# received mean: 146.144
# expected total: 731428.571428571
# received total: 730720
# Varianz: 272.250914182839, Standardabweichung: 16.500027702487, Standardfehler: 0.233345629563889
# 145.686642566055 <= 146.285714285714 <= 146.601357433945 = True
# t: -0.607314934413509
#
# Scenario 3:
# calculated	error rate: 0.1
# actual		error rate: 0.0996982421875
# expected mean: 204.8
# received mean: 204.182
# expected total: 1024000
# received total: 1020910
# Varianz: 829.319139827963, Standardabweichung: 28.7979016566826, Standardfehler: 0.407263830907672
# 203.383762891421 <= 204.8 <= 204.980237108579 = True
# t: -1.51744386095533
#######################################################################################################