# ip(8) completion for fish

# The difficulty here is that ip allows abbreviating options, so we need to complete "ip a" like "ip address", but not "ip m" like "ip mroute"
# Also the manpage and even the grammar it accepts is utter shite (options can only be before commands, it needs the string "dev" before a device)

set -l ip_commands link addr addrlabel route rule neigh ntable tunnel tuntap maddr mroute mrule monitor xfrm netns l2tp tcp_metrics
set -l ip_addr a ad add addr addre addres address
set -l ip_link l li lin link
set -l ip_all_commands $ip_commands $ip_addr $ip_link

function __fish_ip_address_from_device
	ip -o addr | grep $argv | while read a b c d e;
		echo $d;
	end
end

function __fish_ip_device_from_address
	ip -o addr | grep $argv | while read a b c d e;
		echo $b;
	end
end

function __fish_ip_has_device
	breakpoint
	set -l nextisdevice 1
	for word in (commandline -opc)
		if [ $nextisdevice -eq 0 ];
			echo "Found device: $word" >> ~/fish.log
			echo $word
			return 0
		end
		if [ $word = "dev" ];
			echo "Word is dev: $word" >> ~/fish.log
			set -l nextisdevice 0
		end
	end
end

function __fish_ip_device_from_address_commandline
	set -l address ""
	set -l nextisaddress 1
	set -l cmd (commandline -opc)
	set -e cmd[1]
	set -e cmd[1]
	for word in $cmd
		echo "Word: $word" >> ~/fish.log
		if [ $nextisaddress -eq 0 ]
			echo "Got address $word" >> ~/fish.log
			set address $word
			break
		else
			switch word
				case '-*'
					continue
				case '*'
					echo "Next is address" >> ~/fish.log
					set nextisaddress 0
					continue
			end
		end
	end
	if test -n $address
		echo "Address: $address" >> ~/fish.log
		__fish_ip_device_from_address $address
	end
end
			
		
complete -f -c ip
complete -f -c ip -n "not __fish_seen_subcommand_from $ip_all_commands" -a "$ip_commands"
# Yes, ip only takes options before "objects"
complete -c ip -s b -l batch -d "Read commands from file or stdin" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -l force -d "Don't terminate on errors in batch mode" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -s V -l Version -d "Print the version" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s s -l stats -d "Output more information" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s d -l details -d "Output more detailed information" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s l -l loops -d "Specify maximum number of loops for 'ip addr flush'" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s f -l family -d "The protocol family to use" -a "inet inet6 bridge ipx dnet link any" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s 4 -d "Short for --family inet"	-n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s 6 -d "Short for --family inet6" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s B -d "Short for --family bridge" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s D -d "Short for --family decnet" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s I -d "Short for --family ipx" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s O -d "Short for --family link" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s o -l oneline -d "Output on one line" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s r -l resolve -d "Resolve names and print them instead of addresses" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s n -l net -l netns -d "Use specified network namespace" -n "not __fish_seen_subcommand_from $ip_commands"
complete -c ip -f -s a -l all -d "Execute command for all objects" -n "not __fish_seen_subcommand_from $ip_commands"

# What ip refers to as "commands", the second-sublevel thing, i.e. what comes after ip $something
complete -c ip -f -n "__fish_seen_subcommand_from $ip_addr; and not __fish_seen_subcommand_from add del" -a "add del"
complete -c ip -f -n "__fish_seen_subcommand_from $ip_addr; and __fish_seen_subcommand_from add del; and not __fish_seen_subcommand_from dev" -a "dev"
# complete -c ip -f -n "__fish_seen_subcommand_from $ip_addr; and __fish_seen_subcommand_from add del; and __fish_seen_subcommand_from dev" -a "(__fish_print_interfaces)"
complete -c ip -f -n "__fish_seen_subcommand_from $ip_addr; and __fish_seen_subcommand_from add del; and __fish_seen_subcommand_from dev" -a "(__fish_ip_device_from_address_commandline)"
