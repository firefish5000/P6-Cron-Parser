#!/usr/bin/perl6
#module Cron::Grammar;
use v6;
use DateTime::Math;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=1;

# NOTE This was made specificly for fcron. other implimentations. Next will be Cron
grammar Cron::Grammar { # FIXME Most \h, \n, and \s 's should be replaced with a escap compatible token.
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
	
	token Word { # Should IsA#Comment be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| \S]+
		#|| <-[#]> & \S]+
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
	}
}
