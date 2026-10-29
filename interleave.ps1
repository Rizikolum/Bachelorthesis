param(
[String] $c = "111111222222333333444444555555666666777777888888999999000000",
[int] $m = 10
)
[String] $ci = ''
$k = $c.length / $m
$i = -$k
$j = 0

while ($i -le $c.length)
{
    $i += $k
    if ($i -ge $c.length) {
        $j++
        if ($j -eq $k) { break }
        $i = $j  
    }
    $ci += [String] $c[$i]
}
return $ci