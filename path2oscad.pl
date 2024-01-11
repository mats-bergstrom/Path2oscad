#! /usr/bin/perl -w

$fnam = shift;

die "No file name\n" if ( !$fnam );

$in_path = 0;
$d = '';
$lbl = '';
open(F,'<',$fnam) or die "Failed to open file: $fnam\n";
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
print "OK\n";



sub doPath {
    ($L,$s) = @_;

    $is_abs = 0;
    my @X = ();
    my @Y = ();
    my $n = 0;

    my $px = 0;			# Previous x and y
    my $py = 0;
    
    print "LBL : $L\n";
    print "PTH : $s\n";

    
    $c = substr($s,0,1);
    $s = substr($s,1);
    
    if ( $c eq 'm' ) {
	$is_abs = 0;
    }
    elsif ( $c eq 'M' ) {
	$is_abs = 1;
    }
    else {
	printf("Path not linesegments.  Ignored.\n");
	return;
    }

    B: while ( length($s) > 0 ) {
	my $dx = 0;
	my $dy = 0;
	my $bad = 0;
	my $at_end = 0;

#	print "AT: \"$s\"\n";
	A: while ( !$at_end ) {
	    # h 123.456
	    $s =~ s/^\s*[hH]\s+([+-]?\d*\.?\d+)\s+// && do {
		$dx = $1;
		$dy = 0;
		last A;
	    };

	    # v 123.456
	    $s =~ s/^\s*[vV]\s+([+-]?\d*\.?\d+)\s+// && do {
		$dy = $1;
		$dx = 0;
		last A;
	    };

	    # [lL]? 123.456,321.654
	    $s =~ s/^\s*([lL]\s+)?([+-]?\d*\.?\d+),([+-]?\d*\.?\d+)\s+// && do {
		$dx = $2;
		$dy = $3;
		last A;
	    };

	    $s =~ s/^\s*[zZ]// && do {
		$at_end = 1;
		last A;
	    };
	    
	    printf "Not recognised: \"$s\"\n";
	    return;
	};

#	print "\t($dx,$dy)\n";

	if ( !$at_end ) {
	    my $x = $dx + $px;
	    my $y = $dy + $py;
	    if ( !$is_abs ) {
		$px = $x;
		$py = $y;
	    }
	    push @X,$x;
	    push @Y,$y;
	    ++$n;
	}
    }

    if ($n) {
	my $i;
	open(P,">","path_$L.scad") or die "Unable to create file\n";
	print P "// Generated file\n\n";
	print P "path_$L = \[\n";
	for ( $i = 0; $i < $n; ++$i ) {
	    print P "\t\t\[$X[$i],$Y[$i]\],\n"
	}
	print P "\t\];\n\n";
	close(P);
    }
    
    print "\n";
    
}
