param (
    [string]$msgcontent = "010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001",
    [double]$errorrate = 0.05,
    [double]$seed = 3,
    [double]$p_gb = 0,
    [double]$p_bg = 0.2,
    [double]$b_err = 0,
    [double]$del = 0,
    [string] $table = '.\lookup_tables\lookup_table(9,4,6).csv',
    [boolean] $interleave = $true,
    [PSCustomObject] $encoded = ''
    )

#ENCODER - if we already got the Code via Input don't run this code
if ($encoded -eq '') { $encoded = .\KS\encode_ks.ps1 -content $msgcontent -table $table }

#INTERLEAVER
#select the codeword that gets sent through the channel
if ($interleave) { $interleaved = .\interleave.ps1 -c $encoded.encoded -m $encoded.subwordlength
} else { $interleaved = $encoded.encoded }

#CHANNEL
$received = .\channel.ps1 -in $interleaved -errorrate $errorrate -seed $seed -p_gb $p_gb -p_bg $p_bg -b_err $b_err -del $del

#DEINTERLEAVER
if ($interleave) { $transfer = .\disinterleave.ps1 -wi $received.transfer -k $encoded.subwords } 
else { $transfer = $received.transfer }

#DECODER
$decoded = .\KS\decode_ks.ps1 -received $transfer -table $table

return [PSCustomObject]@{
    encoded = $encoded
    interleaved = $interleaved
    received = $received
    unwrangled = $transfer
    decoded = $decoded
}
