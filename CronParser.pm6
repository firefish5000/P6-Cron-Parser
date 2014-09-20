#!/usr/bin/perl6
use v6;
use DateTime::Math;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=1;
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
	method !SmartRange ($from, $to, :@unit) { 
		return @unit[0]..@unit[*-1] if ($from ~~ '*');
		Err qq{from {$from} is not in unit's range} unless @unit[0] <= $from <= @unit[*-1];
		Err qq{to {$to} is not in unit's range} unless @unit[0] <= $to <= @unit[*-1];
		if ($from <= $to) {
			return $from..$to;
		} else {
			return ($from..@unit[*-1],@unit[0]..$to);
		}
	}
}

class Cron {...};
class Cron::Time {...}; # TODO Remove these lines. Im too tired to get my code back into working condition to check if these are needed, but they shouldn't be.
class Cron::Time::Unit {...}; # TODO delete this line
class Cron::Time::Unit::Range {...};
# NOTE This was made specificly for fcron. other implimentations. Next will be Cron
grammar Cron::Gram { # FIXME Most \h, \n, and \s 's should be replaced with a escap compatible token.
	token Unparse { # Short for Unparsable. NOTE This should only be used durring testing, Never published ## Probably should eat the rest of the Input..
		(\N+) .* {Err "FAILED TO PARSE--<<$0>>"}
	}

#	token TWord_Arr { # NOTE I am not satisfied with this name, So it will likely change
#		[<TWord> ',']* <TWord>
#	}
	token TWord { # NOTE TWord for TimeWord. Probably isn't the best name for this either.
		'*' | [\d+ '-' \d+] | \d+ 
	}
	token Min { [<TWord> ',']* <TWord> }
	token Hr { [<TWord> ',']* <TWord> }
	token Dow { [<TWord> ',']* <TWord> }
	token Dom { [<TWord> ',']* <TWord> }
	token Month { [<TWord> ',']* <TWord> }
	token Yr { [<TWord> ',']* <TWord> }
	
	token Word { # Should IsA#Comment? be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| <-[#]> & \S]+
	}
	token Literal { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\ \N
	}
	token Quote { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \' <-[\']>* \'
		| \"   [<Literal> || <-[\"]>]*   \" 
	}

	token CronVar { # FIXME % is not a var, but a Non-clasic CronJob format. CronVar should probably handle things like mail(no) after \&. 
		( <[ \! \% ]> <Word>)
	}
	token CronArg { # I dont think \& should be  part of the CronArg. (What is CronArg Anyway) What succeeds \& should be a CronVar or the like. 
		(  \&  <Word>?) 
	}
	token CronTime {
		 <Min> \h+ <Hr> \h+  <Dom> \h+ <Month> \h+ <Dow> 
	}
	token CronJob {
		 <CronArg> \h+ <CronTime> \h+  <Cmd> 
	}
	
	# TODO token User { ... }
	token Cmd {
		<Word> [\h+<Word>]+
	}
	token Comment { 
		'#' (\N*)
	}
		
	
	rule TOP {
		[ <Comment> 
		|| [ <CronJob>||<CronVar> ] \h* \n? 
		|| <Unparse> ]+
	#	[[  <Comment>
	##	|| <CronJob> <Comment>?
	#	|| <CronVar>
	#	|| <Unparse>
	#	] \h* \n? ]+
	}
}
class Cron::Actions {
	method Min($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Min> ) ;
		make $cta;
	}
	method Hr($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Hr> ) ;
		make $cta;
	}
	method Dow($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Dow> ) ;
		make $cta;
	}
	method Dom($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Dom> ) ;
		make $cta;
	}
	method Month($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Mon> ) ;
		make $cta;
	}
	method Yr($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Yr> ) ;
		make $cta;
	}
	method TWord_Arr($/) {
		my @twords = (for ($<TWord>.list) { .made }) ;
		my $cta = Cron::Time::Unit.create( @twords, :unit<Unk> ) ;
		make $cta;
	}
	method TWord($/) {
#		make Cron::Time::Unit::Range.create( $/ );
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
	method CronTime($/) {
		make Cron::Time.create( [$<Min>.made,
			$<Hr>.made,
			$<Dom>.made,
			$<Month>.made,
			$<Dow>.made
			#$<Yr>.made
		]);
	}
	method CronJob($/) {
		make	[$<CronTime>.made.Str,
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
	has $!CronO = Cron::Gram.parse($!CronFile, :actions(Cron::Actions)); # The Parsed CronFile (Tree?)
	method Call() {
		#my $C = Cron::Gram.parse($Time);
		#$Time.say; 
		$!CronO = Cron::Gram.parse($.CronFile, :actions(Cron::Actions));	# $!CronO Defined here
	}
	method NextCmd() { # FIXME ... Impliment this
		for $!CronO<CronJob>.list -> $Ctime{
			Info '-----';
			Info $Ctime<CronTime>.Str;
			Info $Ctime<CronTime>.made.Str;
			Info $Ctime<CronTime>.made.list[$_;*].join(' ') for 0..4;
		}
	}
	method Test() {
		$!CronO<CronJob>.list[0]<CronTime>.made.NextRun;
	}
}
class Cron::Time { # NOTE Rethink what Str and list should return. (is list reeucursive? should Str return 1 Str or a list of Str?)
		# List crrently doesn't let you extract the Hr, Min,etc
	has @.TimeUnits;
	method gist () {
		return &.Str;
	}
	method list () {
		return &.TUnit_List;
	}
	method Str () {
		return &.TUnit_Str.join(' ');
	}
	method TUnit_Str {
		return (for @.TimeUnits {.Str});
	}
	method TUnit_List {
		my @ret;
		my $i=0;
		for @.TimeUnits {
			@ret[$i] = $_.list;
			$i++;
		};
		return @ret;
		return (for @.TimeUnits {.list});
	}
	method NextRun {
		my $dt = DateTime.new(now);

		Info $dt;
	}
	method create (@TimeUnits) {
		for @TimeUnits -> $TimeUnit {
			die 'Cron::Time must be passed a Cron::Time::Unit array Not ',$TimeUnit.^name unless ($TimeUnit ~~ Cron::Time::Unit);
		}
		return &.new(:@TimeUnits);
	}

}
# CONSID makeing Cron::Time::Unit handle CronTimeWord's job. 
# change <TWord> [ \, <TWord> ]* to Capturing (<.TWord>) [ \, (<.TWord>) ]*
my %legal=(
	Unk => [0..0],
	Mon => [1..12],
	Hr  => (0..23),
	Min => (0..59),
	Dom => (0..31),
	Dow => (0..6)
);
class Cron::Time::Unit { # NOTE Im still not sure about the name 
	# An array of One unit of time. ie. 30 0,12 1-5 * 3-5,11-1. Your time units would be 
	# Min 30
	# Hr 0,12
	# Dow 1-5
	# Day(OfMonth) *
	# Month 3-5,11-12
	has @.TRange;
	has $.unit;
	method gist () {
		return &.Str;
	}
	method list () {
		return &.TRange_List;
	}
	method Str () {
		return &.TRange_Str.join(',');
	}
	method TRange_Str () {
		my @retval;
		for @.TRange -> $Tnums {
			@retval.push($Tnums.Str);
		}
		return @retval;
	}
	method TRange_List () {
		my %retval;
		for @.TRange -> $Tnums {
			for $Tnums.list -> $Tnum {
				#@retval.push($Tnum) unless (@retval ~~ $Tnum);
				%retval{$Tnum}=1;
			}
		}
		return %retval.keys;
	}
	method AddTime(*@TRange) {
		for @TRange -> $Tnums { # I couldnt get Cron::Time @TnumsA or @TnumsA of Cron::Time to work. So I am checking individualy.
			die 'Cron::Time::Unit.create needs a Cron::Time::Word Array' unless ($Tnums ~~ Cron::Time::Word);
		}
		@.TRange.push(|@TRange);
	}
	method create(@TStrs, :$unit) {
		my @TRange;
		for @TStrs -> $Tstr { # I couldnt get Cron::Time @TnumsA or @TnumsA of Cron::Time to work. So I am checking individualy.
			die 'Cron::Time::Unit.create needs a Str||Match Array' unless ($Tstr ~~ (Str||Match)); # Str, Match, or the like
			@TRange.push(Cron::Time::Unit::Range.create($Tstr, :$unit));
		}
		return &.new(:@TRange, :$unit);
	}
}
class Cron::Time::Unit::Range does DynamicRange { # NOTE Im still not sure about the name. 
	# A single Unit of Time Specifier thing. Ie. in 1,10-12 Your Time::Words would be 1 and 10-12.
	has Str $.orig is rw;
	has Int $.from is rw =  die q{'from' is a required var};
	has Int $.to is rw = $!from;
	has Str $.unit is rw = die q{'unit' is a required var}; 
	method gist () { 
		return &.Str;
	}
	method list () {
		Err "Attempt to return Timeword list before \$.unit is set." if $.unit ~~ 'Unk'; 
		return $.from unless ($.from != $.to);
		return self!SmartRange($.from, $.to, :unit(%legal{$.unit}));
	}
	method Str () {
		return $.from unless ($.from != $.to);
		return ($.from,'-',$.to).join;
	}
	multi method create (Str $Range, Str :$unit! ) { self!CreateRange($Range, :$unit); }
	multi method create (Match $Range, Str :$unit! ) { self!CreateRange($Range, :$unit); }
	multi method create (Int $from, Int $to=$from, Str :$unit!) {
		return &.new(:$from, :$to, :$unit);
	}
	method !CreateRange ( $Range, :$unit) {
		given $Range {
			when (Int || /^\d+$/) {
				return &.new(:from($_.Int), :$unit);
			}
			when ('*') {
				return &.new(
					:from(%legal{$unit}[0]),
					:to(%legal{$unit}[*-1]),
					:unit($unit)
				);
			}
			when (Str || Match) {
				if (/^ (\d+) '-'  (\d+) $/) {
					return &.new(:from($0.Int), :to($1.Int), :$unit );
				}
				die "!CreateRange failed to parse {$Range}"
			}
		}
		die "!CreateRange Called with Unsupported Type {$Range.WHAT}";
	}
}

#my $CronFile = qqx{fcrontab -l};
my $Cron = Cron.new(:CronFile($CronFile) );
$Cron.Call;
$Cron.NextCmd;
$Cron.Test;
# vim: syntax=off
