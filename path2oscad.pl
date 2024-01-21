#! /usr/bin/perl -w


# Digs out a path in an SVG and translates that to an OpenScad point array.

$fnam = shift;

die "No file name\n" if ( !$fnam );

$snam = "$fnam.scad";
    
$in_path = 0;			# 0/1		inside <path /> or not.
$d = '';			# string	d= value, i.e. path data
$lbl = '';			# string	inkscape:label of the path

open(F,'<',$fnam) or die "Failed to open file: $fnam\n";
open(S,'>',$snam) or die "Failed to open output file: $snam\n";

print S "// Generated file from $fnam\n\n";

while(<F>) {
    chomp;
    
    if ( !$in_path ) {
	$_ =~ /\s*<path\s*/ && do {
	    $in_path = 1;
	};
	next;
    };

    $_ =~ /\s*([^=]+)=\"([^\"]+)\"\s*(\/>)?/ && do {
	$tag = $1;
	$val = $2;
	$X   = ($3 ? $3 : '');

#	print "$tag = $val : ($X)\n";

	if ( $tag eq 'd' ) { $d = $val; }
	if ( $tag eq 'inkscape:label' ) { $lbl = $val; }
	
	if ( $X eq '/>' ) {
	    if ( $lbl ne '' ) {
		doPath( $lbl, $d );
		$d = '';
		$lbl = '';
	    }
	    $in_path = 0;
	}
    };

}
close(F);
close(S);
print "Done\n";



sub doPath {
    ($L,$s) = @_;

    my @X = ();
    my @Y = ();
    my $n = 0;

    my $px = 0;			# Previous x and y
    my $py = 0;
    my $x = 0;			# Current x and y.
    my $y = 0;

    my $bad = 1;
    my $at_end = 0;
    my $mode = '-';
    
    print "LBL : $L\n";
    print "PTH : $s\n";

    print S "// label = $L\n";
    
    while ( length($s) > 0 ) {

	# Regex for floating point numbers
	my $flt = '[+-]?\d*\.?\d+([eE][-+]?\d+)?'; 

	
	# First catch mode
	$s =~ s/^\s*([mMhHvVlLzZ])\s*// && do {
	    $mode = $1;
	    $mode = 'l' if ( $mode eq 'm' );
	    $mode = 'L' if ( $mode eq 'M' );
	    if ( $mode eq 'z' || $mode eq 'Z' ) {
		$at_end = 1;
	    }
	};
	# if not a new mode we keep the current and parse coordinates.

#	print "mode=\"$mode\" : $s\n";

	  
	# l : Relative lineto x,y
	if ( $mode eq 'l' ) {
	    $s =~ s/\s*(?<X>$flt),(?<Y>$flt)//  && do {
		$x = $+{X} + $px;
		$y = $+{Y} + $py;
		$bad = 0;
	    }
	}

	# L: Absolute lineto x,y
	elsif ( $mode eq 'L' ) {
	    $s =~ s/\s*(?<X>$flt),(?<Y>$flt)//  && do {
		$x = $+{X};
		$y = $+{Y};
		$bad = 0;
	    }
	}

	# h: Relative horizontal x
	elsif ( $mode eq 'h' ) {
	    $s =~ s/\s*(?<X>$flt)//  && do {
		$x = $+{X} + $px;
		$y = $py;
		$bad = 0;
	    }
	}

	# H: Absolute horizontal x
	elsif ( $mode eq 'H' ) {
	    $s =~ s/\s*(?<X>$flt)//  && do {
		$x = $+{X};
		$y = $py;
		$bad = 0;
	    }
	}

	# v: Relative vertical x
	elsif ( $mode eq 'v' ) {
	    $s =~ s/\s*(?<Y>$flt)//  && do {
		$y = $+{Y} + $py;
		$x = $px;
		$bad = 0;
	    }
	}

	# V: Absolute vertical x
	elsif ( $mode eq 'V' ) {
	    $s =~ s/\s*(?<Y>$flt)//  && do {
		$y = $+{Y};
		$x = $px;
		$bad = 0;
	    }
	}
	
	# zZ : end.
	elsif ( $mode eq 'z' || $mode eq 'Z' ) {
	    last;
	}

	# No mode...
	else {
	    print "Unrecognised mode. : \"$s\"\n";
	    last;
	}

	last if ( $bad );

	
	$px = $x;
	$py = $y;

#	print "\t($x,$y)\n";

	push @X,$x;
	push @Y,$y;
	++$n;

    }

    if ($n) {
	my $i;
	my $name = "path_$L";
	my $min_X = $X[0];
	my $max_X = $X[0];
	my $min_Y = $Y[0];
	my $max_Y = $Y[0];

	for ( $i = 0; $i < $n; ++$i ) {
	    $min_X = $X[$i] if ( $X[$i] < $min_X );
	    $max_X = $X[$i] if ( $X[$i] > $max_X );
	    $min_Y = $Y[$i] if ( $Y[$i] < $min_Y );
	    $max_Y = $Y[$i] if ( $Y[$i] > $max_Y );
	}
	print S "\n// $L\n";
	print S "$name" . "_xmin = $min_X;\n";
	print S "$name" . "_xmax = $max_X;\n";
	print S "$name" . "_ymin = $min_Y;\n";
	print S "$name" . "_ymax = $max_Y;\n";
	print S "$name = \[\n";
	for ( $i = 0; $i < $n; ++$i ) {
	    print S "\t\t\[$X[$i],$Y[$i]\],\n"
	}
	print S "\t\];\n\n";

    }
    
    print "\n";
    
}
