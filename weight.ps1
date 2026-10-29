param ([string]$str)
$arr = $str.toCharArray()
$weight = 0
foreach($char in $arr) { if ($char -ne '0') { $weight++ } }
return $weight