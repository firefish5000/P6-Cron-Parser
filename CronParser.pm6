#!/usr/bin/perl6
use v6;
use DateTime::Math;
################
# Project Goal #
# To automaticly create rtcwake events for every Cron Job.
#######################
# Implimantation Goal #
# Create an RTC wake event for the next CronJob occuring in 10min+
# By default, Set RTC wake event for 5min prior to CronJob execution time.
# On Wake, Imediantly create the RTCwake event for the next job that meats the criteria.
# Check Every 5min to see if cronfile has changed and update events(create a hook to notify us if possible)
# Allow the user to specify weather to create RTC wake events, both by default, and on individual jobs.
# Check to see if cron has a &wake(1) or similar command once done. (put your hard work to waste)
###############
# SubProjects #
# CronParser, a potentialy usefull Cron:: Grammar && Actions implimentation;
#########
# State #
# Unusable, no support garenty. Future versions will break this and no there will be no backwards compatibility until API version 0.0.1
# The API uses the following naming convention. <Complete Rewrite>.<Incompatible Changes>.<Compatible Changes> [Some testing/development tag/number]?
# For now our API and version is 0.0.0 and our code is broken.
# Other Thoughts:
# I need spell checking for vim or a some other good editor for perl6. (padre was crashing)
# Vim's syntax highlighting is AWFULY SLOW for perl6.
my $CronFile = q:to/HERECRON/;
# &  -  classic cron syntax
# @  -  frequency or timespan (every 30 minutes; with options: best moment within every 30 minutes)
# %  -  (once) within time interval
# bootrun(1|0),b(1|0)  -  Runs cammand at boot if missed
# classic cron syntax:
#
# * * * * * user 'command to be executed'
# - - - - - -
# | | | | | +- - - user to run as (optional) # `echo hello'(without quotations) may try to run `hello' as user `echo'
# | | | | +- - - - day of week (0 - 6) (Sunday=0)
# | | | +- - - - - month (1 - 12)
# | | +- - - - - - day of month (1 - 31)
# | +- - - - - - - hour (0 - 23)
# +- - - - - - - - minute (0 - 59)
###Eg.################################################
## Syncronize portage tree every other day at 03:27 am
## 27 3 */2 * * 'emerge --sync'
!bootrun(false)

# Check If Our External Ip Address Changed Every day
#&mail(no) 29 1 * * * bash /home/beck/BCust/Specific.Anime/Networking/DLink_DSL-2540B/CheckIP.bash -e 'firefish5000@gmail.com firefish6000@gmail.com'

# Get Justin at 3:00
#&mail(no) 0 14 * * 2,4-5  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
#&mail(no) 30 15 * * 2,4-5 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
# Take Them To School
#&mail(no) 0 7,8 * * 1-5  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Take The kids to school at 8:45'
# Go To School at 2:35 for Math
#&mail(no) 00,30 13 * * 1,3 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Go to your math class at 2:35 (14:35)'
#&mail(no) 00 14 * * 1,3 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Go to your math class at 2:35 (14:35)'
# Get Up
#&mail(no) 00 14 * * 0,2,4-6  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Wake Up From 12:00 Nap (2:00)'
#&mail(no) 00 10 * * 0-6  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Asa Dai Yo (6:00)'
&mail(no) 58 4 25-31 8 2,4  export DISPLAY=:0 && amixer sset Master '50%'
&mail(no) 58 4 * 9-12 2,4  export DISPLAY=:0 && amixer sset Master '50%'
&mail(no) 00 5 25-31 8 2,4  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'School At 6:00  (Leave by 5:45) (5:00)'
&mail(no) 00 5 * 9-12 2,4  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'School At 6:00  (Leave by 5:45) (5:00)'
HERECRON

role DynamicRange { # Rethink the role's and method's name.
	method !SmartRange ($from, $to) { 
		if ($from <= $to) {
			return $from..$to;
		} else {
			return ($to..$from).reverse;
		}
	}
}

class Cron {...};
class Cron::Time {...}; # TODO Remove these lines. Im too tired to get my code back into working condition to check if these are needed, but they shouldn't be.
class Cron::TimeA {...}; # TODO delete this line
grammar Cron::Gram {
	token Min { <TimeA> }
	token Hr { <TimeA> }
	token Dow { <TimeA> }
	token Day { <TimeA> }
	token Month { <TimeA> }
	token Yr { <TimeA> }
	token Unparse { # FIXME This should only be used durring testing, Never published.
		(\N+) {say "FAILED TO PARSE--<<$0>>"}
	}
	token CronVar {
		( <[ \! \% ]> <Word>)
	}
	token CronArg { 
		(  \&  <Word>?) 
	}
	token Cmd {
		<Word> [\h+<Word>]+
	}
	token Word {
		[  <Literal>
		|| <Quote>
		|| <-[#]> & \S]+
	}
	token Literal {
		\\ \N
	}
	token Quote {
		  \' <-[\']>* \'
		| \" <-[\"]>* \"
	}
	token Comment {
		'#' (\N*)
	}
	token User { ... }
	
	token TimeA {
		[<Tnum> ',']* <Tnum>
	}
	token Tnum {
		'*' | [\d+ '-' \d+] | \d+ 
	}
	token CronJob {
		 <CronArg> \s+ <Min> \s+ <Hr> \s+  <Dow> \s+ <Day> \s+ <Month> \s+  <Cmd> 
	}
	rule TOP {
		#TODO [ <Comment> || [ <CronJob>||<CronVar> ] \h* \n? || <Unparse> ]+ #Needs to be tested first, Im tired so test with-geld. Note .perl isn't working as expectd.
		[[  <Comment>
		|| <CronJob> <Comment>?
		|| <CronVar>
		|| <Unparse>
		] \h* \n? ]+
	}
}
class Cron::Actions {
	method Min($/) { make $<TimeA>.made; }
	method Hr($/) { make $<TimeA>.made; }
	method Dow($/) { make $<TimeA>.made; }
	method Day($/) { make $<TimeA>.made; }
	method Month($/) { make $<TimeA>.made; }
	method Yr($/) { make $<TimeA>.made; }
	method TimeA($/) {
		my @tnums = (for ($<Tnum>.list) { .made }) ;
		my $cta = Cron::TimeA.create( @tnums ) ;
		make $cta;
	}
	method Tnum($/) {
		make Cron::Time.create( $/ );
	}
	method CronArg($/) {
		make $/;
	}
	method Cmd($/) {
		make $/.Str;
	}
	method Comment($/) {
		make $/;
		#say $/;
	}
	method CronJob($/) {
		make	[$<Min>.made.Str,
			$<Hr>.made.Str,
			$<Dow>.made.Str,
			$<Day>.made.Str,
			$<Month>.made.Str,
			$<Cmd>.made,
			#$<Yr>.made
		];
	}
	method TOP($/) {
		my @CronJobs = (for ($<CronJob>.list) { .made });
		make @CronJobs;
	}
}
class Cron {
	has $.CronFile is rw = die "CronFile Is Required";
	has Match $!CronO = Cron::Gram.parse($!CronFile, :actions(Cron::Actions)); # The Parsed CronFile (Tree?)
	method Call() {
		#my $C = Cron::Gram.parse($Time);
		#$Time.say; 
		$!CronO = Cron::Gram.parse($.CronFile, :actions(Cron::Actions));	# $!CronO Defined here
		#say $C;
		#say $C<CronJob>[0].made;
	}
	method NextCmd() { # FIXME ... Impliment this
		say '$!CronO';
		say $!CronO;								# This works
		say '$!CronO.perl';
		say $!CronO.perl;							# This doesn't
	#	for $!CronO<CronJob> {
	#		say $_;
	#	}
	}
}
class Cron::TimeA { # FIXME Rename this class. It is not a TimeArray, it is a TimeNumber-Array, an Array of OneUnit of Time. 
	has @.Times;
	method gist () {
		return &.list;
	}
	method list () {
		return &.Tnum_List;
	}
	method Str () {
		return &.Tnum_Str.join(',');
	}
	method Tnum_Str () {
		my @retval;
		for @.Times -> $Tnums {
			@retval.push($Tnums.Str);
		}
		return @retval;
	}
	method Tnum_List () {
		my %retval;
		for @.Times -> $Tnums {
			for $Tnums.list -> $Tnum {
				#@retval.push($Tnum) unless (@retval ~~ $Tnum);
				%retval{$Tnum}=1;
			}
		}
		return %retval.keys;
	}
	method create(@TnumsA) {
		my @Times;
		for @TnumsA -> $Tnums {
			die 'Error' unless ($Tnums ~~ Cron::Time);
			@Times.push( $Tnums );
		}
		return $.new(:@Times);
	}
}
class Cron::Time does DynamicRange { # FIXME Rename this class. It is not a Time class, but a Single Number of a single TimeUnit<dow hr min etc>,
	has Int $.from is rw =  die q{'from' is a required var};
	has Int $.to is rw = $!from;
	has Str $.type is rw;
	method gist () { # NOTE gist to Str is probably better.
		return &.list;
		#return callsame();
	}
	method list () {
		return $.from unless ($.from != $.to);
		return self!SmartRange($.from, $.to);
	}
	method Str () {
		return $.from unless ($.from != $.to);
		return ($.from,'-',$.to).join;
	}
	multi method create (Str $Range ) { self!CreateRange($Range); }
	multi method create (Match $Range ) { self!CreateRange($Range); }
	multi method create (Int $from, Int $to=$from) {
		return &.new(:$from, :$to);
	}
	method !CreateRange ( $Range ) {
		given $Range {
			when (Int || /^\d+$/) {
				return &.new(:from($_.Int));
			}
			when ('*') {

			}
			when (Str || Match) {
				if (/^ (\d+) '-'  (\d+) $/) {
					return &.new(:from($0.Int), :to($1.Int));
				}
			}
			default {
				die q{Unknown Call};
			}
		}
	}
}

#my $CronFile = qqx{fcrontab -l};
my $Cron = Cron.new(:CronFile($CronFile) );
$Cron.Call;
$Cron.NextCmd;

# __END__
my %Tcheck= (
	Min =>	0..59,
	Hr =>	(0..23),
	Day =>	(0..31),
	Dow =>	(0..6),
	Mth =>	(1..12),
	Yr =>	(*..*),
);
my %Nres=(
	Dow=> {
		0 => ('Sun','Sunday'),
		1 => ('Mon','Monday'),
		2 => ('Tue','Tuesday'),
		3 => ('Wed','Wendsday'),
		4 => ('Thu','Thursday'),
		5 => ('Fri','Friday'),
		6 => ('Sat','Saturday'),
	},
	Mth => {
		1 =>  ('Jan', 'January'),
		2 =>  ('Feb', 'Febuary'),
		3 =>  ('Mar', 'March'),
		4 =>  ('Apr', 'April'),
		5 =>  ('May', 'May'),
		6 =>  ('Jun', 'June'),
		7 =>  ('Jul', 'July'),
		8 =>  ('Aug', 'Augest'),
		9 =>  ('Sep', 'September'),
		10 => ('Oct', 'October'),
		11 => ('Nov', 'November'),
		12 => ('Dec', 'December'),
	}
);
