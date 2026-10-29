param (
    [string]$msgcontent = "010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001",
    [double]$errorrate = 0.05,
    [int]$seed = 3,
    [double]$p_gb = 0,
    [double]$p_bg = 0.2,
    [double]$b_err = 0,
    [double]$del = 0,
    [string] $table = '.\lookup_tables\lookup_table(9,4,6).csv',
    [string] $table_0 = '.\lookup_tables\lookup_table(9,4,3).csv',
    [string] $table_1 = '.\lookup_tables\lookup_table(9,4,6).csv',
    [boolean] $interleave = $true,
    [PSCustomObject] $encoded = ''
    )

#ENCODER - if we already got the Code via Input don't run this code
if ($encoded -eq '') { $encoded = .\SWTC\encode_swtc.ps1 -content $msgcontent -table $table -table_0 $table_0 -table_1 $table_1 -interleave $interleave }

#select the actual codeblock that gets sent through the channel
if ($interleave) { $message_enc = $encoded.interleaved } else { $message_enc = $encoded.encoded }

#CHANNEL
$received = .\channel.ps1 -in $message_enc -errorrate $errorrate -seed $seed -p_gb $p_gb -p_bg $p_bg -b_err $b_err -del $del

#DECODER
$decoded = .\SWTC\decode_swtc.ps1 -received $received.transfer -table $table  -table_0 $table_0 -table_1 $table_1 -interleave $interleave

return [PSCustomObject]@{
    encoded = $encoded
    received = $received
    decoded = $decoded
}
