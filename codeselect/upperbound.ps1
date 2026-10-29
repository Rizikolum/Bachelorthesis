param(
        [int]$n = 96,
        [int]$ee = 3,
        [int]$w = 0
)
$upperbound = $null
$upperbound_capacity = $null
$upperbound_redundancy = $null

if ($w -eq 0) { $w = [Math]::ceiling($n/2) }
Add-Type -AssemblyName System.Numerics
$d = $ee * 2 + 2

# returns x!
function factorial {
    param([int] $x = 10)
    if ($x -eq 0) { return 1}
    [System.Numerics.BigInteger]$factorial = $x
    for ($i = $x-1; $i -gt 1; $i--) { $factorial *= $i }
    return $factorial
}

# returns n over w
function binom {
    param (
    [long]$n = 16,
    [long]$w = 8
    )
    return $((factorial $n)/((factorial $w) * $(factorial $($n-$w))))
}

#hammingbound
try {  
    $e = [Math]::floor(0.5*($d-1))
    [System.Numerics.BigInteger] $divisor = 0
    for ($i = 0; $i -le $e; $i++) { $divisor += $(binom -n $n -w $i) }

    [System.Numerics.BigInteger] $hammingbound = [Math]::pow(2,$n) / $divisor
    $hammingbound_capacity = [Math]::Log($hammingbound,2)
    $hammingbound_redundancy = $n - $hammingbound_capacity
} catch { $_ }

#johnson unrestricted
try{
    $e = $ee+1
    $johnsonbound_unrestricted = [System.Numerics.BigInteger]::One

    # d > 2w
    if ($d -le 2*$w) { 
        $nBig = [System.Numerics.BigInteger]$n
        $wBig = [System.Numerics.BigInteger]$w

        for ($i = ($w - $e); $i -ge 0; $i--) {
            $iBig = [System.Numerics.BigInteger]$i
            $dividend = ($nBig - $iBig)
            $divisor = $wBig - $iBig
            $johnsonbound_unrestricted = [System.Numerics.BigInteger]::Divide($dividend,$divisor) * $johnsonbound_unrestricted
        }     
    }
    $johnsonbound_unrestricted_capacity = [Math]::Log($johnsonbound_unrestricted,2)
    $johnsonbound_unrestricted_redundancy = $nBig - $johnsonbound_unrestricted_capacity
} catch { $_ }


#johnson restricted
try{
    $d = $ee * 2 + 2
    $e = $d/2

    $nBig = [System.Numerics.BigInteger]$n
    $wBig = [System.Numerics.BigInteger]$w

    [System.Numerics.BigInteger] $dividend = $nBig * $e
    [System.Numerics.BigInteger] $divisor = $wbig * $wbig - $nBig * $wBig + $nBig * $ee
    if ($divisor -gt 0) { $johnsonbound_restricted = [System.Numerics.BigInteger]::Divide($dividend, $divisor) }
    $johnsonbound_restricted_capacity = [Math]::Log($johnsonbound_restricted,2)
    $johnsonbound_restricted_redundancy = $n - $johnsonbound_restricted_capacity     
} catch { $_ }

if ($hammingbound) {
    $upperbound = $hammingbound
    $upperbound_capacity = $hammingbound_capacity
    $upperbound_redundancy = $hammingbound_redundancy
}
    
if ($johnsonbound_unrestricted -and ($johnsonbound_unrestricted -lt $upperbound -or !$hammingbound)) {
    $upperbound = $johnsonbound_unrestricted
    $upperbound_capacity = $johnsonbound_unrestricted_capacity
    $upperbound_redundancy = $johnsonbound_unrestricted_redundancy
} 

if ($johnsonbound -and ($johnsonbound -lt $upperbound -or !$upperbound)) {
    $upperbound = $johnsonbound_restricted
    $upperbound_capacity = $johnsonbound_restricted_capacity
    $upperbound_redundancy = $johnsonbound_restricted_redundancy
}

return [PSCustomObject]@{upperbound = $upperbound; capacity = $upperbound_capacity; redundancy = $upperbound_redundancy} 