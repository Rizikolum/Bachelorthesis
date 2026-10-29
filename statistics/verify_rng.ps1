$cnt = 5000
$cntinner = 5000
$experiments = $cnt * $cntinner
$critval = 1.96
$mean = 0.5

$rng_mean = 0
for ($i = 0; $i -lt $cnt; $i++) {
    $rng = [System.Random]::new($i)
    for ($j = 0; $j -lt $cntinner; $j++) {
        $rng_mean += $rng.NextDouble()
    }
}
$rng_mean = $rng_mean / ($cnt*$cntinner)
Write-Host "Durchschnitt für $experiments Ziehungen: $rng_mean"

$rng_stderr = [Math]::Sqrt(3)/6/[Math]::sqrt($experiments)

$lo = $rng_mean - $critval * $rng_stderr
$hi = $rng_mean + $critval * $rng_stderr
$z = ($rng_mean-$mean)/$rng_stderr

Write-host "$lo <= $mean <= $hi = $($mean -ge $lo -and $mean -le $hi)"
Write-host "z: "$([Math]::abs($z))

##########################################################
# Durchschnitt für 25000000 Ziehungen: 0.500024006744686 #
# 0.499910846091925 <= 0.5 <= 0.500137167397447 = True   #
# z:  0,415809015207753                                  #
##########################################################