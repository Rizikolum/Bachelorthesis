param (
    [double]$p = 0.1,
    [int] $encode = 128, #96 bit for "Hello World!"
    [double]$z = 1.64 # 3 for ~99.73% chance of a correct message
)

#
# loops through each distance table for the controlword to then check all distance tables again for the subwords
#

$variancesingle = $p * (1-$p)
$bestcw = [PSCustomObject]@{n = $null; d = $null; w = $null; data = $null; tdata = $null} #current best controlword
$bests1 = [PSCustomObject]@{n = $null; d = $null; w = $null; data = $null; tdata = $null} #current best subword1
$bestvalue = [double]::MinValue #Score

$tables = foreach ($d in 4, 6, 8, 10, 12, 14, 16, 18) {
    @{
        d     = $d
        table = Import-Csv ".\lookup_tables\d$d.csv" -Delimiter ';'
    }
}

#go through all distances for the controlword
for ($c = 0; $c -lt $tables.length; $c++) {
    $ccw = [PSCustomObject]@{n = $null; w = $null;d = $null; tdata = $null; data = $null;coderate = $null} #$ccw -> current controlword
    $ctable = $tables[$c].table # $ctable -> current controlword table
    $ccw.d = [int] $tables[$c].d

    #go through every w for the current controlword distance table
    for ($i = 0; $i -lt $ctable.length; $i++) {
        $ccw.n = [int] $ctable[$i].n

        #skips the current controlword if the amount of subwords is uneven (would produce weight issues)
        if ($ccw.n % 2 -ne 0) { continue }

        #go through every n for the current w
        for ($j = 3; $j -lt 35; $j++) {
			if ($ctable[$i].$j -ne '' -and $ctable[$i].$j -ne $null) {
				$ccw.tdata = [Math]::Log($([int] $ctable[$i].$j),2)
                $ccw.data = $([Math]::floor($ccw.tdata))
                $ccw.w = $j

                #calculates how many bits a single subword needs to encode
                $sdata = $(($encode-$ccw.data)/$ccw.n)
                
                #search cs1 in all distance tables, basically the same as for the controlword
                for ($s = 0; $s -lt $tables.length; $s++) {
					$cs1 = [PSCustomObject]@{n = $null; w = $null;d = $null; tdata = $null; data = $null;coderate = $null}
                    $stable = $tables[$s].table
                    $cs1.d = [int] $tables[$s].d

                    #search through every w for the current subword distance table
                    for($k = 0; $k -lt $stable.length; $k++) {
                        $cs1.n = [int] $stable[$k].n

                        #search through every n for the current w
                        for ($l = 0; $l -lt 35; $l++) {
                            if ($stable[$k].$l -ne '' -and $stable[$k].$l -ne $null) {
                                $cs1.tdata = $([Math]::Log($([int]$stable[$k].$l),2))
                                $cs1.data = $([Math]::floor($cs1.tdata))

                                #skips the current candidate if we cant fit enough data
                                if ($cs1.data -lt ($sdata)) { continue }

                                $cs1.w = $l

                                $smaxerror = ($cs1.d/2-1)

                                $variancetotal = $cs1.n * $variancesingle
                                $stdev = [Math]::Sqrt($variancetotal)
                                $t = $z * $stdev + $p * $cs1.n
                                $compare_d = 2*[Math]::ceiling($t) + 2

                                #ensure we can encode all data, dont use the same weight for s1 and s2 and can correct enough errors
                                if (($ccw.n * $cs1.data) -ge $($encode-$ccw.data) -and ($cs1.w -le $($cs1.n/2-1)) -and $($cs1.d -ge $compare_d)) {
                                    #we are certain our candidate encodes the data and error correction is fulfilled, so we focus on coderate
                                    $evalrate = 6*($encode/($cs1.n*$ccw.n))
									#encourages a higher distance s1<->s2 so we have to correct less via the controlword
                                    $dcs = 0.02*[Math]::abs($cs1.w-($cs1.n-$cs1.w))
                                    #even higher error correction capability is encouraged but not required
                                    $everr = 0.006*($smaxerror / $t)
                                    #any other parameters being equal - a higher distance in the controlword gives us more security
                                    $evalcwd = 0.001*$ccw.d

                                    $cvalue = $evalrate+$dcs+$everr+$evalcwd #current value

                                    if($cvalue -gt $bestvalue) {
                                        $bestvalue = $cvalue
                                        $bestcw.n = $ccw.n
                                        $bestcw.d = $ccw.d
                                        $bestcw.w = $ccw.w
                                        $bestcw.data = $ccw.data
                                        $bestcw.tdata = $ccw.tdata

                                        $bests1.n = $cs1.n
                                        $bests1.d = $cs1.d
                                        $bests1.w = $cs1.w
                                        $bests1.data = $cs1.data
                                        $bests1.tdata = $cs1.tdata
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
if ($bests1.n -eq $null) { 
    $bestcw.n = 0
    $bestcw.d = 0
    $bestcw.w = 0
    $bestcw.data = 0

    $bests1.n = 0
    $bests1.d = 0
    $bests1.w = 0
    $bests1.data = 0

    $bests2 = [PSCustomObject]@{n = $bests1.n; d = $bests1.d; w = $($bests1.n-$bests1.w); data = $bests1.data}
    return [PSCustomObject]@{cw = $bestcw; s1 = $bests1; s2 = $bests2; totalcoderate = 0; value = $bestvalue; theoreticalcoderate = 0 }
    } 
else {
    $bests2 = [PSCustomObject]@{n = $bests1.n; d = $bests1.d; w = $($bests1.n-$bests1.w); data = $bests1.data}
    return [PSCustomObject]@{cw = $bestcw; s1 = $bests1; s2 = $bests2; totalcoderate = $(($bestcw.data+$bestcw.n*$bests1.data)/($bests1.n*$bestcw.n)); value = $bestvalue.toString("0.000"); theoreticalcoderate = $(($bestcw.tdata+$bestcw.n*$bests1.tdata)/($bests1.n*$bestcw.n)) }
}