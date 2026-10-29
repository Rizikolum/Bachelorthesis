cls
$cnt = 500 # simulations
$del = 0
$z = 1.64

# Scenario 1 BSC mit 0,01#
#$scenario = 1
#$errorrate = 0.01
#$p_gb = 0
#$p_bg = 1
#$b_err = 0
#$interleave = $true

# Scenario 2 GE mit 2/43 ohne interleave
#$scenario = 2
#$errorrate = 0.05 #5,00%
#$p_gb = 0.01 #1,00%
#$p_bg = 0.2 #20,00%
#$b_err = 0.5 #50,00%
#$interleave = $false

# Scenario 3 GE mit 2/43 und interleave
#$scenario = 3
#$errorrate = 0.05
#$p_gb = 0.01
#$p_bg = 0.2
#$b_err = 0.5
#$interleave = $true

# Scenario 4 GE mit 0.1 und interleave
$scenario = 4
$errorrate = 0
$p_gb = 0.04
$p_bg = 0.2
$b_err = 0.6
$interleave = $true

#channel parameters
$pg = $p_bg/($p_bg+$p_gb)
$pb = $p_gb/($p_bg+$p_gb)
$pne = (1-$errorrate-$del)*$pg + (1-$b_err-$del)*$pb
$pe = $errorrate*$pg+$b_err*$pb
$pdel = $del
$ble = 1/$p_bg

Write-Host "errorrate: $errorrate, del: $pdel, p_gb: $p_gb, p_bg: $p_bg, b_err: $b_err, interleave: $interleave`nP(good): $pg, P(bad): $pb`nP(no error): $pne, P(error): $pe, Expected Burstlength: $ble"
$baseparam = @{
    cnt = $cnt;
    msgcontent = $msgcontent;
    errorrate = $errorrate;
    p_gb = $p_gb;
    p_bg = $p_bg;
    b_err = $b_err;
    del = $del;
    interleave = $interleave;
    pg = $pg
    pb = $pb
    pne = $pne
    pe = $pe
    pdel = $pdel
    ble = $ble
}

$statistics = @()
for ($i = 4; $i -le 7; $i++) {
    $payloadlength = [Math]::Pow(2,$i)
    Write-Host "`n--------------------------$payloadlength--------------------------"
    $baseparam.msgcontent = '0'* $payloadlength
    $swtc = .\codeselect\find_best_code_swtc.ps1 -p $pe -z $z -encode $baseparam.msgcontent.length
    $table = ".\lookup_tables\lookup_table($($swtc.cw.n),$($swtc.cw.d),$($swtc.cw.w)).csv"
    $table_0 = ".\lookup_tables\lookup_table($($swtc.s1.n),$($swtc.s1.d),$($swtc.s1.w)).csv"
    $table_1 = ".\lookup_tables\lookup_table($($swtc.s2.n),$($swtc.s2.d),$($swtc.s2.w)).csv"
    $ks = .\codeselect\find_best_code_ks.ps1 -p $pe -z $z -encode $baseparam.msgcontent.length
    $table_2 = ".\lookup_tables\lookup_table($($ks.s1.n),$($ks.s1.d),$($ks.s1.w)).csv"
    $statistics += .\statistics\statistics.ps1 @baseparam -table $table -table_0 $table_0 -table_1 $table_1 -table_2 $table_2
}

#$statistics | Export-Clixml -Path .\statistics\statistics-$scenario-$cnt-256.xml -Depth 10 #creates a data dump, cave: large file size - can be reimported via $data = Import-Clixml -Path and the respecting path- & filename.