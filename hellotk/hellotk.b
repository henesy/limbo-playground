implement HelloTk;

include "sys.m";
	sys: Sys;

include "draw.m";
	draw: Draw;

include "tk.m";
	tk: Tk;

include	"tkclient.m";
	tkclient: Tkclient;

HelloTk: module {
	init:	fn(ctxt: ref Draw->Context, argv: list of string);
};


init(ctxt: ref Draw->Context, nil: list of string) {
	sys  = load Sys  Sys->PATH;
	if (ctxt == nil)
		raise "no window context";

	draw = load Draw Draw->PATH;
	tk   = load Tk   Tk->PATH;
	tkclient= load Tkclient Tkclient->PATH;

	# Make a new process group for us and child processes
	sys->pctl(Sys->NEWPGRP, nil);

	# Start Tk
	tkclient->init();

	# Create window
	(t, wmctl) := tkclient->toplevel(ctxt, "", "Hello Tk", 0);

	# Set the text to be displayed
	text := "Hello, Tk ☺ \n";
	tk->cmd(t, "label .d -label {" + text + "}");

	# Build the window
	height := 1;		# 2 lines
	tk->cmd(t, "pack .d; pack propagate . " + string height);
	tkclient->onscreen(t, nil);

	# Start receiving keyboard and mouse input
	tkclient->startinput(t, "kbd"::"ptr"::nil);

	# Set a ticker to trigger periodic re-draw'ing
	tick := chan of int;
	spawn timer(tick);

	n := 0;
	for(;;) 
		alt {
		key := <-t.ctxt.kbd =>
			# Ticks every keyboard button press
			sys->print("key = %d\n", key);
			tk->keyboard(t, key);

		ptr := <-t.ctxt.ptr =>
			# Ticks every time the pointer moves/clicks
			tk->pointer(t, *ptr);

		s := <-t.ctxt.ctl
		or	s = <-t.wreq
		or	s = <-wmctl =>
			# Ticks every time the window itself has an event
			sys->print("tk string = \"%s\"\n", s);
			tkclient->wmctl(t, s);

		<-tick =>
			# Update the text on screen
			str := text + string ++n;
			tk->cmd(t, ".d configure -label {" + str + "};update");
		}
}

timer(c: chan of int) {
	for(;;) {
		c <-= 1;
		sys->sleep(1000);
	}
}

kill(pid: int) {
	fd := sys->open("#p/"+string pid+"/ctl", sys->OWRITE);
	if(fd != nil)
		sys->fprint(fd, "kill");
}
