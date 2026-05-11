{ config, ... }:
{
	services.openssh = {
		enable = true;
		ports = [ 42067 ];
		settings = {
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = "no";
			AllowUsers = null;
			UseDns = true;
			X11Forwarding = false;
		};
	};

	services.endlessh = {
		enable = true;
		port = 22;
		openFirewall = true;
	};
	
	services.fail2ban = {
		enable = true;
	};

	users.users."jacobnickerson".openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGsgM2ftNlPvn8Vltsj3+WuHhVZHMIW+5Iqk2ajfXJi jacobnickerson@PortaJake"
	];
}
