#!/usr/bin/perl
use Math::Trig;


$level=15;
$latStart = 54.70;
$lonStart = 9.82;
$latEnde = 54.57;
$lonEnde = 10.08;

($xstart, $ystart) = getTileNumber($latStart,$lonStart,$level);
($xende,  $yende)  = getTileNumber($latEnde, $lonEnde, $level);
$xanz = $xende-$xstart;
$yanz = $yende-$ystart;

$urlOSM="http://a.tile.openstreetmap.org";
$urlOSeaMap="http://tiles.openseamap.org/seamark";


# Status anzeigen
print ("Anzahl x: $xanz\n");
print ("Anzahl y: $yanz\n");

($dummy, $lonStart, $latStart, $$dummy) = Project($xstart,$ystart,$level);
($latEnde, $dummy, $dummy, $lonEnde) = Project($xende,$yende,$level);
print (" -> $latStart, $lonStart, $latEnde, $lonEnde \n"); 

# Aufräumen
`rm *.png *.log`;

# liegt es im Rahmen?
if ($xanz*$yanz > 25*25) {
   die "Zu viele Teile";
}
# Hauptschleife
for ($x=$xstart; $x<$xstart+$xanz; $x++){
   for ($y=$ystart; $y<$ystart+$yanz; $y++){
       print ("Level, X, Y = $level, $x, $y\n");
       `wget "$urlOSM/$level/$x/$y.png" -o "$level-$y-$x.log" -O "$level-$y-$x.png" `;
       `wget "$urlOSeaMap/$level/$x/$y.png" -o log -O "SeaMap-$level-$y-$x.png" `;
       if ( -e "SeaMap-$level-$y-$x.png"){ 
          unless ( -z "SeaMap-$level-$y-$x.png"){
             `convert -type PaletteMatte -matte -transparent "#F8F8F8" "SeaMap-$level-$y-$x.png" "SeaMap-$level-$y-$x.png"`; 
             `composite "SeaMap-$level-$y-$x.png" "$level-$y-$x.png" "$level-$y-$x.png"` 
          }
          `rm "SeaMap-$level-$y-$x.png"`;
       }
   }
}
`montage +frame +shadow +label -tile "$xanz x $yanz" -geometry 256x256+0+0 *.png joined.png`;



sub getTileNumber {
   my ($lat,$lon,$zoom) = @_;
   my $xtile = int( ($lon+180)/360 *2**$zoom ) ;
   my $ytile = int( (1 - log(tan(deg2rad($lat)) + sec(deg2rad($lat)))/pi)/2 *2**$zoom ) ;
   return ($xtile, $ytile);
}

sub Project {
  my ($X,$Y, $Zoom) = @_;
  my $Unit = 1 / (2 ** $Zoom);
  my $relY1 = $Y * $Unit;
  my $relY2 = $relY1 + $Unit;
 
  # note: $LimitY = ProjectF(degrees(atan(sinh(pi)))) = log(sinh(pi)+cosh(pi)) = pi
  # note: degrees(atan(sinh(pi))) = 85.051128..
  # my $LimitY = ProjectF(85.0511);
 
  # so stay simple and more accurate
  my $LimitY = pi;
  my $RangeY = 2 * $LimitY;
  $relY1 = $LimitY - $RangeY * $relY1;
  $relY2 = $LimitY - $RangeY * $relY2;
  my $Lat1 = ProjectMercToLat($relY1);
  my $Lat2 = ProjectMercToLat($relY2);
  $Unit = 360 / (2 ** $Zoom);
  my $Long1 = -180 + $X * $Unit;
  return ($Lat2, $Long1, $Lat1, $Long1 + $Unit); # S,W,N,E
}
sub ProjectMercToLat($){
  my $MercY = shift;
  return rad2deg(atan(sinh($MercY)));
}
sub ProjectF{
  my $Lat = shift;
  $Lat = deg2rad($Lat);
  my $Y = log(tan($Lat) + sec($Lat));
  return $Y;
}
