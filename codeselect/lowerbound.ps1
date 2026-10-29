param(
        [int]$n = 8,
        [int]$ee = 1,
        [int]$w = 0
)
if ($w -eq 0) { $w = [Math]::ceiling($n/2) }
Add-Type -AssemblyName System.Numerics

$lowerbound = $null

# returns true if $number is a prime power
function primepowertest {
    param([long]$Number)
    if ($Number -lt 2) { return $false }
    
    for ($divisor = 2; $divisor -le ($Number / $divisor); $divisor++) {
        if ($Number % $divisor -eq 0) {
            while ($Number % $divisor -eq 0) { $Number = [long]($Number / $divisor) }
            return ($Number -eq 1)
        }
    }
    return $true
}

# returns x!
function factorial {
    param([int] $x = 10)
    [System.Numerics.BigInteger]$factorial = $x
    if ($x -eq 0) { return [System.Numerics.BigInteger]1}
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

$binom = binom $n $w

##Theorem 2
if ($ee -ge 2) {
    #find the closest prime power q >= n - 1
    [int]$candidate = [Math]::Max(2, $n - 1)
    while (-not (primepowertest $candidate)) { $candidate++ }
    
    $q = [System.Numerics.BigInteger]$candidate
    $q1 = $q - 1
    $qe11 = [System.Numerics.BigInteger]::Pow($q, $ee+1)-1

    $q1binom = $q1 * $binom
    $lowerbound = $q1binom / $qe11
}

## Theorem 1
#find the closest prime power q >= n
[int]$candidate = [Math]::Max(2, $n)
while (-not (primepowertest $candidate)) { $candidate++ }
$q2 = [System.Numerics.BigInteger]$candidate
$q2e = [System.Numerics.BigInteger]::Pow($q2, $ee+1)-1
#binom can be reused

$q2binom = $q2 * $binom

$lowerbound2 = $binom / $q2e

#no code possible, redundancy > n
if ($binom -lt $q2e -and $q1binom -lt $qe11){ return [PSCustomObject]@{lowerbound = 0; lowerbound_capacity = 0; lowerbound_redundancy = 0} }

# compare Theorem 1 vs Theorem 2 and use the larger result
if ($lowerbound -lt $lowerbound2) { $lowerbound = $lowerbound2 }

$lowerbound_capacity = [Math]::Log($lowerbound,2)
$lowerbound_redundancy = $n - $lowerbound_capacity

return [PSCustomObject]@{lowerbound = $lowerbound; capacity = $lowerbound_capacity; redundancy = $lowerbound_redundancy}