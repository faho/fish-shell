function __fish_seen_bsdoption_from
	echo "bsdoption" >> ~/fish.log
	set words (commandline -op)
	set -e words[1] # The first word can never be an option because it's the command
	switch $argv[1]
		case "--all"
			set -e argv[1]
		case "*" # If all is not passed, check only the second word - this is the only way for programs that also accept files
			set words $words[1]
	end
	set -l options $argv
	echo "bsdoption: options: $options, words: $words" >> ~/fish.log
	for w in $words
		for option in $options
			switch $w
				case "*$option*"
					echo "bsdoption: Seen $option" >> ~/fish.log
					return 0
			end
		end
	end
	echo "bsdoption: Not seen" >> ~/fish.log
	return 1
end
