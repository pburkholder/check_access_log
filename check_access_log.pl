#!/usr/bin/perl 

# This plugin processes a logfile ( -l ) in the httpd common access format and
# report on all status entries for last ( -m ) minutes
use strict;
use warnings;

use File::ReadBackwards;
use Date::Manip;
use Nagios::Plugin;
use vars qw($VERSION $PROGNAME  $verbose $warn $critical $timeout $result);
$VERSION = '1.0';

# get the base name of this script for use in the examples
use File::Basename;
$PROGNAME = basename($0);

sub parse {
# Lifted from
# http://cpansearch.perl.org/src/MSLAGLE/Parse-AccessLogEntry-0.06/AccessLogEntry.pm
        my $Line=shift;
        my $Ref;
        my $Rest;
        my $R2;
        ($Ref->{host},$Ref->{user},$Ref->{date},$Rest)= $Line =~ m,^([^\s]+)\s+-\s+([^ ]+)\s+\[(.*?)\]\s+(.*),;
        my @Dsplit=split(/\s+/,$Ref->{date});
	    $Ref->{diffgmt}=$Dsplit[1];
	    my @Ds2=split(/\:/,$Dsplit[0],2);
        $Ref->{date}=$Ds2[0];
        $Ref->{time}=$Ds2[1];
        if ($Rest) {
                ($Ref->{rtype},$Ref->{file},$Ref->{proto},$Ref->{code},$Ref->{bytes},$R2)=split(/\s/,$Rest,6);
# Removing following processing improves run by 10% - PDB
#		$Ref->{rtype}=~tr/\"//d;
#		$Ref->{proto}=~tr/\"//d;
#                if ($R2)
#                {
#                        my @Split=split(/\"/,$R2);
#                        $Ref->{refer}=$Split[1];
#                        $Ref->{agent}=$Split[3];
#                }
        }
        return $Ref;
}

my %regex_for = (
    '20X'   => '2\d\d',
    '30X'   => '3\d\d',
    '403'   => '403',
    '404'   => '404',
    '40X'   => '4\d[^3-4]',
    '500'   => '500',
    '503'   => '503',
    '50X'   => '50(1|2|4|5)',
    'no_status'  => '-',
    );

# use Nagios::Plugin::Getopt to process the @ARGV command line options:
#   --verbose, --help, --usage, --timeout and --host are defined automatically.
my $np = Nagios::Plugin->new( 
    shortname => "ACCESS_STATUS",  
    usage => "Usage: %s [ -v|--verbose ] -l|--logfile=file -m|--m=minutes " .
    "[ -c|--critical=<threshold>(20)  ] [ -w|--warning=<threshold>(10) ] ".
    "[ -a|--activity=number_of_lines (100) ]",
    blurb => "Report status summary for the last minutes of an httpd access log"
);

# Parse arguments and process standard ones (e.g. usage, help, version)
$np->add_arg(
        spec => 'logfile|l=s',
        help => qq{-l, --logfile=STRING},
        required => 1,
);
$np->add_arg(
        spec => 'minutes|m=i',
        help => qq{-m, --minutes=INTEGER},
	    default => 5,
);
$np->add_arg(
        spec => 'debug|D+',
        help => qq{-D, --debug},
);
$np->add_arg(
	spec => 'warning|w=i',
	help => qq{-w, --warning=FLOAT Warn when % failures is above the specified threshold},
	default => 10,
);
$np->add_arg(
	spec => 'critical|c=i',
	help => qq{-c, --critical=FLOAT Critical when % failures is above the specified threshold},
	default => 20,
);

$np->add_arg(
	spec => 'activity|a=i',
	help => qq{-a, --activity=INTEGER Only go to critical or warning if log activity exceeds threshold},
	default => 100,
);
$np->getopts;

my $threshold = $np->set_thresholds(
    warning     => $np->opts->warning,
    critical    => $np->opts->critical,
);
my $log_file= $np->opts->logfile or $np->nagios_die("No input logfile defined");
my $minutes = $np->opts->minutes;
my $DEBUG   = $np->opts->debug;
my $start   = DateCalc ("epoch ".time(),"$minutes minutes ago");
#my $start   = "2010092012:59:30"; # sample for multiple runs on same file

my %status_score;   # initialize score card
my $lines=0;
my $bytes_served=0;
my $matched='';

tie *BW, 'File::ReadBackwards', $log_file or 
    $np->nagios_die("can't read $log_file $!") ;

print STDERR "Opening $log_file\n" if $np->opts->verbose;

# Start looping backward thru logfile
my $prior_logdate="";    # Set prior lines' logdate to nothing
while (<BW>) {
    my $line_ref    = parse($_);
    # skip tests from load-balancers
    next if ($line_ref->{host} =~ m/^192\.168\.30\.1/);                                                               
    if ( ( $lines %1000 == 0 ) and $np->opts->verbose) {
        print STDERR "line: $lines\n";
        print $_;
    }
    $lines++;
    my $logdate     = $line_ref->{date} . " " . $line_ref->{time};
    if ( $logdate eq $prior_logdate || ParseDate($logdate) gt $start ) {
        $prior_logdate = $logdate;
        my $status = $line_ref->{code};
        print $_ if (($status eq '-' ) and  $np->opts->verbose);
        $matched='false';
        $bytes_served += $line_ref->{bytes} if ($line_ref->{bytes} ne '-');
        foreach my $status_key (keys %regex_for) {
            if ( $status =~ m/$regex_for{$status_key}/x ) {
                $status_score{$status_key}++;
                $matched='true';
                last;               # break out of status_key foreach
            }
        }
        $status_score{'other'}++ if ( $matched eq 'false' );
    } else {
        last;                       # break out of <BW>;
    }
}

my $failure_rate=
    sprintf("%0.2f", 100 - (($status_score{'20X'} + $status_score{'30X'})/$lines) * 100.0);

$np->add_perfdata(
    label   => 'Total',
    value   => $lines,
);

$np->add_perfdata(
    label   => 'FAIL',
    value   =>  $failure_rate,
    uom     => '%',
    threshold => $threshold,
);

$np->add_perfdata(
    label   => 'BytesServed',
    uom     => 'kB',
    value   => 
        int($bytes_served/1024),

);

foreach my $key (sort keys %regex_for) {
    $np->add_perfdata(
        label   => $key,
        value   => $status_score{$key}||0,
    );
}

$np->add_perfdata(
    label   => 'Other',
    value   => $status_score{'other'}||0,
);


# We will return OK for this check
# unless the number of lines exceeds the activity threshold
my $return_code = 0;  
if ( $lines > $np->opts->activity ) {
    $return_code = $np->check_threshold($failure_rate);
} 

#return_code => $return_code,
$np->nagios_exit( 
	 return_code => $return_code,
	 message => "FAILURE_RATE $failure_rate" 
);
