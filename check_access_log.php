<?php
# $Id$
# $URL$
# Peter Burkholder, AARP, Copyright 2010
# License terms are unknown.
define("_WARNRULE", '#FFFF00');
define("_CRITRULE", '#FF0000');
define("_AREA", '#EACC00');
define("_LINE", '#000000');

#

$ds_name[1] = "Access Log Breakdown by Status";
$opt[1] = "--vertical-label \"Loglines/5min\" -l0  --title \"Access Log for  $hostname / $servicedesc\" ";
#
#
$def[1] =  "";
$def[1] .= "DEF:ttl=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] .= "DEF:var1=$rrdfile:$DS[4]:AVERAGE " ;
$def[1] .= "DEF:var2=$rrdfile:$DS[5]:AVERAGE " ;
$def[1] .= "DEF:var3=$rrdfile:$DS[6]:AVERAGE " ;
$def[1] .= "DEF:var4=$rrdfile:$DS[7]:AVERAGE " ;
$def[1] .= "DEF:var5=$rrdfile:$DS[8]:AVERAGE " ;
$def[1] .= "DEF:var6=$rrdfile:$DS[9]:AVERAGE " ;
$def[1] .= "DEF:var7=$rrdfile:$DS[10]:AVERAGE " ;
$def[1] .= "DEF:var8=$rrdfile:$DS[11]:AVERAGE " ;
$def[1] .= "DEF:var9=$rrdfile:$DS[12]:AVERAGE " ;
$def[1] .= "LINE1:ttl#000000:\"Total\" " ;
$def[1] .= "AREA:var1#34E954:\"20X\" " ;
$def[1] .= "STACK:var2#EA8F00:\"30X \" " ;
$def[1] .= "STACK:var3#FABC2E:\"403\" " ;
$def[1] .= "STACK:var4#FABC2E:\"404\" " ;
$def[1] .= "STACK:var5#FABC2E:\"40X\" " ;
$def[1] .= "STACK:var6#407BE2:\"500\" " ;
$def[1] .= "STACK:var7#407BE2:\"503\" " ;
$def[1] .= "STACK:var8#407BE2:\"50X\" " ;
$def[1] .= "STACK:var9#E4203E:\"---\" " ;


$ds_name[2] = "Access Log Percent Failure Rate";
$opt[2] = "--vertical-label \"Failure %\" -l0 -u100 --title \"Failure rate for $hostname / $servicedesc\" ";

$def[2] =  "DEF:percent1=$rrdfile:$DS[2]:AVERAGE " ;
$def[2] .=  "CDEF:sp1=percent1,100,/,12,* " ;
$def[2] .=  "CDEF:sp2=percent1,100,/,30,* " ;
$def[2] .=  "CDEF:sp3=percent1,100,/,50,* " ;
$def[2] .=  "CDEF:sp4=percent1,100,/,70,* " ;

$def[2] .= "AREA:percent1#FF5C00:\"Failed non-200 log entries \" " ;
$def[2] .= "AREA:sp4#FF7C00: " ;
$def[2] .= "AREA:sp3#FF9C00: " ;
$def[2] .= "AREA:sp2#FFBC00: " ;
$def[2] .= "AREA:sp1#FFDC00: " ;


$def[2] .= "GPRINT:percent1:LAST:\"%6.2lf $UNIT[2] last \" " ;
$def[2] .= "GPRINT:percent1:MAX:\"%6.2lf $UNIT[2] max \" " ;
$def[2] .= "GPRINT:percent1:AVERAGE:\"%6.2lf $UNIT[2] avg \\n\" " ;
$def[2] .= "LINE1:percent1#000000:\"\" " ;
if($WARN[2] != ""){
  $def[2] .= "HRULE:".$WARN[2]."#000000:\"Warning ".$WARN[2]."%% \" " ;
}
if($CRIT[2] != ""){
  $def[2] .= "HRULE:".$CRIT[2]."#FF0000:\"Critical ".$CRIT[2]."%% \" " ;
}

$ds_name[3] = "Access Log Total Bytes Served";
$opt[3] = "--vertical-label \"Bytes served\" -l0 --title \"Bytes served for $hostname / $servicedesc\" ";
$def[3] =  "DEF:bytes=$rrdfile:$DS[3]:AVERAGE " ;
$def[3] .= "AREA:bytes#00A9E2:\"bytes \" " ;
$def[3] .= "LINE1:bytes#000000:\"\" " ;
$def[3] .= "GPRINT:bytes:LAST:\"%6.2lf $UNIT[3] last \" " ;
$def[3] .= "GPRINT:bytes:MAX:\"%6.2lf $UNIT[3] max \" " ;
$def[3] .= "GPRINT:bytes:AVERAGE:\"%6.2lf $UNIT[3] avg \\n\" " ;


?>
