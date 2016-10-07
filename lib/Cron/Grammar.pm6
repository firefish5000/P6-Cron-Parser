#!/usr/bin/perl6
unit module Cron::Grammer;
use v6;
use DateTime::Math;
use BC::Debug::Color;
#$BC::Debug::Color::DebugLevel=1;

# NOTE This was made specificly for fcron. Standard cron syntax is recognized. Features specific to other cron implimentations may not be supported.
grammar Cron::Grammar { # FIXME Most \h, \n, and \s 's should be replaced with a escap compatible token.
	#= Unparse: Short for unparsable. Matches everything after the last successfully parsed line when malformed cronjob is encountered.
	token Unparse {
		(\N+) .* {Err "FAILED TO PARSE--<<$0>>"}
	}
	 #= Timeword: A single astrisk, number, range, or Pattern. Every TimeUnit is made of one or more TimeWords
	token TimeWord {
		'*' [\/ \d{1,2}]? | [\d+ '-' \d+] | \d+
	}
	#= Timeunit: A list of comma seperated timewords reperesenting either Minutes, Hours, Days of Month, Months, or Days of the Week
	#= Minute: Token containing a list of TimeWords pertraining to the minute field of a cronjob
	token Min { [<TimeWord> ',']* <TimeWord> }
	#= Hr: Token containing a list of TimeWords pertraining to the hour field of a cronjob
	token Hr { [<TimeWord> ',']* <TimeWord> }
	#= Dow: Token containing a list of TimeWords pertraining to the Day of Week field of a cronjob
	token Dow { [<TimeWord> ',']* <TimeWord> }
	#= Dom: Token containing a list of TimeWords pertraining to the Day of Month field of a cronjob
	token Dom { [<TimeWord> ',']* <TimeWord> }
	#= Month: Token containing a list of TimeWords pertraining to the Month field of a cronjob
	token Month { [<TimeWord> ',']* <TimeWord> }
	#= Yr: Optional Token containing a list of TimeWords pertraining to the Year field of a cronjob in nncron
	token Yr { [<TimeWord> ',']* <TimeWord> }
	#= Word: A single string of characters. A word begains with a litteral or any non-whitspace character except for a hash, and ends as at the first non-literal and un-quoted whitespace character.
	token Word { # Should IsA#Comment be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| \S]+
		#|| <-[#]> & \S]+
	}
	#= Literal: An escaped character that should be treated as part of a string, but may have special meaning in unescaped form.
	token Literal { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\ \N
	}
	#= Quote: A pair of matching quotes and content inside of them.
	token Quote { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \' <-[\']>* \'
		| \"   [<Literal> || <-[\"]>]*   \" 
	}
	#= CronDefaultVar: A Cron variable affecting all proceeding cronjobs. These variables start with a special character and often change default options for cronjobs proceeding them. Every CronDefaultVariable must be on its own line
	token CronDefaultVar { # FIXME % is not a var, but a Non-clasic CronJob format. CronVar should probably handle things like mail(no) after \&. 
		( <[ \! \% ]> <Word>)
	}
	#= CronJobVar: A Cron variable affecting a single cronjob. These variables start with the special character '&' and change options for the current cronjob only. This is placed directly in front of the cronjob it is to affect.
	token CronJobVar {
		(  \&  <Word>?)
	}
	#= CronTime: The time at which a cronjob is to run. A space seperated list of Minute, hour, day_of_month, month, and day_of_week TimeUnits.
	token CronTime {
		 <Min> \h+ <Hr> \h+  <Dom> \h+ <Month> \h+ <Dow> 
	}
	#= CronJob: A single cronjob containing all CronJobVariable, the CronTime, And the Cmd to be executed.
	token CronJob {
		 [ [<CronJobVar> ',']* <CronJobVar> \h+]? <CronTime> \h+  <Cmd> 
	}
	# TODO token User { ... }
	#= Cmd: The command to be executed for a given cronjob.
	token Cmd {
		<Word> [\h+<Word>]+
	}
	#= Comment: A comment which is started with an unquoted, unescaped '#' that is not part of a word. Comments begin with the hash and end at the end of the line.
	token Comment { 
		'#' (\N*)
	}
		
	
	rule TOP {
		[ <Comment> 
		|| [ <CronJob>||<CronDefaultVar> ] \h* \n? 
		|| <Unparse> ]+
	}
}
