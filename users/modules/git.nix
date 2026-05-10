{ ... }:
{
	programs.git = {
		enable = true;
		settings = {
			user = {
				email = "jacobmilesnickerson@gmail.com";
				name = "Jacob Nickerson";
			};
			init = {
				defaultBranch = "main";
			};
			core = {
				editor = "nvim";
			};
		};
	};
}