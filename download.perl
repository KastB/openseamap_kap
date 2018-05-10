#!/usr/bin/perl
use Math::Trig;


$level_start=16;
$level_end=18;
$latStart = 47.82;
$lonStart = 8.86;
$latEnde = 47.42;
$lonEnde = 9.8;



$urlOSM="http://a.tile.openstreetmap.org";
$urlOSM="http://localhost:8008/hot";
$urlOSeaMap="/export/home/bernd/src/renderer/work/tiles";

for ($level=$level_start; $level < $level_end + 1; $level++) {

	
	($xstart, $ystart) = getTileNumber($latStart,$lonStart,$level);
	($xende,  $yende)  = getTileNumber($latEnde, $lonEnde, $level);
	$yende = $yende + 1;
	$xende = $xende + 1;

	$xanz = $xende-$xstart;
	$yanz = $yende-$ystart;
	
	# Status anzeigen
	print ("Anzahl x: $xanz\n");
	print ("Anzahl y: $yanz\n");

	`mkdir result`;
	`rm *.png`;
	`rm *.kap`;
	
	($dummy, $lonStart, $latStart, $$dummy) = Project($xstart,$ystart,$level);
	($latEnde, $dummy, $dummy, $lonEnde) = Project($xende,$yende,$level);
	print (" -> $latStart, $lonStart, $latEnde, $lonEnde \n"); 

	# Aufräumen
	`rm *.png *.log`;

	# liegt es im Rahmen?
	#if ($xanz*$yanz > 25*25 * 3) {
	#   die "to many tiles" + $xanz*$yanz;
	#}
	# Hauptschleife
	if (1 == 2) {
		for ($x=$xstart; $x<$xstart+$xanz; $x++){
		   for ($y=$ystart; $y<$ystart+$yanz; $y++){
			   print ("Level, X, Y = $level, $x, $y\n");
			   print("wget $urlOSM/$level/$x/$y.png -o $level-$y-$x.log -O $level-$y-$x.png\n");
			   `wget "$urlOSM/$level/$x/$y.png" -o "wget.log" -O "$level-$y-$x.png" `;
			   `cp "$urlOSeaMap/$level/$x/$y.png" "SeaMap-$level-$y-$x.png" 2> cp.log`;
			   if ( -e "SeaMap-$level-$y-$x.png"){ 
				  unless ( -z "SeaMap-$level-$y-$x.png"){
					 `convert -type PaletteMatte -matte -transparent "#F8F8F8" "SeaMap-$level-$y-$x.png" "SeaMap-$level-$y-$x.png"`; 
					 `composite "SeaMap-$level-$y-$x.png" "$level-$y-$x.png" "$level-$y-$x.png"` 
				  }
				  `rm "SeaMap-$level-$y-$x.png"`;
			   }
		   }
		}
	}
	print ("montage -limit memory 8000000 +frame +shadow +label -tile '$xanz x $yanz' -geometry 256x256+0+0 '*.png' joined$level.png\n");
	print("imgkap joined$level.png $latStart $lonStart $latEnde $lonEnde joined$level.kap\n");
	`montage -limit memory 8000000 +frame +shadow +label -tile "$xanz x $yanz" -geometry 256x256+0+0 "*.png" joined$level.png`;
	`imgkap joined$level.png $latStart $lonStart $latEnde $lonEnde joined$level.kap`;
	`mv joined$level.kap joined$level.png result`;
}

sub getTileNumber {
   my ($lat,$lon,$zoom) = @_;
   my $xtile = int( ($lon+180.0)/360.0 *2.0**$zoom ) ;
   my $ytile = int( (1.0 - log(tan(deg2rad($lat)) + sec(deg2rad($lat)))/pi)/2.0 *2.0**$zoom ) ;
   return ($xtile, $ytile);
}

sub Project {
  my ($X,$Y, $Zoom) = @_;
  my $Unit = 1 / (2.0 ** $Zoom);
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
  $Unit = 360.0 / (2.0 ** $Zoom);
  my $Long1 = -180.0 + $X * $Unit;
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
