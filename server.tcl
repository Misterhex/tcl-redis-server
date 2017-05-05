set port 6500

proc accept {chan addr port} {

	puts "accepted new tcp connection : $addr:$port"

	fconfigure $chan -buffering line
	fileevent $chan readable [list processCommand $chan]
}

proc processCommand {chan} {
	
	if {[catch { gets $chan line }]} {
		puts "error on sock $chan, closing..."
		close $chan
	}

	puts "$chan received '$line'"

	if {[isStringSet $line]} {

		puts "received redis set command"

		set tokens [split $line " "]

		set key [lindex $tokens 1]

		set globalKey ::$key

		set tokens [lreplace $tokens 1 1 $globalKey]

		set globalset [join $tokens " "]

		eval $globalset

	} elseif {[isStringGet $line]} { 

		puts "received redis get command"
	
		set tokens [split $line " "]

		set key [lindex $tokens 1]

		if {[info exists ::$key]} {

			puts $chan [set ::$key]

		} else {

			puts $chan "(nil)"

		}

	} else {

		set errorMsg "unknown command '$line'."

		puts $chan $errorMsg

		close $chan
	}

}

proc isStringSet {command} {
	string match {set [a-zA-Z0-9]* [a-zA-Z0-9]*} $command
}

proc isStringGet {command} {
	string match {get [a-zA-Z0-9]*} $command
}


set socketServer [socket -server accept $port]

vwait forever
