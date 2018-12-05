// load flow analysis macro into Fiji's Plugins->Macros submenu
macrosDirectory=getDirectory("plugins")+"Macros"+File.separator;
run("Install...","install="+macrosDirectory+"STAFF.ijm");