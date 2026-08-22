<######
# Created by : Adam Monsour
# Link : https://gccode.ssc-spc.gc.ca/service-canada/d2gc/
# Changelog : https://gccode.ssc-spc.gc.ca/service-canada/d2gc/blob/master/CHANGELOG.md
######>

[CmdletBinding()] 
param(
    [string]$confirm,
    [string]$zipDir
)

<#
$Script:args=""
write-host "Num Args: " $PSBoundParameters.Keys.Count
foreach ($key in $PSBoundParameters.keys) {
    $Script:args+= "`$$key=" + $PSBoundParameters["$key"] + "  "
}
write-host $Script:args
#>

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if ($Invocation.MyCommand.CommandType -eq "ExternalScript") {
        Split-Path -Parent -Path $Invocation.MyCommand.Definition
    } elseif($Invocation.PSScriptRoot) {
        $Invocation.PSScriptRoot;
    } elseif($Invocation.MyCommand.Path) {
        Split-Path $Invocation.MyCommand.Path
    } else {
      [string](Get-Location)
    }
}

$dir = Get-ScriptDirectory

. "$dir\lib\Custom.ps1"
. "$dir\lib\Xml-Placeholder.ps1"

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0, [string] $LogFile = "", $TimeFormat = "yyyy-MM-dd HH:mm:ss") {
    $DefaultColor = $Color[0]
    if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
    if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine } 
    } else {
        for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
    }
    Write-Host
    if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
    if ($LogFile -ne "") {
        $TextToFile = ""
        for ($i = 0; $i -lt $Text.Length; $i++) {
            $TextToFile += $Text[$i]
        }
        Write-Output "[$([datetime]::Now.ToString($TimeFormat))]$TextToFile" | Out-File $LogFile -Encoding unicode -Append
    }
}

function configIni() {

    $array = [ordered]@{ "fname"="first name"; "lname"="last name"; "username"="AEM Username"; "email"="Email"; "aemgcEng"="English - Organisation name in AEM (for Analytics purposes)"; "file"="file name";}
    
    foreach($key in @($array.keys)){
        $f = configRH $array.Item($key)
        $array[$key] = $f
    }
    $f = @{“settings”=$array}

    return $f;
}

function displayIni() {
    $a = gic "$dir\config.ini"
    $array = [ordered]@{ "First Name"=$a["settings"]["fname"]; "Last Name"=$a["settings"]["lname"]; "AEM Username"=$a["settings"]["username"]; "Email"=$a["settings"]["email"]; "English Organisation name in AEM"=$a["settings"]["aemgcEng"]; "File Name"=$a["settings"]["file"];}

    return $array;
}

function hashIni() {
    $a = gic "$dir\config.ini"
    $array = [ordered]@{ "createdBy"=$a["settings"]["fname"]; "name"=$a["settings"]["lname"]; "lastModified"=$a["settings"]["inst"]; "lastModifiedBy"=$a["settings"]["acr"]; "created"=$a["settings"]["file"];`
                         "buildCount"="1"; "version"=$a["settings"]["lname"]; "dependencies"=""; "packageFormatVersion"=$a["settings"]["acr"]; "description"=$a["settings"]["file"];`
                         "lastWrapped"=""; "group"=$a["settings"]["acr"]; "lastWrappedBy"=$a["settings"]["file"]; }
    return $array;
}

function configRH ($string) {
    return Read-Host "Please state your $string"
}
<#
function checkAccents ($str) {
    


    $wrapper = @{ 'Ã€'='À'; 'Ãƒ'='Ã'; 'Ã„'='Ä'; 'Ã…'='Å'; 'Ã†'='Æ'; 'Ã‡'='Ç'; 'Ãˆ'='È'; 'Ã‰'='É'; 'ÃŠ'='Ê'; 'Ã‹'='Ë';
                    'ÃŒ'='Ì'; 'ÃŽ'='Î'; 'Ã&lsquo;'='Ñ'; 'Ã&rsquo;'='Ò'; 'Ã&ldquo;'='Ó'; 'Ã&rdquo;'='Ô'; 'Ã•'='Õ'; 'Ã–'='Ö';
                    'Ã—'='×'; 'Ã˜'='Ø'; 'Ã™'='Ù'; 'Ã›'='Û'; 'ÃŸ'='ß'; 'Ã¡'='á'; 'Ã¢'='â'; 'Ã£'='ã'; 'Ã¤'='ä';
                    'Ã¥'='å'; 'Ã¦'='æ'; 'Ã§'='ç'; 'Ã¨'='è'; 'Ã©'='é'; 'Ãª'='ê'; 'Ã«'='ë'; 'Ã¬'='ì'; 'Ã®'='î'; 'Ã¯'='ï'; 'Ã°'='ð'; 'Ã±'='ñ'; 'Ã²'='ò';
                    'Ã³'='ó'; 'Ã´'='ô'; 'Ãµ'='õ'; 'Ã¶'='ö'; 'Ã·'='÷'; 'Ã¸'='ø'; 'Ã¹'='ù'; 'Ãº'='ú'; 'Ã»'='û'; 'Ã¼'='ü'; 'Ã½'='ý'; 'Ã¾'='þ'; 'Ã¿'='ÿ'; 'â'‚¬'='€';
                    'Æ&rsquo;'='ƒ'; 'â€ž'='&bdquo;'; 'â€¦'='…'; 'â€'='†'; 'â€¡'='‡'; 'Ë†'='ˆ'; 'â€°'='‰'; 'Å'='Š'; 'â€¹'='‹'; 'Å&rsquo;'='Œ'; 'â€™'='&rsquo;';
                    'â€œ'='&ldquo;'; 'â€¢'='•'; 'â€&ldquo;'='–'; 'â€&rdquo;'='—'; 'Ëœ'='˜'; 'â&bdquo;¢'='™'; 'Å¡'='š'; 'â€º'='›'; 'Å&ldquo;'='œ';
                    'Å¾'='ž'; 'Å¸'='Ÿ'; 'Â¢'='¢'; 'Â£'='£'; 'Â¤'='¤'; 'Â¥'='¥'; 'Â§'='§'; 'Â¨'='¨'; 'Â©'='©'; 'Âª'='ª'; 'Â«'='«'; 'Â¬'='¬';
                    'Â®'='®'; 'Â¯'='¯'; 'Â°'='°'; 'Â±'='±'; 'Â²'='²'; 'Â³'='³'; 'Â´'='´'; 'Âµ'='µ'; 'Â¶'='¶'; 'Â·'='·'; 'Â¸'='¸'; 'Â¹'='¹'; 'Âº'='º'; 'Â»'='»';
                    'Â¼'='¼'; 'Â½'='½'; 'Â¾'='¾'; 'Â¿'='¿'; 'Ã'= 'à';
    }
    $wrapper.Keys | % {
        $str = $str -replace "$_" , $wrapper[$_]
    }
    
    return $str
}
#>

function doLogic($fir, $sec, $log, $json) {
    $fir = isJson $fir $json
    $sec = isJson $sec $json

    if ($fir -eq $false) { $fir = $null }
    if ($sec -eq $false) { $sec = $null }

    #write-host $fir $sec

    if ($fir -match '\*') {
        $last = $fir.Length
        if ($fir[$last-1] -eq "*") {
            $fir = $fir.substring(0, $last-1)
            $firLength = $fir.Length
            $sec = $sec.substring(0, $firLength)
        } else {
            Write-Host "The wild card can only be applied at the end, not the beginning or middle"
        }
    } elseif ($sec -match '\*') {
        $last = $sec.Length
        if ($sec[$last-1] -eq "*") {
            $sec = $sec.substring(0, $last-1)
            $secLength = $sec.Length
            $fir = $fir.substring(0, $secLength)
        } else {
            Write-Host "The wild card can only be applied at the end, not the beginning or middle"
        }
    }

    $and = "%%"
    $andEx = "=="
    $or = "||"
    $orEx = "--"
    $split = "@@"

    if ( $log -eq $or) {
        if ($fir -or $sec) {
            return $true;
        }
    } elseif ( $log -eq $and) {
        if ($fir -and $sec) {
            return $true;
        }
    } elseif ( $log -eq $split ) {
        if ( ($fir -eq $sec) -or ( $fir.length -gt 0 -and ($sec -eq 1 -or $sec -eq "true") ) ) {
            return $true;
        }
    } elseif ( $log -eq $orEx ) {
        if ( ($fir -eq $sec) ) {
            return $true;
        }
    }  elseif ( $log -eq $andEx ) {
        if ( ($fir -ne $sec) ) {
            return $true;
        }
    } 
    return $false;
}

function checkCondition($array, $json) {
    $and = "*%%*"
    $or = "*||*"

    if ($array -like $or -or $array -like $and) {
        $arr = $array.Split()
        $cnt = 0
        $log = $null
        for ($i = 0; $i -lt $arr.count; $i = $i + 3) {
            if ($cnt -eq 0) {
                $log = doLogic $arr[$cnt].Trim() $arr[$cnt+2].Trim() $arr[$cnt+1].Trim() $json
                #write-host $arr[$cnt].Trim() $arr[$cnt+2].Trim() $arr[$cnt+1].Trim() $log
            } else {
                $log = doLogic $fin $arr[$cnt+2].Trim() $arr[$cnt+1].Trim() $json
                #write-host $fin $arr[$cnt+2].Trim() $arr[$cnt+1].Trim() $log
            }
            $fin = $log
            
            $cnt = $cnt + 2
        }
        return $fin;
    }

    $jsonVar = $json.($array);
    if (!$jsonVar) { return $false; }
    return $true;
}

function includesData($array, $json) {
    $and = "@@"
    $andVar = "*@@*"

    if ($array -like $andVar) {
        $arr = $array -split $and
        $foo = $arr[1].Split(";")

        $jsonVar = isJson $arr[0] $json

        foreach ($var in $foo) {
            if ($jsonVar -eq $var) {
                return $true
            }
        }
    }
    
    return $false;
}

function getSplit ($text, $array, $json) {
    $org = $text

    $final = $null
    $cnt = 0
    $len = $str.length

    foreach ($str in $array.name) {
        $text = $org

        $hash = "*((Custom.Hash))*"
        $hVar = "((Custom.Hash))"
        if ( $text -like $hash ) {
            if ($len -gt 1) { $arr = $array[$cnt].hash; }
            else { $arr = $array.hash; }
            $text = $text -replace [regex]::Escape($hVar), $arr;
        }

        while ( $text -like "*((*))*" ) { 
            
            $var = $text.substring($text.IndexOf("(("), $text.IndexOf("))") + 1 - $text.IndexOf("((") + 1)

            $r = [regex] '\(\([\d]{1,10}\)\)'
            $match = $r.match($var)
            $var2 = $match.groups[0].value

            if (!$var2) {
                $jsonVar = isJson $var $json
                $text = $text -replace [regex]::Escape($var), $jsonVar;
            } else {
                $jsonVar = $text.substring($text.IndexOf("((") + 2, $text.IndexOf("))") - $text.IndexOf("((") - 2)
                if ($len -gt 1) {
                    $text = $text -replace [regex]::Escape($var), $array[$cnt].values[[int]$jsonVar-1];
                } else {
                    $text = $text -replace [regex]::Escape($var), $array.values[[int]$jsonVar-1];
                }
            }
        }

        
        
        #$final += "$text<br />" #2022-07-15 commented out and replaced by 2 lines below - axl618
        $cnt++
        
        if($cnt -lt $len){$final += "$text</li><li>"} #2022-07-15 -axl618
        else{$final += "$text"}                       #2022-07-15 -axl618
        
      
    }
    return $final    

}

function isSplit($array, $text, $json) {
    if ($array.split -and $array.source) {
        $src = $array.source
        $sub = $null
        $split = $array.split
        $exclude = $array.exclude
        $hash = $array.hash
        $sort = $array.sort
        $delim = ";"
        if ($sort) {
            if ($sort -like "*$delim*") {
                $sortNum = $sort.Split($delim)[0];
                $sortAsc = $sort.Split($delim)[1];
                if ($sortAsc -ne "asc" -or $sortAsc -ne "desc") { $sortAsc = "desc"; }
            }
        }

        if ($exclude) {
            $excludeArr = @($exclude.Split($delim));
        }

        $multiple = $false;

        if (!$src -or !$split) { return; }
        if ($array.sub) { $sub = $array.sub }
        $src = isJson $src $json
        $src = $src -split $split
        $str = @(); $cnt = 0

        if ($sub) {

            foreach ($foo in $src) {
                $foo = $foo -split $sub
                $str += @{ Name = $cnt; values = @() }
                foreach ($suba in $foo) {
                    $str[$cnt].values += $suba
                }
                $cnt++
            }
            $multiple = $true;
        } else {
            foreach ($foo in $src) {
                $str += @{ Name = $cnt; values = @() }
                $str[$cnt].values += $foo
                $cnt++
            }
            $multiple = $false;
        }

        if ($sort) {
            if ($multiple) {
                if ($sortAsc -eq "asc") { $str = $str.GetEnumerator() | Sort-Object{ $_.values[[int]$sortNum-1] } }
                else { $str = $str.GetEnumerator() | Sort-Object -Descending { $_.values[[int]$sortNum-1] } }

            } else {
                if ($sortAsc -eq "asc") { $str = $str.GetEnumerator() | Sort-Object { $_.values } }
                else { $str = $str.GetEnumerator() | Sort-Object -Descending { $_.values } }
            }
        }

        if ($hash) { 
            if ($str.ContainsKey(1)) { 
                $hash = $hash | ConvertFrom-Json
                #$obj = $hash | out-string
                #write-host $obj
                $cnt = 0
                $str = $str.GetEnumerator() | ? { 
                    foreach ( $key in $hash.psobject.properties.name ) {
                        $value = $hash.$key
                        $orig = $_.values
                        
                        if ( $orig -match $value ) {
                            $orig -match $value
                            $str[$cnt].hash += $key                            
                            break;
                        }
                    }
                    $cnt++
                    
                }
            } else {
                $hash = $hash | ConvertFrom-Json
                foreach ( $key in $hash.psobject.properties.name ) {
                    $value = $hash.$key

                    $orig = $str.values

                    if ( $orig -match $value ) {
                        $str += @{hash = $key}
                    }
                }
            }
        }

        if ($exclude) {
            if ($str.ContainsKey(1)) {
                $str = $str.GetEnumerator() | ? { 
                    $count = 0
                    foreach ( $exc in $excludeArr ) {
                        $orig = $_.values
                        if ($orig -match $exc) {
                            $count++
                        }
                    }
                    if ($count -eq 0) {
                        $orig
                    }
                }
            } else {
                $orig = $str.values
                foreach ( $exc in $excludeArr ) {
                    if ($orig -match $exc) {
                        $str.clear()
                    }
                }
            }
        }
        
        return getSplit $text $str $json
        
    }
}

function isSplitAt ( $first, $second, $json ) {
    $split = "*@@*"
    $splitVar = "@@"
    if ( ($first -like $split) -and ($second -like $split) ) {
        $first = $first -split $splitVar
        $second = $second -split $splitVar

        if ($first.Count -eq $second.Count) {
            for ($i = 0; $i -lt $first.count; $i++) {
                $foo = doLogic $first[$i] $second[$i] $splitVar $json
                if ( $foo -eq $false ) { return $false }
            }
            return $true
        }
    } else {
        $foo = doLogic $first $second $splitVar $json
        if ( $foo -ne $false ) { return $true }
    }
    return $false
}

function isSplitOr ( $first, $second, $json ) {
    $split = "*@@*"
    $splitVar = "@@"
    $orVar = "--"
    $andVar = "=="

    if ( ($first -like $split) -and ($second -like $split) ) {
        $first = $first -split $splitVar
        $second = $second -split $splitVar

        if ($first.Count -eq $second.Count) {
            for ($i = 0; $i -lt $first.count; $i++) {
                #write-host "$i " + $first[$i] + $second[$i]
                $foo = doLogic $first[$i] $second[$i] $orVar $json
                if ( $foo -eq $true ) { return $true; }
            }
            return $false
        }
    } else {
        $foo = doLogic $first $second $orVar $json
        if ( $foo -eq $true ) { return $true }
    }
    return $false
}

function isText($array, $json, $cntr) {
    $hasRequired = "";
    $breaks = ""
    $text = ""
    $global:split = 0
    $name = "mwsbodytext"

    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ $global:cntr--; return; }
    }

    if ($array.includes) {
        $var = includesData $array.includes $json
        if ($var -eq $false) { $global:counter--; return; }
    }

    $text = $array.InnerXml

    $textTemp = isSplit $array $text $json
    if ($textTemp) { $text = $textTemp; }

    if ($array.break) {
        $j = $json.($array.break)
        $breaks = hasBreakLines $j
        $newLines = hasNewLines $j
    }
    
    $html = $array.Name
    if ($html -eq "dt" -or $html -eq "dd") {
        $html = "p";
    }

    $text = isJson $text $json $html
    $text = replaceAmp $text
    $text = replaceSquareBrackets $text

    if ($breaks) { $text = addBreak $text $breaks }
    #write-host $text
    $text = removeLTChar $text
    if ($html -ne "li" -or $html -ne "dt") {
        $text = parseHtml $text $html
    }
    $text = replaceQuote $text

    if ($newLines) { $text = addParagraph $text $newLines }

    if ($array.Name -eq "dt" -or $array.Name -eq "li") {
        if ( $cntr -gt 9) {
            [string]$cntr = $cntr;
            $first = $cntr.Substring(0,1)
            $second = $cntr.Substring(1,2)
        }
        else {
            [string]$cntr = $cntr;
            $first = $cntr.Substring(0,1)
        }
        $f += $dt.replace("***1***", $first).replace("***2***", $second).replace("***TEXT***", $text);
    }
    elseif ($array.Name -eq "dd") {
        $f += $dd.replace("***LISTNUM***", $cntr).replace("***TEXT***", $text);
    }
    else {
        $text = $bodyText.replace("***TEXT***", $text);
        $global:txtNum = getRandomNumber $global:txtNum
        $f += $text.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:txtNum) ))
    }

    return $f
}
 
function isPanel($array, $json) {
    $f = ""

    $loop = $array.for;

    if ($loop) {
        foreach ($j in $json.$loop) { $f += getPanel $array $j }
    } else { $f = getPanel $array $json }

    return $f
}

function getPanel($array, $json) {
    
    $name = "mwspanel"
    $h = $null
    $header = $array.header
    $class = $array.class

    $global:panNum = getRandomNumber $global:panNum
    if ($header) {
        $h = getJson $header $json
    }
            
    $f = $panelOp.Replace("***CLASS***", $class).Replace("***HEADER***", $h).Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:panNum) ))
    $f += mainChild $array.ChildNodes $json
    $f += $panelEd.Replace(("</" + $name), ( "</" + $name + "_" + (getRandomNumber $global:panNum) ));

    return $f
}
 
function isColumn($array, $json) {
    $f = ""
    $size = $array.size.Split(";")[0]

    
    if ($size -eq "1" -or $size -eq "2" -or $size -eq "3") {
        $f += $columnsOp.Replace("***SIZE***", $array.size);
        for ($i = 0; $i -le $size - 1; $i++) {
            $f += mainChild -xml $array.ChildNodes[$i].ChildNodes -json $json -colNum ($i + 1)
        }
        $f += $columnsEd;

        return $f
    }
    return
}

function isList($array, $json) {
    $f = ""

    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ return; }
    }

    if ($array.includes) {
        $var = includesData $array.includes $json
        if ($var -eq $false) { return; }
    }

    $a = $array.Name
    $c = $array.class

    if ($a -eq "dl") {
        
        if ($c -eq "dl-horizontal") {
            $f += $dlOp.replace("***LTEMPLATE***", "horizontal")
        } else {
            $f += $dlOp.replace("***LTEMPLATE***", "default")
        }
        
        $global:cntr = 0
        
        $f += $dtOp
        $f += getList $array $json "dt"
        $f += $dtEd

        $global:cntr = 0
        $f += getList $array $json "dd"
        
        $f += $dlEd;
    }
    elseif ($a -eq "ul") { 
        $name = "mwsmulti_list"
        if ($c) {
            $text = $ulOp.replace("***ULCLASS***", $c)
        } else {
            $text = $ulOp.replace("***ULCLASS***", "default")
        }
        $global:txtNum = getRandomNumber $global:txtNum
        $f += $text.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:txtNum) ))

        $global:cntr = 0
        
        $f += $dtOp
        $f += getList $array $json "li"
        $f += $dtEd

        $f += $dlEd.Replace(("</" + $name), ( "</" + $name + "_" + (getRandomNumber $global:txtNum) ));
    }
    elseif ( $a -eq "ol") { 
        $name = "mwsmulti_list"  
        if ($c) {
            $text = $olOp.replace("***OLCLASS***", $c)
        } else {
            $text = $olOp.replace("***OLCLASS***", "default")
        }
        $global:txtNum = getRandomNumber $global:txtNum
        $f += $text.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:txtNum) ))

        $global:cntr = 0
        
        $f += $dtOp
        $f += getList $array $json "li"
        $f += $dtEd

        $f += $dlEd.Replace(("</" + $name), ( "</" + $name + "_" + (getRandomNumber $global:txtNum) ));
    }

    return $f
}

function getList($array, $json, $html) {

    for ($i = 0; $i -le $array.ChildNodes.Count - 1; $i++) {
        $a = $array.ChildNodes[$i].Name
        if ($a -eq $html) {
            $global:cntr++
            $f += isText $array.ChildNodes[$i] $json $global:cntr
        }
    }
    return $f
}
 
function isHorizontal($array, $json) {
    $name = "mwshorizontalrule"
    $global:hrNum = getRandomNumber $global:hrNum

    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ return; }
    }
    
    $f = $hr.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:hrNum) ))
    return $f

}

function isTextWrapper($array, $json, $tag) {
    
    $text = ""
    $name = ""
    if ( $tag -eq "text-wrapper" ) { $name = "mwsbodytext" }
    else { $name = "mwsgeneric_base_html" }
    
    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ return; }
    }
    
    for ($i = 0; $i -le $array.ChildNodes.Count - 1; $i++) {
         #write-host $array.ChildNodes[$i].Name
         $text += setWrapper $array.ChildNodes[$i] $json
    }
    $text = replaceQuote $text
    $text = replaceAmp $text
    $text = replaceWithSquareBrackets $text
    #write-host $text
    $text = removeLTChar $text
    $text = $text.replace("&amp;quot;", "&quot;")
    $text = $text.replace("&amp;#91;", "&#91;")
    $text = $text.replace("&amp;#93;", "&#93;")
    $text = $text.replace("&lt;p>&lt;p>", "&lt;p>")
    $text = $text.replace("&lt;/p>&lt;/p>", "&lt;/p>")
    
    if ($name -eq "mwsbodytext") { $text = $bodyText.replace("***TEXT***", $text); }
    else { $text = $genericText.replace("***TEXT***", $text); }

    $global:txtNum = getRandomNumber $global:txtNum
    $f = $text.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:txtNum) ))

    If($f -match "&lt;details.*?>\s–.*?&lt;/details>"){Write-Host "`nNote: Removed empty prior year ex/hide" -ForegroundColor cyan; $f = $f -replace "&lt;details.*?>\s–.*?&lt;/details>","";} #2023-12-04 axl618 - added this line to remove empty prior year ex/hides if they are only available in either fillable or flat format
    #write-host $f

    return $f

}

function setWrapper ($array, $json) {

    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ return; }
    }

    if ($array.includes) {
        $var = includesData $array.includes $json
        if ($var -eq $false) { return; }
    }

    if ($array.break) {
        $j = $json.($array.break)
        $breaks = hasBreakLines $j
        $newLines = hasNewLines $j
    }
    
    $html = $array.LocalName
    $html2 = $array
    $text = $array.InnerXml
    $attrib = $null
    #write-host $text + $text2 + $text3
    $textTemp = isSplit $array $text $json $html
    
    if (!$textTemp) {
        if ($array.hasChildNodes) {
            for ($i = 0; $i -le $array.ChildNodes.Count - 1; $i++) {
                 $temp += setWrapper $array.ChildNodes[$i] $json
            }
            $text = $temp
        } else { 
            $text = $array.InnerText
            #write-host $text
        }
    } else { $text = $textTemp;}

    $text = isJson $text $json $html
    $text = replaceSquareBrackets $text
    foreach ($attr in $array.attributes) {
        if ( $attr.Name -ne "required" -and $attr.Name -ne "split" -and $attr.Name -ne "source" -and $attr.Name -ne "sub" -and $attr.Name -ne "header" -and $attr.Name -ne "for" -and $attr.Name -ne "break" -and $attr.Name -ne "hash" -and $attr.Name -ne "sort" -and $attr.Name -ne "includes" -and $attr.Name -ne "exclude") {
            $attrib += ($attr.Name) + "=""" + ($attr."#text") + """ "
        }
    }

    if ($attrib) {
        $text = "<$html $attrib>$text</$html>"
        $text = isJson $text $json $html
        $text = replaceSquareBrackets $text
        #write-host $text
    }
    else {
        if ($html -ne "#text" -and $html -ne "#comment") {
            $text = "<$html>$text</$html>"
        } elseif ($html -eq "#comment") {
            $text = "<!--$text-->"
        }
    }
    return $text
}

function isAlert($array, $json) {
    $name = "mwsalerts"

    if ($array.required) {
        $jsonVar = checkCondition $array.required $json
        if (!$jsonVar){ return; }
    }
    
    $f = $alertOp;
    $text = $array.InnerXML;
    $text = isJson $text $json

    $class = $array.class
    if ($class -eq "alert-success" -or $class -eq "alert-info" -or $class -eq "alert-warning" -or $class -eq "alert-danger") {
        $array.class
    } else {
        $class = "alert-info"
    }

    $j = $text

    if ($j -like "*<div.*?>*" -or $j -like "*</div>*" ) {
        $r = [regex] '<div.*?>([\r\n\s\S]+)<\/div>'
        $match = $r.match($j)
        $j = $match.groups[1].value
    }

    if (!$array.title) {
        if ($j -match '<(h[\d]{1}).*?>') {
            $heading = $Matches[1]

            $r = [regex] "\<h[\d].*?\>(.*?)\<\/h[\d]\>"
            $match = $r.match($j)
            $title = $match.groups[1].value

            $r = [regex] '<\/h[\d]\>([\r\n\s\S]+)'
            $match = $r.match($j)
            $j = $match.groups[1].value
        }
        else {
            $heading = "h2"
            $title = "Information"
        }
    }
    else {
        $title = $array.title;
        $heading = $array.heading
    }
    
    $text = $j
    $text = removeLTChar $text
    $text = replaceQuote $text

    $f += $alert.replace("***TEXT***", $text).replace("***HEADING***", $heading).replace("***CLASS***", $class).replace("***TITLE***", $title);

    $f += $alertEd
    
    $global:txtNum = getRandomNumber $global:txtNum
    $f = $f.Replace(("<" + $name), ( "<" + $name + "_" + (getRandomNumber $global:txtNum) )).Replace(("</" + $name), ( "</" + $name + "_" + (getRandomNumber $global:txtNum) ))

    return $f

}
 
 
function mainChild {
param([System.Object] $xml, [System.Object] $json, [double] $colNum, [string] $id)

#Write-Host XML: $x.PSObject.TypeNames`n`r JSON: $json.PSObject.TypeNames`n`r
    
    if ($colNum) {
        $f += $colOp.Replace( $dftNum, $colNum)
    }

    for ($i=0; $i -lt $xml.count; $i++) {
        
        $x = $xml[$i]
        $y = $x.Name

        if ($y -eq "p" -or $y -eq "h2" -or $y -eq "h3" -or $y -eq "h4" -or $y -eq "h5" -or $y -eq "h6" ) {
            $f += isText $x $json
        }
        elseif ($y -eq "dl" -or $y -eq "ul" -or $y -eq "ol") {
            $f += isList $x $json
        }
        elseif ($y -eq "col") {
            $f += isColumn $x $json
        }
        elseif ($y -eq "panel") {
            $f += isPanel $x $json
        }
        elseif ($y -eq "alert") {
            $f += isAlert $x $json
        }
        elseif ($y -eq "text-wrapper" -or $y -eq "generic-text") {
            $f += isTextWrapper $x $json $y
        }
        elseif ($y -eq "hr") {
            $f += isHorizontal $x $json
        }
    }
 
    if ($colNum) {
        $f += $colEd.Replace( $dftNum, $colNum)
    }
 
    return $f
}

function Get-ObjectMembers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [PSCustomObject]$obj
    )
    $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        [PSCustomObject]@{Key = $key; Value = $obj."$key"}
    }
}

function isJson($text, $json, $html, $bool) {

    while ( $text -like "*((*))*" ) {
        $text = getJson $text $json $html $bool
    }
    
    #$text = checkAccents $text

    return $text
}
#*********
function getJson($text, $json, $html, $bool) {
    $f = ""

    #get full variable
    $var = $text.substring($text.IndexOf("(("), $text.IndexOf("))") + 1 - $text.IndexOf("((") + 1)
    $jsonVar = $text.substring($text.IndexOf("((") + 2, $text.IndexOf("))") - $text.IndexOf("((") - 2)

    #get the variable without the $ sign and semi-colon
    if ($var -like "((Custom.Key))") { $json = $global:id }
    elseif ($var -like "((Custom.Dir))") { $json = $dir }
    #elseif ($bool) { return $text  -replace [regex]::Escape($var), $jsonVar; }
    else { $json = $json.$jsonVar }

    if ($text -like "*$var.ToUpper()*") {
        $var = "$var.ToUpper()"
        $json = $json.ToUpper()
    }
    elseif ($text -like "*$var.ToLower()*") {
        $var = "$var.ToLower()"
        $json = $json.ToLower()
    } elseif ($text -like "*$var.HTMLFix()*") {
        $temp = ".html"
        $var = "$var.HTMLFix()"
        if ($json -like "*.html*") {
            $r = [regex] '(.*?).html.*?'
            $match = $r.match($json)
            $j = $match.groups[1].value
            $json = $j + $temp
        }
    }

    #if ($bool) { }

    if ($json.PSObject.TypeNames -eq "System.Object[]") {
        foreach ($j in $json) {
            $f += "<$html>" + $j + "</$html>"
            #write-host "json: " $j "`n`rjson type: " $j.PSObject.TypeNames "`n`r`n`r"
        }
        $json = $f
    }

    $final = $text  -replace [regex]::Escape($var), $json
    
    #write-host "Variable: $var ; Json: $final"

    return $final
}

#Get Random number;
function getRandomNumber ($num)  {
    # If there is a number fed into function, +1 the value and return
    if ($num) { $num++ }
    #else, get a random number from range and return
    else { $num = Get-Random -Minimum 1000000000 -Maximum 9000000000 }
    return $num
}

function hasBreakLines ($string) {
    #returns how many break lines are in the string
    return ([regex]::Matches($string, "<\s*br\s*/>" )).count
}

function hasNewLines ($string) {
    #returns how many new lines are in the string
    return $string.count;
}

function removeNewLines ($string) {
    #returns a string without the line feed unicode character
    return $string -replace "\u000a", " "
}

function replaceQuote ($string) {
    return $string.replace("`"", "&quot;");
}

function replaceAmp ($string) {
    return $string.replace("&", "&amp;")
}

function replaceSquareBrackets ($string) {
    if ( $string -ne $null ) {
        $string = $string.replace("[", "&#91;");
        $string = $string.replace("]", "&#93;");
    }
    return $string
}

function replaceWithSquareBrackets ($string) {
    #write-host $string
    $string = $string -replace "<!(--)*<([\s\w\d]+)>", ("<!" + '$1' + "[" + '$2' + "]")
    return $string
}

function removeLTChar ($string) {
    #returns a string without the less than symbol and replaces with the html entity
    return $string.replace("<", "&lt;")
}

function cleanName ($name) {
    #cleans a string as much as possible so that it relates to the title in the aem url
    #to remove
    #$name = $name.Replace("[©{}<>()[]!@#$%^&*,/\\~]", '').Replace(".-_", " ")
    #$name = $name.Replace("/", '').Replace("*",'')
    $name = $name -replace "\s[a-zA-Z]{1,3}\s", "-" -replace "-[a-zA-Z]{1,3}\s", "-" -replace "\s\w\'", "" -replace "-\w\'", "-" -replace "\'", "" -replace "\""", ""
    $name = $name -replace "@", "" -replace "\s+", " " -replace "\s-\s", "-" -replace "\s", "-" -replace ":", "" -replace "&#.*?;",""
    <#
    $name = $name.replace("[©{}<>()[]!@#$%^&*.,/\\'""~``’]", '')
    $name = $name.Replace("/", '').Replace("*",'')
    $name = $name -replace "\s+", " " -replace "\s-\s", "-" -replace "\s", "-" -replace ":", "" -replace "@", "" -replace ",&#.*?;",""
    #>
    return $name.ToLower()
}

function getDate ($pre, $format) {
    if (!$format) { $format = 'yyyy-MM-dd' }
    if ($pre) {
        $pre = [DateTime]::ParseExact($pre, $format, $null)
        return "{Date}" +$pre.ToString("yyyy-MM-ddTHH:mm:ss.fff-05:00")
    } else {
        #formats the date in the same structure as aem does
        return "{Date}" +(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fff-04:00")
    }
}

function getDateProp {
    return (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fff-04:00")
}

function parseHtml ($string, $html) {
    
    if ( $string.startswith("&lt;$html>") -and $string.endswith("&lt;/$html>") ) {
        return $string;
    }
    else {
        #the html tag in variables
        $temp = ""; $op = "&lt;$html>"; $ed = "&lt;/$html>&#xa;"
        #for every break line, split and then surround it with the p tags as proper html > aem coding
        $temp = $op + $string + $ed;
    }

    return $temp
}

function addBreak ($string, $breaks) {
    $temp = "";
    #for every new line, split and then surround it with the p tags as proper html > aem coding
    for ($i = 0; $i -le $breaks; $i++) {
        $temp += "&lt;br>"
    }
    $string = $string + $temp

    return $string
}

function addParagraph ($string, $breaks) {
    $temp = ""; $op = "&lt;p>"; $ed = "&lt;/p>&#xa;"
    #for every new line, split and then surround it with the p tags as proper html > aem coding
    for ($i = 1; $i -lt $breaks; $i++) {
        $temp += "$op&amp;nbsp;$ed"
    }
    $string = $string + $temp
    return $string
}

function ParseItem($jsonItem) 
{
    if($jsonItem.PSObject.TypeNames -match 'Array') { return ParseJsonArray($jsonItem) }
    elseif($jsonItem.PSObject.TypeNames -match 'Dictionary') { return ParseJsonObject([HashTable]$jsonItem) }
    else { return $jsonItem }
}

function ParseJsonObject($jsonObj) 
{
    $result = New-Object -TypeName PSCustomObject
    foreach ($key in $jsonObj.Keys) {
        $item = $jsonObj[$key]
        if ($item) { $parsedItem = ParseItem $item }
        else { $parsedItem = $null }
        $result | Add-Member -MemberType NoteProperty -Name $key -Value $parsedItem
    }
    return $result
}

function ParseJsonArray($jsonArray) 
{
    $result = @()
    $jsonArray | ForEach-Object -Process { $result += , (ParseItem $_) }
    return $result
}

function ParseJsonString($json) 
{
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")        
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = [System.Int32]::MaxValue
    $ser.RecursionLimit = 99
    $config = $ser.DeserializeObject($json)
    return ParseItem($config)
}

function ParseJsonFile($fileName) {
    $json = (Get-Content -Raw $fileName | Out-String)
    return ParseJsonString $json
}

function getAltTitle ( $string, $json ) {
    
    $altTitle = $string
    $altTitleText = $string.InnerText

    if ($altTitleText -ne $null -or $altTitleText -ne "") {

        $altRemove = $altTitle.remove
        $altAdd = $altTitle.add
        $altType = $altTitle.type
        $altSource = isJson $altTitle.source $json

        if ($altType -eq "any" -or $altType -eq $null) {
            $altId = (($altSource).replace($altRemove, ""))
        } elseif ($altType -eq "end") {
            $rem = $altRemove.Length
            $altIdEnd = ($altSource).substring( ($altSource.Length-$altRemove.Length), $altRemove.Length);
            $altIdBeg = ($altSource).substring( 0, ($altSource.Length-$altRemove.Length) );
            
            if ($altRemove -eq $altIdEnd) {
                $altId = $altIdBeg
            }
        }

        $altId = $altID + $altAdd

        $cnt = 0;
        if ($global:altLevel -eq 1) {
            Get-ObjectMembers -obj $json | ForEach {
                if ($_.Key -eq $altId) {
                    $altTitle = isJson $altTitleText $_.Value
                    $cnt++;
                }
            }
        } elseif ($global:altLevel -eq 2) {
            Get-ObjectMembers -obj $json | ForEach { 
                Get-ObjectMembers -obj $_.Value | ForEach {
                    if ($_.Key -eq $altId) {
                        $altTitle = isJson $altTitleText $_.Value
                        $cnt++;
                    }
                }
            }
        } elseif ($global:altLevel -eq 3) {
            Get-ObjectMembers -obj $json | ForEach { 
                Get-ObjectMembers -obj $_.Value | ForEach {
                    Get-ObjectMembers -obj $_.Value | ForEach {
                        if ($_.Key -eq $altId) {
                            $altTitle = isJson $altTitleText $_.Value
                            $cnt++;
                        }
                    }
                }
            }
        }
        #cleans title and trims
        if ($cnt -eq 0) {
            Write-Color -Text "Error", "`r`nThe alternative title was not processed correctly, the following was not found in the database `"$altID`"; The alternate title will be set to nil.`r`nPlease fix the problem in the JSON/XML or template file and try the executable again." -Color "Red", "DarkYellow"
            $global:errorLog = 1;
            $altTitle = $null;
        } else {
            $altTitle = replaceAmp $altTitle.Trim();
        }

    #write-host $altTitle + $altTitleText 
    } else {
        $altTitle = $null;
    }

    return $altTitle;

}

function main ($jsonRaw, $xml, $xmlChildren, $jsonRawFull, $xmlChildrenFr, $jsonRawFullFr) {
    $global:id = $jsonRaw.Key
    $json = $jsonRaw.Value
    $lang = $xml.html.header.language.InnerText
    $langVal = $xml.html.header.language.val
    $lang = isJson $lang $json
    $altTitle = $xml.html.header.altTitle;
    $global:errorLog = 0;

    $unique = $xml.html.header.unique.InnerText
    $uniqueVal = $xml.html.header.unique.val

    $includes = $xml.html.header.includes.InnerText
    $includesVal = $xml.html.header.includes.val

    $excludes = $xml.html.header.excludes.InnerText
    $excludesVal = $xml.html.header.excludes.val

    if ($unique) {
        $unique = isSplitAt $unique $uniqueVal $json
    } else { $unique = $null; }

    if ($includes) {
        $includes = isSplitOr $includes $includesVal $json
    } else { $includes = $null; }

    if ($excludes) {
        $excludes = isSplitOr $excludes $excludesVal $json
    } else { $excludes = $null; }

    if ( ( ($unique -eq $true) -or ($unique -eq $null) ) -and ( ($includes -eq $true) -or ($includes -eq $null) ) -and ( ($excludes -eq $false) -or ($excludes -eq $null) )  ) {
        Write-Host -NoNewline "Processing $id..."
        #Write-Progress -ID 1 -Activity $Activity -Status ($StatusText) -PercentComplete ($count / $pTot * 100)
        $title = $xml.html.title
        $title = isJson $title $json

        if ($altTitle) { $altTitle = getAltTitle $altTitle $jsonRawFullFr }
        else { $altTitle = $null; }

        $file = isJson $xml.html.fileName $json
        $file = cleanName $file

        $h1 = $xml.html.header.title
        $h1 = isJson $h1 $json
        $h1 = replaceAmp $h1

        #cleans title and trims
        $title = replaceAmp $title.Trim()

        #check if title contains "Archived" - 2022-07-15 axl618
        If($title -match "(ARCHIVED|ARCHIVÉE)"){$archived = "[gc:page-context/archived/@-archived]"}
        ElseIF($xmlName -match "archived"){write-host "template is $xmlName"; $archived = "[gc:page-context/archived/@-archived]"}
        Else{$archived = ""};

        #sets title to the id - title
        $f = ""
        $f = $op.Replace($dftTitle, $title).Replace($dftFrTitle, $altTitle).Replace($dftText, $h1).Replace($dftHtml, $file)
        $f += $parOp;
        $f += mainChild -xml $xmlChildren -json $json -id $id
        $f += $parEd;
        $f += $ed;

        $altPath = isJson $altXml.html.loc
        $altPath = $altPath.substring($altPath.IndexOf("\content\"), $altPath.length - $altPath.IndexOf("\content\")).replace("\","/")

        $gcFormat = $null; $gcOverFormat = $null; $gcDate = $null; $gcOverDate = $null

        $tar = $xml.SelectNodes('//html/header/meta')
        $tar | % { 
            $k = $_.name;
            if ($k -eq "keywords") { $keywords = isJson $_."#text" $json }
            elseif ($k -eq "subject") { $subject = isJson $_."#text" $json }
            elseif ($k -eq "description") { $description = isJson $_."#text" $json }
            elseif ($k -eq "contributor") { $contributor = isJson $_."#text" $json }
            elseif ($k -eq "contentprovider") { $contentprovider = isJson $_."#text" $json }
            #elseif ($k -eq "gcModified") { $gcDate = isJson $_."#text" $json; $gcFormat = isJson $_.format $json; }
            elseif ($k -eq "gcModifiedOverride") { $gcOverDate = isJson $_."#text" $json; $gcOverFormat = isJson $_.format $json; }
            elseif ($k -eq "gcAltLanguagePeer") { $gcAltLanguagePeer = isJson $_."#text" $json }
        }

        $override = $xml.html.overrideDate
        if ($override -eq "true" -or $override -eq 1) {
            $override = $true
            $gcDate = getDate $gcOverDate $gcOverFormat
            $gcOverDate = getDate $gcOverDate $gcOverFormat
        } else {
            $override = $false
            $gcDate = getDate
            $gcOverDate = ""
        }

        $langAEM = $xml.html.lang
        if ($langAEM -eq "eng") { $langAEMToggle = "en"; $f = $f.Replace($dftLicense, "Open Government Licence"); }
        else { $langAEMToggle = "fr"; $f = $f.Replace($dftLicense, "Licence du gouvernement ouvert"); }
        
        $description = replaceAmp $description
        $keywords = replaceAmp $keywords
        $subject = replaceAmp $subject
        $contributor = replaceAmp $contributor # variable vide
        $contentprovider = replaceAmp $contentprovider # variable vide
        $spacer = "; "
        $eddsmailbox = "EDDSADMING@cra-arc.gc.ca"
        $wbbranch = "PAB/DDPD/PSD/WD"

        $date = getDate
        $f = $f.Replace($dftDate, $date);
        $f = $f.Replace($dftAem, $aem)
        $f = $f.Replace($dftEmail, $conf["settings"]["email"])
        $f = $f.Replace($dftFname, $conf["settings"]["fname"])
        $f = $f.Replace($dftLname, $conf["settings"]["lname"])
        $f = $f.Replace($dftUsername, $conf["settings"]["username"])
        $f = $f.Replace($dftKey, $keywords)
        $f = $f.Replace($dftDesc, $description)
        $f = $f.Replace($dftSubject, $subject)
        $f = $f.Replace($dftAlt, $gcAltLanguagePeer)
        $f = $f.Replace($dftLang, $langAEM)
        $f = $f.Replace($dftLangToggle, $langAEMToggle)
        $f = $f.Replace($dftOverride, $override)
        $f = $f.Replace($dftModifiedDate, $gcDate)
        $f = $f.Replace($dftModOverrideDate, $gcOverDate)
        #$f = $f.Replace($dftbranch, $contributor) 
        if ($contributor -eq $null) {$f = $f.Replace($dftbranch, $wbbranch)#2025-03-17 added ".Replace($dftbranch, $contributor)" - ppd676
        } else {
        $f = $f.Replace($dftbranch, "$contributor$spacer$wbbranch")
        }
        if ($contentprovider -eq $null){ $f = $f.Replace($dftcontributor, $eddsmailbox) #2025-03-17 added ".Replace($dftcontributor, $contentprovider)" - ppd676
        } else {
        $f = $f.Replace($dftcontributor, "$contentprovider$spacer$eddsmailbox")
        } 


        
        $contentTypes = $xml.html.contentTypes
        $ct = "gc:content-types/"

        if ( $contentTypes ) {
            
            $contentTypes = $contentTypes -split ";"
            $text = "["
            foreach ( $c in $contentTypes) {
                $text += $ct + $c
                $text += ","
            }
            $text = $text.substring(0, $text.length-1)
            $text += "]"
        } else {
            $text = "[gc:content-types/acts]"
        }

        $contentTypes = $text
        $f = $f.Replace($dftContentTypes, $contentTypes)

        
        $location = isJson $xml.html.loc

        $loc = $location + $file + "\.content.xml"

        New-Item -ItemType Directory -Force -Path ($location + $file) | Out-Null
         
        $global:mode = $xml.html.mode
        if ($mode -eq $null) { $global:mode = "replace" }

        $incChildren = $xml.html.replaceChildrenAEM

        if ($incChildren -eq 0 -or $incChildren -eq "false" -or $incChildren -eq $null) { $global:incChildren = $false }
        else { $global:incChildren = $true }

        Try {
            <#
            $xDoc = New-Object System.Xml.XmlDocument
            $xDoc.LoadXml($f)
            $xWte = [System.Xml.XmlWriter]::Create($loc)
            $xDoc.Save($xWte)
            $xWte.Close()
            #>
            #New-Item -ItemType Directory -Force -Path ($loc) | Out-Null
            $f | Set-Content $loc -Force -Encoding UTF8

            if ($incChildren -eq $false) {
                $modeArr.Add( $mode ) > $null
                $xmlFilter.Add( $location.substring($location.IndexOf("\content\"), $location.length - $location.IndexOf("\content\")).replace("\","/") + "$file/jcr:content" ) > $null
            }

        }
        Catch {
            $ErrorMessage = $_.Exception.Message
            Remove-Item ($location + $file)
            Write-Color -Text "Object ""$id"" was not processed. Please fix the problem (below) in the JSON/XML and try the executable again.`r`n$ErrorMessage" -Color "DarkYellow"
        }
        
        if ($global:errorLog -eq 0) {
            Write-Color -Text "Done" -Color Green
        }

    }
}

# ////////// Main Content ////////// # 

#sets variables for the placeholders
$dftTitle = "***TITLE***"; $dftText = "***TEXT***"; $dftHtml = "***HTMLFILE***"; $dftDate = "***DATE***"; $dftHeader = "***HEADER***";
$dftFrTitle = "***TITLEFR***"; $dftNum = "***NUMBER***"; $dftNum = "***NUMBER***"; $dftListTemp = "***LTEMPLATE***"; $dftSubject = "***subject***";
$dftUsername = "***username***"; $dftFname = "***fname***"; $dftLname = "***lname***"; $dftLang = "***lang***"; $dftEmail = "***email***";
$dftAem = "***aemgc***"; $dftKey = "***keywords***"; $dftDesc = "***description***"; $dftAlt = "***ALTLOC***"; $dftOverride = "***OVERRIDE***"; $dftcontributor = "***contributor***"; $dftbranch = "***contentprovider***"; $dftArchived = "***ARCHIVED***"; #2022-07-15 added "$dftArchived = "***ARCHIVED***";" axl618
$dftModifiedDate = "***OVERRIDEDATE***"; $dftModOverrideDate = "***MODOVERDATE***"; $dftLangToggle = "***langToggle***"; $dftContentTypes = "***content-types***"
$dftLicense = "***LICENSE***"

#set random number variables
$col1Num = getRandomNumber
$col2Num = getRandomNumber
$panNum = getRandomNumber
$hrNum = getRandomNumber
$txtNum = getRandomNumber

<#
$text = @"
 
 
 
                                        ,   ,                                
                                        `$,  `$,     ,                         
                                        "ss.`$ss. .s'                         
                                ,     .ss`$`$`$`$`$`$`$`$`$`$s,                        
                                `$. s`$`$`$`$`$`$`$`$`$`$`$`$`$`$``$`$Ss                      
                                "`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$o`$`$`$       ,              
                               s`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$s,  ,s               
                              s`$`$`$`$`$`$`$`$`$"`$`$`$`$`$`$""""`$`$`$`$`$`$"`$`$`$`$`$,             
                              s`$`$`$`$`$`$`$`$`$`$s""`$`$`$`$ssssss"`$`$`$`$`$`$`$`$"             
                             s`$`$`$`$`$`$`$`$`$`$'         `"""ss"`$"`$s""              
                             s`$`$`$`$`$`$`$`$`$`$,              `"""""`$  .s`$`$s        
                             s`$`$`$`$`$`$`$`$`$`$`$`$s,...               `s`$`$'  `       
                         `ssss`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####s.     .`$`$"`$.   , s-   
                           `""""`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$#####`$`$`$`$`$`$"     `$.`$'    
                                 "`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####s""     .`$`$`$|     
                                   "`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$##s    .`$`$" `$    
                                   `$`$""`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$"   `    
                                  `$`$"  "`$"`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$S""""'         
                             ,   ,"     '  `$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####s             
                             `$.          .s`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####"            
                 ,           "`$s.   ..ssS`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####"            
                 `$           .`$`$`$S`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$#####"             
                 Ss     ..sS`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$######""              
                  "`$`$sS`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$########"                  
           ,      s`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$#########""'                      
           `$    s`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$#######""'      s'         ,           
           `$`$..`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$######"'       ....,`$`$....    ,`$            
            "`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$######"' ,     .sS`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$s`$`$            
              `$`$`$`$`$`$`$`$`$`$`$`$#####"     `$, .s`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$s.         
   )          `$`$`$`$`$`$`$`$`$`$`$#####'      ``$`$`$`$`$`$`$`$`$###########`$`$`$`$`$`$`$`$`$`$`$.       
  ((          `$`$`$`$`$`$`$`$`$`$`$#####       `$`$`$`$`$`$`$`$###"       "####`$`$`$`$`$`$`$`$`$`$      
  ) \         `$`$`$`$`$`$`$`$`$`$`$`$####.     `$`$`$`$`$`$###"             "###`$`$`$`$`$`$`$`$`$   s'
 (   )        `$`$`$`$`$`$`$`$`$`$`$`$`$####.   `$`$`$`$`$###"                ####`$`$`$`$`$`$`$`$s`$`$' 
 )  ( (       `$`$"`$`$`$`$`$`$`$`$`$`$`$#####.`$`$`$`$`$###'                .###`$`$`$`$`$`$`$`$`$`$"   
 (  )  )   _,`$"   `$`$`$`$`$`$`$`$`$`$`$`$######.`$`$##'                .###`$`$`$`$`$`$`$`$`$`$     
 ) (  ( \.         "`$`$`$`$`$`$`$`$`$`$`$`$`$#######,,,.          ..####`$`$`$`$`$`$`$`$`$`$`$"     
(   )`$ )  )        ,`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$####################`$`$`$`$`$`$`$`$`$`$`$"       
(   (`$`$  ( \     _sS"  `"`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$S`$`$,       
 )  )`$`$`$s ) )  .      .   ``$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$"'  ``$`$      
  (   `$`$`$Ss/  .`$,    .`$,,s`$`$`$`$`$`$##S`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$S""        '      
    \)_`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$##"  `$`$        ``$`$.        ``$`$.                
        `"S`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$#"      `$          ``$          ``$                
            `"""""""""""""'         '           '           '
                  
                  
"@

Write-Host $text
#>


#Update data-readme file
$rmPath = $dir + "\db\data-readme.xml";

#Append : to alternate formats - 2022-07-15 axl618
[regex]$altRegex = "</(eText|largePrint|braille|pdf)>"
$rm = (Get-Content $rmPath -Encoding UTF8) ; Start-Sleep -s 1
If((!($rm -match ":</(eText|largePrint|braille|pdf)>")) -and ($rm -match "</(eText|largePrint|braille|pdf)>")){$rm | ForEach-Object {$altRegex.Replace($_, {":"+$args[0]})} | Set-Content $rmPath -Encoding UTF8}
Start-Sleep -s 1;

#Add uppercase name element to data-readme.xml - 2021-03-23 axl618
[regex]$rmRegex = "<name>.*?</name>"
$rm = (Get-Content $rmPath -Encoding UTF8) ; Start-Sleep -s 1
If(!($rm -match "<upname>")){$rm | ForEach-Object {$rmRegex.Replace($_, {$args[0].value.toLower() +"`n`t`t"+
                                                                         $args[0].value.toUpper().Replace("NAME","upname")})} | Set-Content $rmPath -Encoding UTF8}
Start-Sleep -s 1;


Write-Color -Text "D2GC (Data to Government of Canada)" -Color "White"
Write-Host "-----------------------------------`r`n"

Write-Color -Text "Phase 1" -Color "Red"

$configPath = ($dir + "\config.ini")
if (Test-Path $configPath) {
    Write-Host "There is a ""config.ini"" file"
    Write-Host "The following is entered in the ""config.ini"" file:`n`r"
    displayIni
    if ( $confirm -ne "true" ) {
        $q = Read-Host "`n`rIs this correct: [Y]es [N]o (default/nil input is ""Yes"")"
    }
    if ($q -eq "n" -or $q -eq "N") {
        Remove-Item ($dir + "\config.ini")
        $config = configIni
        oif -InputObject $config -FilePath ($dir + "\config.ini")
    }
}
else {
    Write-Host "There is no ""config.ini"" file in the folder. This will be a one time entry`n`r"
    $config = configIni
    oif -InputObject $config -FilePath ($dir + "\config.ini")
}




$pTot = 0
<#
$p  | Get-ObjectMembers | ForEach {
    $pTot++
}

$Activity = "Generating AEM Accessible XML files using the template and JSON data"
$StatusText = "Please wait..."
$StatusBlock = [ScriptBlock]::Create($StatusText)
#>
$count = 0

Write-Color -Text "`n`rPhase 2" -Color "Red"

Write-Host "`nRemoving previous files, one moment please"
$getChild = ($dir + "\data\jcr_root\content\canadasite")
$child = ($dir + "\data\jcr_root\content\canadasite\*")

function Get-Tree($Path,$Include='*') { 
    @(Get-Item $Path -Include $Include -Force) + 
        (Get-ChildItem $Path -Recurse -Include $Include -Force) | 
        sort pspath -Descending -unique
} 

function Remove-Tree($Path,$Include='*') { 
    Try {
        Get-Tree $Path $Include | Remove-Item -force -recurse -ErrorAction Stop -ErrorVariable x
        Write-Host "`tDone"
    } Catch {
        write-color -text "You have a file explorer open on one of the nodes that it is removing. Please see error below:`r`n$x" -Color "DarkYellow"
        Read-Host "`r`nPress any key to exit..."
        exit
    }
} 

if ( Test-Path($getChild) ) {
    Remove-Tree $child
} else { Write-Host "`tComplete data folder is not found.. please place the complete data folder and try again"; }

[System.Collections.ArrayList]$xmlFilter = @()
[System.Collections.ArrayList]$modeArr = @()
[System.Collections.ArrayList]$typeArr = @()

#sets the xml template
$xmlRoot = Get-ChildItem $dir -Filter "template-*.xml" -Recurse

if ($xmlRoot.count -ne 0) {
    $xmlRoot | % { 
        $xmlPath = $_.FullName
        $xmlName = $_.Name

        if ($xmlPath -like "*-eng.xml") {
            $altXmlPath = $xmlPath -replace "-eng.xml", "-fra.xml"
        } else {
            $altXmlPath = $xmlPath -replace "-fra.xml", "-eng.xml"
        }

        #$xmlPath = @("$dir\template-eng.xml","$dir\template-fra.xml");

        #for ($i = 0; $i -lt 2; $i++) {
        if ( Test-Path($altXmlPath) ) {
            $e = @(0,0)
            #[System.Io.File]::ReadAllText($xmlPath) | Out-File -FilePath $xmlPath -Encoding UTF8
            #[System.Io.File]::ReadAllText($altXmlPath) | Out-File -FilePath $altXmlPath -Encoding UTF8

            <#
            $xmlP = Get-Content $xmlPath
            write-host $xmlP
            #$xmlP = [System.Io.File]::ReadAllText( $xmlPath, [Text.Encoding]::GetEncoding('iso-8859-1') )
            [System.IO.File]::WriteAllLines($xmlPath, $xmlP)
            #>

            [xml]$xml = [IO.File]::ReadAllText( $xmlPath, [Text.Encoding]::GetEncoding('iso-8859-1') )
            [xml]$altXml = [IO.File]::ReadAllText( $altXmlPath, [Text.Encoding]::GetEncoding('iso-8859-1') )

            #sets the raw path of the json being used
            $p = isJson $xml.html.data
            $pAlt = isJson $altXml.html.data

            $ext = [IO.Path]::GetExtension($p)
            $extAlt = [IO.Path]::GetExtension($pAlt)

            if ($ext -eq ".xml") {
                Try {
                    [System.Io.File]::ReadAllText($p) | Out-File -FilePath $p -Encoding UTF8
                    $x = [xml]([IO.File]::ReadAllText( $p, [Text.Encoding]::GetEncoding('iso-8859-1') ))
                } Catch {
                    Write-Warning "The XML either does not validate or is improperly structured. Please fix the XML and try again"
                    Read-Host "`r`nPress any key to exit..."
                    exit
                }

                $p = ConvertFrom-Xml -InputObject $x
                $p = $p | ConvertTo-Json -Compress
                $p = ParseJsonString $p
            }
            elseif ($ext -eq ".json") {
                $p = ParseJsonFile $p
            }
            else {
                Write-Warning "Please include a supported extension (.json or .xml) in the XML template data field"
                Read-Host "`r`nPress any key to exit..."
                exit
            }

            if ($extAlt -eq ".xml") {
                Try {
                    [System.Io.File]::ReadAllText($pAlt) | Out-File -FilePath $pAlt -Encoding UTF8
                    $xAlt = [xml]([IO.File]::ReadAllText( $pAlt, [Text.Encoding]::GetEncoding('iso-8859-1') ))
                } Catch {
                    Write-Warning "The Alternate Language XML either does not validate or is improperly structured. Please fix the Alternate Language XML and try again"
                    Read-Host "`r`nPress any key to exit..."
                    exit
                }

                $pAlt = ConvertFrom-Xml -InputObject $xAlt
                $pAlt = $pAlt | ConvertTo-Json -Compress
                $pAlt = ParseJsonString $pAlt
            }
            elseif ($extAlt -eq ".json") {
                $pAlt = ParseJsonFile $pAlt
            }
            else {
                Write-Warning "Please include a supported extension (.json or .xml) in the Alternate Language XML template data field"
                Read-Host "`r`nPress any key to exit..."
                exit
            }

            #sets the value x with all nodes under the tag html METADATA Child nodes
            $x = $xml.html.ChildNodes

            #sets the value x with all nodes under the tag html METADATA Child nodes
            $xAlt = $altXml.html.ChildNodes

            <#
            if ( $i -eq 0) { $e = @(0,0); Write-Host "Generating English AEM Accessible XML files using the template and JSON data`n`r`tPlease Wait..." }
            else { Write-Host "Generating French AEM Accessible XML files using the template and JSON data`n`r`tPlease Wait..." }
            #>
            Write-Host "Generating AEM Accessible XML files using the $xmlName template and JSON data`n`r`tPlease Wait..."

            $conf = gic "$dir\config.ini"
            #$f = $f.Replace($dftLang, $xml.html.lang)
            $aem = $conf["settings"]["aemgcEng"];

            $level = $xml.html.depth
            $global:altLevel = $altXml.html.depth

            if ($level -eq "1") {
                Get-ObjectMembers -obj $p | ForEach {
                    main $_ $xml $x $p $xAlt $pAlt
                }
            } elseif ($level -eq "2") {
                Get-ObjectMembers -obj $p | ForEach { 
                    Get-ObjectMembers -obj $_.Value | ForEach {
                        main $_ $xml $x $p $xAlt $pAlt
                    }
                }
            } elseif ($level -eq "3") {
                Get-ObjectMembers -obj $p | ForEach { 
                    Get-ObjectMembers -obj $_.Value | ForEach {
                        Get-ObjectMembers -obj $_.Value | ForEach {
                            main $_ $xml $x $p $xAlt $pAlt
                        }
                    }
                }
            } else {

                $cntA = 0
                $cntB = 0

                $h = Get-ObjectMembers -obj $p | ForEach {
                        $cntA++
                }

                $h = Get-ObjectMembers -obj $p | ForEach {
                    Get-ObjectMembers -obj $_.Value | ForEach {
                        $cntB++
                    }
                }

                #write-host "A: $cntA ; B: $cntB"

                if ($cntA -lt 2) {
                    Get-ObjectMembers -obj $p | ForEach { 
                        Get-ObjectMembers -obj $_.Value | ForEach {
                            main $_ $xml $x $p $xAlt $pAlt
                        }
                    }
                } else {
                    Get-ObjectMembers -obj $p | ForEach {
                        main $_ $xml $x $p $xAlt $pAlt
                    }
                }
            }

            $location = isJson $xml.html.loc
            $type = $xml.html.loc
            #write-host $incChildren
            if ($incChildren) {
                $xmlFilter.Add( $location.substring($location.IndexOf("\content\"), $location.length - $location.IndexOf("\content\")).replace("\","/") ) > $null
                $modeArr.Add( $mode ) > $null
            }
            #$xmlFilter.Add( $location.substring($location.IndexOf("\content\"), $location.length - $location.IndexOf("\content\")).replace("\","/") ) > $null

            #Write-Progress -ID 1 -Activity $Activity -Completed
            Write-Color -Text "Success!" -Color "Green"
            Write-Host The files have been written to $location`n`r

        } else {
            Write-Warning "There is no ""template-*-eng.xml"" and/or ""template-*-fra.xml"" in the folder where the executable was launched, please place the ""template-*-eng.xml"" and ""template-*-fra.xml"" in any proceeding folder and try again."
            $e = 0;
        }
    }

} else {
    Write-Warning "There is no ""template-*-eng.xml"" and/or ""template-*-fra.xml"" in the folder where the executable was launched, please place the ""template-*-eng.xml"" and ""template-*-fra.xml"" in any proceeding folder and try again."
    $e = 0;
}

if ($e) {
    Write-Color -Text "`n`rPhase 3" -Color "Red"

    Write-Host "Applying the an incremented version number by 0.0.01 for AEM backup to a previous version...`n`r"
    $mPath = $dir + "\data\META-INF\vault\"

    $path = $mPath + "properties.xml"

    [xml]$pXml = Get-Content ($path) -Force
    #( Select-Xml -Path ($path) -XPath / ).Node
    <#
    $hash = hashIni
    $specs = New-Object PSObject -Property $hash
    [xml]$pXml = $specs | % { "<?xml version=""1.0"" encoding=""utf-8"" standalone=""no""?>`n`r<!DOCTYPE properties SYSTEM ""http://java.sun.com/dtd/properties.dtd""[]>" } { '<properties>'} { $_.psobject.properties | % { "`t<comment>FileVault Package Properties</comment>" } {"`t<entry key=""$($_.name)"">$($_.value)</entry>"} } {'</properties>'}
    #>

    #$pXml.Load($path)

    $target =  $pXml.SelectNodes('//properties/entry')
    
    $name = $conf["settings"]["file"]
    if (!$name) { $name = "gc-" + $conf["settings"]["acr"] }

    $target | % {
        $k = $_.key;

        if ($k -eq "version") {
            $first2 = $_.InnerText.SubString( 0, $_.InnerText.LastIndexOf('.') )
            $num = [int]$_.InnerText.Split(".")[-1]
            $num++
            $fin = ($first2 + "." + $num)
            $_.InnerText = $fin
        }
        elseif ($k -eq "createdBy" -or $k -eq "lastModifiedBy" -or $k -eq "lastWrappedBy") {
            $_.InnerText = $conf["settings"]["username"];
        }
        elseif ($k -eq "lastModified" -or $k -eq "created" -or $k -eq "lastWrapped") {
            $_.InnerText = getDateProp
        }
        elseif ($k -eq "name") {
            $_.InnerText = $name
        }
    }
    $pXml.Save($path)
    
    #2022-10-28 - axl618: added these 2 lines to remove square brackets from properties.xml file since it was preventing uploads
    $pXml2 = Get-Content -Path $path -Encoding UTF8 -Raw
    $pXML2.replace("[]","") | Set-Content -Path $path -Encoding UTF8;  

    <#
    $pXml.properties.entry
    $xml.properties.entry.values"#text" = "$variable"
    $xml.Save('D:\test.xml')
    #>
    Write-Host "Updating page location in filters as per the template.xml...`n`r"


    $final = $opXml
    $final2 = $opXml;
    $zip = ""; $zip2 = "";

    for ($i = 0; $i -lt $xmlFilter.count; $i++) {
        if ( $modeArr[$i] ) {
            if ( $modeArr[$i] -eq "multiple" ) {
                $xmlFilterT = ( $xmlFilter[$i].Substring(0,$xmlFilter[$i].Length-12) );
                $final += "`t<filter root=""" + $xmlFilter[$i] + """ mode=""replace""/>`n"
                $final2 += "`t<filter root=""" + $xmlFilterT + """ mode=""replace""/>`n"
            } else {
                $final += "`t<filter root=""" + $xmlFilter[$i] + """ mode=""" + $modeArr[$i] + """/>`n"
            }
        } else {
            $final += "`t<filter root=""" + $xmlFilter[$i] + """/>`n"
        }
    }
    $final += $EdXml

    $path = $mPath + "filter.xml"
    $final | Set-Content $path -Force

    Write-Color -Text "Success!" -Color "Green"
    
    Write-Color -Text "`n`rPhase 4" -Color "Red"

    Write-Host "Creating zip file containing the generated files for sending to the Principal Publisher`n`r`tPlease wait...`n`r"

    $jcr = $dir + "\data\jcr_root\"
    $meta = $dir + "\data\META-INF\"

    if ($zipDir) {
        $zip = ( "$zipDir\$name-$fin.zip")
        if ( !(Test-Path $zipDir) ) {
            Write-Color -Text "`nFolder placed in zipDir param incorrect/no folder found, replacing with default directory path`n" -Color "Red"
            $zip = ( "$dir\$name-$fin.zip" )
        }
    } else {
        $zip = ( "$dir\$name-$fin.zip" )
    }

    dir @($jcr,$meta) -recurse | oz -ZipFile $zip -HideProgress


    ## If there is multiple

    if ($final2 -ne $opXml) {
        
        $final2 += $EdXml

        $path = $mPath + "filter.xml"
        $final2 | Set-Content $path -Force
    
        Write-Color -Text "`n`rCreating a rebuild zip file" -Color "Red"

        Write-Host "Creating zip file containing the generated files for sending to the Principal Publisher`n`r`tPlease wait...`n`r"

        if ($zipDir) {
            $zip2 = ( "$zipDir\$name-$fin.zip")
            if ( !(Test-Path $zipDir) ) {
                Write-Color -Text "`nFolder placed in zipDir param incorrect/no folder found, replacing with default directory path`n" -Color "Red"
                $zip2 = ( "$dir\rebuild-$name-$fin.zip" )
            }
        } else {
            $zip2 = ( "$dir\rebuild-$name-$fin.zip" )
        }

        $mPath = $dir + "\data\META-INF\vault\"

    $path = $mPath + "properties.xml"

    [xml]$pXml = Get-Content ($path) -Force

    $target =  $pXml.SelectNodes('//properties/entry')
    
    $name = $conf["settings"]["file"]
    if (!$name) { $name = "gc-" + $conf["settings"]["acr"] }

    $target | % {
        $k = $_.key;

        if ($k -eq "name") {
            $_.InnerText = "rebuild-$name"
        }
    }
    $pXml.Save($path)

    #2022-10-28 - axl618: added these 2 lines to remove square brackets from properties.xml file since it was preventing uploads
    $pXml2 = Get-Content -Path $path -Encoding UTF8 -Raw
    $pXML2.replace("[]","") | Set-Content -Path $path -Encoding UTF8;  

        dir @($jcr,$meta) -recurse | oz -ZipFile $zip2 -HideProgress

    }


    $path = $mPath + "filter.xml"
    $final | Set-Content $path -Force

    Write-Color -Text "Success!" -Color "Green"
    if ($zip2) {
        Write-Host "The file location for the main zip is $zip`nThe file location for the rebuild is $zip2"
    } else {
        Write-Host "The file location for the main zip is $zip"
    }
}
if ( $confirm -ne "true" ) {
    Read-Host "`r`nPress any key to exit..."
}
exit

<#
if (!(Test-Xml -Path "C:\Users\Adam\Desktop\gc-cra-cvitp\source.xml" -Schema "C:\Users\Adam\Desktop\gc-cra-cvitp\source.xsd")) {
    write-host "Going forward"
}
else {
    write-Host "Please fix the errors"
}
#>
