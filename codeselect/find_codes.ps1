cls
$z = 1.64
foreach ($p in 0.01, (1/14), 0.1) {
    Write-host "Fehlerrate: $("{0:g}" -f $p)"
    foreach ($j in 16, 32, 64, 128) {
        $compare = .\codeselect\comparisoncode_setdata.ps1 -payloadlength $j -p $p -zbase $z
        #Lowerbound
        if ($compare.lowerbound.n -ne $null) {
            $l = " L($($compare.lowerbound.n),$($compare.lowerbound.d),$($compare.lowerbound.w))"
            $lrate = "nutzbar: L: $($compare.lowerbound.Coderate)"
        } else { 
            $l = " L: /" 
            $lrate = "nutzbar: L: /"
        }
        #Upperbound
        if ($compare.upperbound.n -ne $null) {
            if ($compare.upperbound.coderate -gt $compare.lowerbound.coderate) {
                $u = ", U($($compare.upperbound.n),$($compare.upperbound.d),$($compare.upperbound.w))"
                $urate = ", U: $($compare.upperbound.Coderate)"
            } else {
                $u = ", lowerbound > upperbound - U($($compare.upperbound.n),$($compare.upperbound.d),$($compare.upperbound.w))"
                $urate = ", U: $($compare.upperbound.Coderate)"
            }
        }
        Write-Host "payload: $j Bits$l$u`n$lrate$urate"
        $l = $null
        $u = $null

        #KS
        $ks = .\codeselect\find_best_code_ks.ps1 -p $p -encode $j -z $z
        if ($ks.s1.n -ne 0) {
            Write-host "KS:`t`t C($($ks.s1.n),$($ks.s1.d),$($ks.s1.w)), nutzbar: $($ks.totalcoderate.toString("0.000")), Score: $($ks.value)"
        }

        #SWTC
        $swtc = .\codeselect\find_best_code_swtc.ps1 -p $p -encode $j -z $z
        if ($swtc.s1.n -ne 0) {
            Write-host "SWTC:`t CW($($swtc.cw.n),$($swtc.cw.d),$($swtc.cw.w)), S1($($swtc.s1.n),$($swtc.s1.d),$($swtc.s1.w)), S2($($swtc.s2.n),$($swtc.s2.d),$($swtc.s2.w)), nutzbar: $($swtc.totalcoderate.toString("0.000")), Score: $($swtc.value)`n"
        }
    }
}

##################################################################################
# Fehlerrate: 0,01
# payload: 16 Bits L(29,6,15), U(28,6,14)
# nutzbar: L: 0,552, U: 0,571
# KS:		 C(15,4,7), nutzbar: 0,600, Score: 2,674
# SWTC:	 CW(6,6,3), S1(9,4,3), S2(9,4,6), nutzbar: 0,352, Score: 1,854
# 
# payload: 32 Bits L(47,6,24), lowerbound > upperbound - U(48,6,24)
# nutzbar: L: 0,681, U: 0,667
# KS:		 C(15,4,7), nutzbar: 0,600, Score: 2,674
# SWTC:	 CW(8,8,4), S1(10,4,4), S2(10,4,6), nutzbar: 0,413, Score: 2,458
# 
# payload: 64 Bits L(88,8,44), lowerbound > upperbound - U(90,8,45)
# nutzbar: L: 0,727, U: 0,711
# KS:		 C(16,4,8), nutzbar: 0,625, Score: 2,865
# SWTC:	 CW(8,8,4), S1(17,4,5), S2(17,4,12), nutzbar: 0,478, Score: 2,979
# 
# payload: 128 Bits L(162,10,81), lowerbound > upperbound - U(168,10,84)
# nutzbar: L: 0,790, U: 0,762
# KS:		 C(16,4,8), nutzbar: 0,625, Score: 3,084
# SWTC:	 CW(10,10,5), S1(25,6,11), S2(25,6,14), nutzbar: 0,524, Score: 3,153
# 
# Fehlerrate: 0,0714285714285714
# payload: 16 Bits L(35,8,18), lowerbound > upperbound - U(40,14,20)
# nutzbar: L: 0,457*, U: 0,400
# KS:		 C(30,12,14), nutzbar: 0,267, Score: 1,340
# SWTC:	 CW(6,6,3), S1(19,10,7), S2(19,10,12), nutzbar: 0,167, Score: 0,956
# 
# payload: 32 Bits L(161,36,81), U(72,20,36)
# nutzbar: L: 0,199, U: 0,458
# KS:		 C(30,12,14), nutzbar: 0,267, Score: 1,340
# SWTC:	 CW(6,4,3), S1(27,12,9), S2(27,12,18), nutzbar: 0,198, Score: 1,376
# 
# payload: 64 Bits L(338,66,169), U(128,30,64)
# nutzbar: L: 0,189, U: 0,500
# KS:		 C(32,12,16), nutzbar: 0,313, Score: 1,435
# SWTC:	 CW(8,8,4), S1(31,12,13), S2(31,12,18), nutzbar: 0,262, Score: 1,663
# 
# payload: 128 Bits L(810,142,405), U(248,52,124)
# nutzbar: L: 0,158, U: 0,520
# KS:		 C(32,12,16), nutzbar: 0,313, Score: 1,545
# SWTC:	 CW(14,8,5), S1(32,12,14), S2(32,12,18), nutzbar: 0,286, Score: 1,809
# 
# Fehlerrate: 0,1
# payload: 16 Bits L(47,12,24), U(46,18,23)
# nutzbar: L: 0,340*, U: 0,348
# KS:		 C(6,6,3), nutzbar: 0,167, Score: 0,840
# SWTC:	 CW(6,6,3), S1(26,14,10), S2(26,14,16), nutzbar: 0,122, Score: 0,748
# 
# payload: 32 Bits L(119,26,60), U(82,28,41)
# nutzbar: L: 0,269*, U: 0,390
# KS:		 C(6,6,3), nutzbar: 0,167, Score: 0,840
# SWTC:	 CW(6,4,3), S1(32,16,14), S2(32,16,18), nutzbar: 0,167, Score: 1,091
# 
# payload: 64 Bits L: /, U(152,46,76)
# nutzbar: L: /, U: 0,421
# KS:		 C(6,6,3), nutzbar: 0,167, Score: 0,840
# SWTC:	 CW(12,6,6), S1(32,16,14), S2(32,16,18), nutzbar: 0,167, Score: 1,093
# 
# payload: 128 Bits L: /, U(284,76,142)
# nutzbar: L: /, U: 0,454
# KS:		 C(6,6,3), nutzbar: 0,167, Score: 0,840
# SWTC:	 CW(24,8,9), S1(32,16,14), S2(32,16,18), nutzbar: 0,168, Score: 1,095
##################################################################################