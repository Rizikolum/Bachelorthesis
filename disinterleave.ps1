param(
[String] $wi = "12345678901234567890123456789012345678901234567890",
[int] $k = 5
)
[String] $w = ''
$m = $wi.length / $k
$i = -$m
$j = 0

while ($i -le $wi.length)
{
    $i += $m
    if ($i -ge $wi.length) {
        $j++
        if ($j -eq $m) {break}
        $i = $j  
    }
    $w += [String]$wi[$i]
}
return $w