#uses the binary String from encode.ps1 or encode_si.ps1 and puts in biterrors with a likelihood of 15%
param (
    [string]$in = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    [int]$seed = 0,
    [double]$p_gb = 0.02,
    [double]$p_bg = 0.2,
    [double]$errorrate = 0.05,
    [double]$b_err = 0.5,
    [double]$del = 0.0
    )

#Write-host "$seed`t$p_gb`t$p_bg`t$errorrate`t$b_err"

[int] $transfer_index = 0
[int] $errors = 0
[double]$temp = $errorrate #stores the bit error rate to be able to restore after bursting
[int]$longestburst = 0
$array = $in.toCharArray()
[string] $out = ""

$transfer_errors = @()
$burststate = $false

$rng = [System.Random]::new($seed)

foreach($bit in $array) {
    if ($burststate -eq $true) { $burstlength++ }

    # deletion
    $rand = $rng.NextDouble()
    if ($rand -lt $del) {
        $errors +=1
        $bit = ''
        $transfer_errors += $transfer_index
    }

    #bitflip
    $rand = $rng.NextDouble()
    if ($rand -lt $errorrate -and $bit -ne '') {
        $errors +=1
        $bit = (([int]$bit + 1)%2) #bitflip, if there was no deletion
        $transfer_errors += $transfer_index #returns the positions of a bitflip error
    }
    $transfer_index++
    $out += $bit

    $rand = $rng.NextDouble()
    if ($burststate -eq $false -and $rand -lt $p_gb) {
        $burststate = $true
        $errorrate = $b_err
    } elseif ($burststate -eq $true -and $rand -lt $p_bg) {
        $burststate = $false
        $errorrate = $temp
        if ($burstlength -gt $longestburst) { $longestburst = $burstlength }
        $burstlength = 0
    }
}
return [PSCustomObject]@{transfer = $out; errors = $errors; seed = $seed; errorindex = $transfer_errors; longestburst = $longestburst}
x