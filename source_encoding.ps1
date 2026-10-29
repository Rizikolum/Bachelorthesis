param (
    [string]$text = "Hello World!",
    $iso = [System.Text.Encoding]::GetEncoding(28591), #default is iso-8859-1
    $datalength = 8 # iso-8859-1 is 8-bit
)
[byte[]] $bytes = $iso.GetBytes($text) #convert text to bytes
[String] $binaryStr = ''
#the inner convert converts byte -> string, the outer one string -> (binary)String, Padleft ensures the block has enough leading zeroes to fill the datalength
for ($i = 0; $i -lt $bytes.Length; $i++) { $binaryStr += [Convert]::ToString([Convert]::ToString($bytes[$i], 10), 2).PadLeft($datalength, '0') }
return $binaryStr