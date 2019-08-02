implement Docmd;

include "sys.m";
	sys: Sys;
	pctl, fprint, fildes,
	NEWFD, FORKFD, NEWNS, FORKNS, 
	NODEVS, NEWENV, FORKENV, NEWPGRP: import sys;

include "draw.m";

include "arg.m";

include "sh.m";


Docmd: module {
	init: fn(ctx: ref Draw->Context, argv: list of string);
};


# Debug output
chatty: int = 0;


# Run a command with specific arguments
init(ctx: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	arg := load Arg Arg->PATH;
	if(arg == nil)
		raise "could not load arg.m";

	arg->init(argv);
	arg->setusage("docmd [-D] cmd args…");
	
	while((o := arg->opt()) != 0)
		case o {
		'D' => chatty++;
		* => arg->usage();
	}
			
	argv = arg->argv();
	argc := len argv;
	
	if(argc <= 0)
		arg->usage();
	
	cmd := hd argv;
	
	if(chatty) {
		fprint(fildes(2), "Argc = %d\nCmd = %s\n", argc, cmd);
		fprint(fildes(2), "Args:\n");
		for(a := argv; a != nil; a = tl a)
			fprint(fildes(2), "\t%s\n", hd a);
	}
	
	pid := pctl(NEWFD, 0 :: 1 :: 2 :: nil);

	if(chatty)
		fprint(fildes(2), "Pid = %d\n", pid);
	
	c := load Command cmd;
	c->init(ctx, argv);
	
	exit;
}
