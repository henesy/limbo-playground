implement Docmd;

include "sys.m";
	sys: Sys;
	pctl, fprint, fildes, bind,
	NEWFD, FORKFD, NEWNS, FORKNS, 
	NODEVS, NEWENV, FORKENV, NEWPGRP: import sys;

include "draw.m";

include "arg.m";

include "sh.m";

include "newns.m";


Docmd: module {
	init: fn(ctx: ref Draw->Context, argv: list of string);
};


# Debug output
chatty: int = 0;

# Pctl flags
# TODO - maybe use NEWNS rather than FORKNS using careful binds?
flags: int = NEWFD | FORKNS | NODEVS | NEWENV | NEWPGRP;

# Run a command with specific arguments
init(ctx: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;

	arg := load Arg Arg->PATH;
	if(arg == nil)
		raise "could not load " + Arg->PATH;

	ns := load Newns Newns->PATH;
	if(ns == nil)
		raise "could not load " + Newns->PATH;

	arg->init(argv);
	arg->setusage("docmd [-D] [-n nsfile] cmd args…");

	# ns file to build from
	nsf := "";
	
	while((o := arg->opt()) != 0)
		case o {
		'D' => chatty++;
		'n' => nsf = arg->earg();
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

		fprint(fildes(2), "Pctl flags = 0x%x\n", flags);

		# This is a silly hack
		fprint(fildes(2), "Parent pid = %d\n", pctl(0, nil));
	}

	# Read a namespace(6) file to create our ns
	if(nsf != nil) {
		user := readfile("/dev/user");
		err := ns->newns(user, nsf);
		if(err != nil)
			raise "err (parent): newns(2) failed - " + err;
	}

	pidc := chan of int;
	
	spawn runcmd(ctx, cmd, argv, pidc);

	pid := <- pidc;

	if(chatty)
		fprint(fildes(2), "Child pid = %d\n", pid);
	
	exit;
}

# For use with spawn
runcmd(ctx: ref Draw->Context, cmd: string, argv: list of string, pidc: chan of int) {
	 pidc <-= pctl(flags, 0 :: 1 :: 2 :: nil);
	
	# You'll get a module not loaded at this point if it can't find the file
	c := load Command cmd;
	if(c == nil) {
		fprint(fildes(2), "err (child): file %s could not be loaded - %r\n", cmd);
		exit;
	}

	c->init(ctx, argv);
}

# Reads a file into a string
readfile(f: string): string {
	fd := sys->open(f, sys->OREAD);
	if(fd == nil)
		return nil;

	buf := array[8192] of byte;
	n := sys->read(fd, buf, len buf);
	if(n < 0)
		return nil;

	return string buf[0:n];	
}
