
/* Macros:
 *  Open/Create Project
 *  Analyze Skeleton
 *  Create Intervals
 *  Analyze Flow
 *  Produce Spatial Map
 *
 * Functions:
 *  in
 *  indexInArray
 *  append
 *  getLastOpenConfig
 *  loadConfig
 *  confirmExistence
 *  openWholeFile
 *  openAndSelect
 *  saveOldFile
 *  getNewParameterNumber
 *  getNewParameterFileName
 *  getNewParameterLUT
 *  getNewParameterOneOf
 *  getNewParameterNumberInRange
 *  getNewParameterValue
 *  saveConfig
 *  makeKymo
 *
 * Files:
 *  project directory
 *  input directory
 *  video file (.avi .tiff .tif)
 *  segment file (.zip)
 *  skeleton file
 *  intervals file (.csv)
 *  angles file (.csv)
 *  angles fits file (.csv)
 *  plot file (.tif)
 *  velocities file (.csv)
 *  ...
 *  raw_velocity (.csv)    - future, all velocities & small segs
 *  clean_velocity (.csv)  - future, clamp data > max speed
 *
 * Parameters:
 *  project directory      - folder for config and output
 *  input directory
 *  skeleton file          - path to skeleton image file
 *  skeleton line color
 *  video file             - path to blood flow video file
 *  frame rate             - video frame rate (fps)
 *  pixel size             - pixel width (um)
 *  min. segment length    - shortest seg length to analyze (um)
 *  max. speed             - maximum measured velocity (um/s)
 *  segment file           - skeleton ROI file name (.zip)
 *  intervals file         - time intervals file name (.csv)
 *  angles file            - kymograph angles file name (.csv)
 *  angle fits file        - angle fitness file name (.csv)
 *  velocities file        - segment velocities file name (.csv)
 *  color scale            - plot colors LUT
 *  plot file              - plot file name (.tif)
 *  plot background color  - plot background color (black..white)
 *  plot line thickness    - plot line thickness (1..12)
 *  max. plot speed        - maximum velocity to be plotted (um/s)
 *  flicker correction     - correct for lamp flicker
 *  arrow size             - arrows show flow direction
 *  arrow cutoff           - flow direction unreliable for really low
 *                           velocities, so dont draw arrow for them
 */ 
 */

/**************************************************************/
/**************************************************************/
/* parameter strings */

var numberOfParameters = 23;

var parameters =            newArray("project directory",            "skeleton file",              "video file",                   "frame rate",          "pixel size",          "min. segment length",                 "max. speed",          "segment file",               "intervals file",          "angles file",                    "angle fits file",             "velocities file",                  "color scale",         "plot file",          "plot background color", "plot line thickness", "max. plot speed", "arrow size","input directory","flicker correction","skeleton line color","arrow cutoff","project prefix");

var parameterTypes =        newArray("directory",                    "file path",                  "file path",                    "number",              "number",              "number",                              "number",              "file name",                  "file name",                  "file name",                      "file name",                   "file name",                        "LUT name",            "file name",          "one of",                "number in range", "number", "one of","directory","number","number","number","file name");

var parameterDescriptions = newArray("folder for config and output", "path to the skeleton image", "path to the blood flow video", "video frame rate",    "1 pixel's width",     "shortest segment length to analyze",  "maximum measured speed",  "name for skeleton ROI file", "name for intervals file", "name for kymograph angles file", "name for angle fitness file", "name for segment velocities file", "LUT for plot colors", "name for plot file", "plot background color", "plot line thickness", "maximum speed plotted", "plot arrow size","folder for input files","correct for lamp flicker","color of lines in skeleton plot","omit arrow if velocity < cutoff","prefix for output filenames");

var parameterUnits =        newArray("",                             "",                           "",                             "frames per second",   "microns",             "microns",                             "microns per second",  ".zip",                       ".csv",                       ".csv",                           ".csv",                        ".csv",                             "",                    ".tif",               "black,white",           "1,12", "microns per second", "small,medium,large","","","","","");

var parameterProviders =    newArray("Open/Create Project",          "Open/Create Project",        "Open/Create Project",          "Open/Create Project", "Open/Create Project", "Open/Create Project",                 "Open/Create Project", "Analyze Skeleton",           "Create Intervals",        "Analyze Flow",                   "Analyze Flow",                "Analyze Flow",                     "Open/Create Project", "Produce Spatial Map",       "Open/Create Project",   "Open/Create Project", "Open/Create Project", "Open/Create Project","Open/Create Project","Analyze Flow","Produce Spatial Map","Produce Spatial Map","Open/Create Project");

var configDelimiter = "\t"; // Config file is delimited by tabs to allow spaces, commas, etc. in filename parameters.

var logger=0;               // =0 minimal log window, >0 detailed log window

/**************************************************************/
/*****************  globals - default values  *****************/
/**************************************************************/
/* folders and file names */

var projectPath="";           // full path to project folder
var projectPrefix="";         // File.getName(projectPath) + "-"

var inputPath="";             // only used in editInputFiles

var segmentFile="skel_roi.zip";                // List.get("segment file")
var spatialMapFile="spatial_map.tif";          // List.get("plot file")
var anglesFile="kym_ang.csv";                  // List.get("angles file")
var anglesFitFile="good_fit.csv";              // was "ang_fit.csv" // List.get("angle fits file")
var velocitiesFile="segment_velocities.csv";   // was "vel.csv" // List.get("velocities file")

var movieFile="";                              // List.get("video file")
var skeletonFile="skel.csv";                   // List.get("skeleton file")

var configFile="config.csv";
var configPath="";             // projectPrefix + configFile;

var intervalsFile="intervals.csv";             // List.get("intervals file")
var intervalsPath=projectPath+projectPrefix+intervalsFile;
var respirationDelimiter=","; // Column delimiter in intervals.csv file. Should always be ",".


/**************************************************************/
/* analysis parameters */

var maxMeasuredSpeed=2000.0;
var minSegmentLength=20.0;
var frameRate=0.0;
var pixelSize=0.0;
var flickerCorrection=0;       // ??? not saved yet


/**************************************************************/
/* plot parameters */

var maxPlotSpeed=1000.0;
var lineThickness=4;
var arrowSize="medium";     
var colorScale="physics";
var backgroundColor="black";
var skeletonLineColor;          // ??? not saved or used yet
var arrowCutoff=1;              // ??? not saved yet


/**************************************************************/
/* kymograph regions-of-interest (ROIs) */

var numIntervals;      // was numNonRespirations;
var intervalStarts;    // was nonRespStarts;
var intervalEnds;      // was nonRespEnds;


/**************************************************************/
/**************************************************************/
/* Generally useful functions */

function in(arr, val){
	for (i=0; i<lengthOf(arr); i++){if (arr[i] == val){return true;}}
	return false;
}


/**************************************************************/

function indexInArray(arr, val){
	for (i=0; i<lengthOf(arr); i++){ if (arr[i] == val){return i;}}
	exit("Tried to find '" + val + "' place in an array it wasn't in.");
}


/**************************************************************/
// Returns an copy of array "arr" with "val" added to the end of it.
function append(arr, val){
	tmpArr = newArray(1);
	tmpArr[0] = val;
	return Array.concat(arr, tmpArr);
}


/**************************************************************/
// Get the contents of /tmp/flow-analysis-last-project.conf file,
// which should be the last config file the user opened with 'Open/Create Project'.

function getLastOpenedConfig(){
	lastConfigFile = getDirectory("temp") + "flow-analysis-last-project.conf";
	if (File.exists(lastConfigFile)){
		lastConfigFileLines = split(File.openAsString(lastConfigFile), "\n");
		config_file = lastConfigFileLines[0];
		if (File.exists(config_file)){
			return config_file;
		}
	}
	exit("I don't know what project you're working on.\n" + "Please run Open/Create Project.");
}


/**************************************************************/
// Load config into List from a .csv file.
// Does not warn if configuration is incomplete!

function loadConfig(config_path){
	if (File.exists(config_path)){
		configText = File.openAsString(config_path);
		configLines = split(configText, "\n");
		for (lineNum = 0; lineNum<lengthOf(configLines); lineNum++){
			line = configLines[lineNum];
			lineParts = split(line, configDelimiter);
			if(lengthOf(lineParts) >= 2 && !startsWith(line, "//")){
				parameter = lineParts[0];
				value = lineParts[1];
				List.set(parameter, value);
			}
		}
	} else {exit("Tried to open non-existant config file:\n" + config_path + "\nPlease run Open/Create Project.");}
	if (logger) print("Loaded configuration:\n" + List.getList);
}


/**************************************************************/

function confirmExistence(neededParameters){
	for (parameterNum = 0; parameterNum < lengthOf(neededParameters); parameterNum++){
		parameter = neededParameters[parameterNum];
		if (!in(parameters, parameter)){exit("This macro has an unknown config parameter, '" + parameter + "'!\n" + "This is probably a bug in the macro.");}
		i = indexInArray(parameters, parameter);
		type = parameterTypes[i];
		provider = parameterProviders[i];
		val = List.get(parameter);
		if (val == ""){exit("This macro needs config parameter '" + parameter + "', which is not in the config file.\n" + "Run Open/Create Project to set it.");}
		if (type == "directory"){if (!File.exists(val)){exit("Directory '" + val + "' doesn't exist!\n" + "Run " + provider + " to fix this.");}}
		if (type == "file path"){if (!File.exists(val)){exit("File '" + val + "' doesn't exist!\n" + "Run " + provider + " to fix this.");}}
		if (type == "file name"){
			dir = List.get("project directory");
			path = dir + val;
			if (!File.exists(path)){exit("No file '" + val + "' in '" + dir + "'.\n" + "Run " + provider + " or Open/Create Project to fix this.");}
		}
		if (type == "LUT name"){
			luts = getList("LUTs");
			if (!in(luts, val)){exit("No LUT called '" + parameter + "'.\n" + "Import it, or run Open/Create Project.");}
		}
	}
}


/**************************************************************/

function listInputFileNames()
{
// Input Files and folders
List.set("input directory",inputPath);
List.set("video file",movieFile);
List.set("skeleton file",skeletonFile);
}


function listOutputFileNames()
{
// Output Files
List.set("project directory",projectPath);
List.set("project prefix",projectPrefix);
List.set("segment file",segmentFile);
List.set("plot file",spatialMapFile);
List.set("angles file",anglesFile);
List.set("angle fits file",anglesFitFile);
List.set("velocities file",velocitiesFile);
List.set("intervals file",intervalsFile);
}


function listAnalyzeFlowParameters()
{
// Analyze flow parameters
List.set("max. speed",maxMeasuredSpeed);
List.set("min. segment length",minSegmentLength);
List.set("pixel size",pixelSize);
List.set("frame rate",frameRate);
List.set("flicker correction",flickerCorrection);
}


function listPlotParameters()
{
// Spatial map parameters
List.set("max. plot speed",maxPlotSpeed);
List.set("plot line thickness",lineThickness);
List.set("arrow size",arrowSize);
List.set("color scale",colorScale);
List.set("plot background color",backgroundColor);
List.set("skeleton line color",skeletonLineColor);
List.set("arrow cutoff",arrowCutoff);
}


function listGlobals()    // listParameters
{
listInputFileNames();
listOutputFileNames();
listAnalyzeFlowParameters();
listPlotParameters();
}


function copyListToGlobals()
{
// Input files and folders
inputPath=List.get("input directory");
movieFile=List.get("video file");
skeletonFile=List.get("skeleton file");

// Output files
projectPath=List.get("project directory");
projectPrefix=List.get("project prefix");
segmentFile=List.get("segment file");
spatialMapFile=List.get("plot file");
anglesFile=List.get("angles file");
anglesFitFile=List.get("angle fits file");
velocitiesFile=List.get("velocities file");
intervalsFile=List.get("intervals file");

// need to parse strings, turn them into numbers, checkbox, word choices

// Analyze flow parameters
maxMeasuredSpeed=List.get("max. speed");
minSegmentLength=List.get("min. segment length");
pixelSize=List.get("pixel size");
frameRate=List.get("frame rate");
flickerCorrection=List.get("flicker correction");

// Spatial map parameters
maxPlotSpeed=List.get("max. plot speed");
lineThickness=List.get("plot line thickness");
arrowSize=List.get("arrow size");
colorScale=List.get("color scale");
backgroundColor=List.get("plot background color");
skeletonLineColor=List.get("skeleton line color");
//arrowCutoff=List.get("arrow cutoff");
}


/**************************************************************/
// inputPath isnt used (yet) outside of editInputFileNames.
// selecting it via getDirectory causes getDirectory calls for
// movieFile and skeletonFile to display contents of inputDir.
//
// movieFile and skeletonFile contain full paths, which may
// or may not be the same as inputDir (user could have moved
// out of inputPath while using file dialog box).

function editInputFileNames()
	{
	showMessage("Input Directory", "Select the input directory.");
	inputPath = getDirectory("Select Input Directory");
	if (logger) print("inputPath: "+inputPath);

	showMessage("Movie File","Select the movie file.");
	movieFile = File.openDialog("Select Movie File");
	if (logger) print("movieFile: "+movieFile);

	showMessage("Skeleton File","Select the skeleton file.");
	skeletonFile = File.openDialog("Select Skeleton File");
	if (logger) print("skeletonFile: "+skeletonFile);

	listInputFileNames();
	saveConfig();
	}


/**************************************************************/
// when Create/Open Project macro calls editOutputFileNames(),
// give user the option to see/change output filename prefix
// (projectPrefix) by setting new_config arg = true.
// but only do this when creating a new project (config file).
//
// we can't let user change filename prefix after reloading
// an existing config file, because the macros will then not
// be able to find old data files (which were created using 
// old filename prefix), while new data files will be
// created using new/different prefix.
//
// when Analyze Flow macro calls editOutputFileNames,
// allow user to change project path/folder (projectPath),
// and also change base filenames, but not filename prefix.
// by setting new_config arg = false.

function editOutputFileNames(new_config)
{
	Dialog.create("Output File Names");
        Dialog.addString("Project Directory",projectPath,32);
        if (new_config) Dialog.addString("Filename Prefix",projectPrefix,32);
	Dialog.addString("Segment File",segmentFile,32);
	Dialog.addString("Spatial Map File",spatialMapFile,32);
	Dialog.addString("Angles File",anglesFile,32);
	Dialog.addString("Goodness of Fit File",anglesFitFile,32);
	Dialog.addString("Velocities File",velocitiesFile,32);
	Dialog.addString("Intervals File",intervalsFile,32);

	Dialog.show();
        // if user clicks OK button in Dialog box,
        // the following code is executed.
        // if user clicks Cancel button in Dialog box,
        // the following code is NOT executed.
        if (logger) print("editOutputFileNames\n");

	projectPath=Dialog.getString();
        if (new_config) projectPrefix=Dialog.getString();
	segmentFile=Dialog.getString();
	spatialMapFile=Dialog.getString();
        anglesFile=Dialog.getString();
	anglesFitFile=Dialog.getString();
	velocitiesFile=Dialog.getString();
	intervalsFile=Dialog.getString();

	listOutputFileNames();
	saveConfig();
}


/**************************************************************/

function editAnalyzeFlowParameters()
{
	Dialog.create("Analyze Flow Parameters");
	Dialog.addNumber("Max Measured Speed (um/s)",maxMeasuredSpeed,3,9,"");
	Dialog.addNumber("Min Segment Length (um)",minSegmentLength,3,9,"");
	Dialog.addNumber("Pixel Size (um)",pixelSize,3,9,"");
	Dialog.addNumber("Frame Rate (fps)",frameRate,3,9,"");
        Dialog.addCheckbox("Flicker correction",flickerCorrection);

	Dialog.show();
	// if user clicks OK button in Dialog box,
        // the following code is executed.
        // if user clicks Cancel button in Dialog box,
        // the following code is NOT executed.
	if (logger) print("editAnalyzeFlowParameters");

	maxMeasuredSpeed=Dialog.getNumber();
	minSegmentLength=Dialog.getNumber();
	pixelSize=Dialog.getNumber();
	frameRate=Dialog.getNumber();
	flickerCorrection=Dialog.getCheckbox();

        // if user enters a negative or zero value for a parameter,
        // give them one more change to fix it (and dont check it again).

        if (maxMeasuredSpeed<=0.0)
          {
          Dialog.create("Out-of-Range Parameter");
	  Dialog.addMessage("Max Measured Speed must be greater than 0");
          Dialog.addNumber("Max Measured Speed (um/s)",maxMeasuredSpeed,3,9,"");
	  Dialog.show();
	  maxMeasuredSpeed=Dialog.getNumber();
          }

        if (minSegmentLength<=0.0)
          {
          Dialog.create("Out-of-Range Parameter");
	  Dialog.addMessage("Min Segment Length must be greater than 0");
          Dialog.addNumber("Min Segment Length (um)",minSegmentLength,3,9,"");
	  Dialog.show();
	  minSegmentLength=Dialog.getNumber();
          }

        if (pixelSize<=0.0)
          {
          Dialog.create("Out-of-Range Parameter");
	  Dialog.addMessage("Pixel Size must be greater than 0");
          Dialog.addNumber("Pixel Size (um)",pixelSize,3,9,"");
	  Dialog.show();
	  pixelSize=Dialog.getNumber();
          }

        if (frameRate<=0.0)
          {
          Dialog.create("Out-of-Range Parameter");
	  Dialog.addMessage("Frame Rate must be greater than 0");
          Dialog.addNumber("Frame Rate (fps)",frameRate,3,9,"");
	  Dialog.show();
	  frameRate=Dialog.getNumber();
          }

	listAnalyzeFlowParameters();
	saveConfig();
}


/**************************************************************/
// currently we don't let users see/change arrowCutoff via dialog.
// they can only change it by editing "var arrowCutoff=1.0;"
// statement near other global default values in STAFF.ijm.
//
// you only need to uncomment 2 lines in editPlotParameters
// function to allow user to see/change arrowCutoff:
//   	Dialog.addNumber("Arrow Cutoff",arrowCutoff);
//      arrowCutoff=Dialog.getNumber();

function editPlotParameters()
{
	Dialog.create("Spatial Map Parameters");

	Dialog.addNumber("Max Speed Mapped (um/s)",maxPlotSpeed);
	Dialog.addNumber("Line Thickness (1..12)",lineThickness);
	Dialog.addChoice("Arrow Size", newArray("small", "medium", "large"),arrowSize);
	//Dialog.addNumber("Arrow Cutoff",arrowCutoff);
	Dialog.addChoice("Color Scale", newArray("mpl-inferno", "mpl-magma", "mpl-plasma", "mpl-viridis", "physics"),colorScale);
	Dialog.addChoice("Background Color",newArray("black", "white"),backgroundColor);
	//Dialog.addNumber("Skeleton Line Color",skeletonLineColor);

	Dialog.show();
	// if user clicks OK button in Dialog box,
        // the following code is executed.
        // if user clicks Cancel button in Dialog box,
        // the following code is NOT executed.
	if (logger) print("editPlotParameters\n");

	maxPlotSpeed=Dialog.getNumber();
	lineThickness=Dialog.getNumber();
	arrowSize=Dialog.getChoice();
	//arrowCutoff=Dialog.getNumber();
	colorScale=Dialog.getChoice();
	backgroundColor=Dialog.getChoice();
	//skeletonLineColor=Dialog.getNumber();

	listPlotParameters();
	saveConfig();
}


/**************************************************************/
// Uses the necessary importer to open *all* of a video or image (by opening as a virtual stack).
// Otherwise, just uses 'open(path)'.
// This is necessary because open(VERY-LARGE-FILE.avi) will silently open only the first 1000 frames or so.

function openWholeFile(path){
	if (endsWith(toLowerCase(path), ".avi")){
		if (logger) print("Opening .avi file as virtual stack: " + path);
		run("AVI...", "open=[" + path + "] use");
	} else if (endsWith(toLowerCase(path), ".tif")  || endsWith(toLowerCase(path), ".tiff")){
		if (logger) print("Opening .tif file as virtual stack: " + path);
		run("TIFF Virtual Stack...", "open=[" + path + "]");
		if (nSlices == 1){
			if (logger) print("TIF file is only 1 frame, re-opening as regular image.");
			close();
			open(path);
		}
	} // more 'else if (endsWith(toLowerCase(path), "FILE_EXTENSION){}' here
	else {
		extension = substring(path, lastIndexOf(path, "."));
		print("This macro does not know how to open a " + extension + " file as a virtual stack!\n"
		+ "If this is a video file, ImageJ might not load the entire video.\n"
		+ "If this is an image file, ignore this message. You are fine.");
		open(path);
	}
}


// If a file is not open, open it. (Opened files are always brought to the front.)
// If the file is already open, bring it to the front.
function openAndSelect(path){
	name = File.getName(path);
	if (!isOpen(name)){openWholeFile(path);}
	selectWindow(name);
}


/**************************************************************/

function saveOldFile(path){
	if (File.exists(path)){
		newPath = path + ".old";
		if (File.exists(newPath)){
			File.delete(newPath);
		}
		File.rename(path, newPath);
	}
}


/**************************************************************/
/**************************************************************/
/* macro menu commands:                                       */
/*  1) Open/Create Project                                    */
/*  2) Analyze Skeleton                                       */
/*  3) Edit Time Intervals                                    */
/*  4) Analyze Flow                                           */
/*  5) Produce Spatial Map                                    */
/**************************************************************/

macro "Open/Create Project"
{

/***************************************************/	

function editConfig()
{
  function getNewParameterFilePath(parameter, currentValue){
	if (currentValue == "")
          {
	  showMessage("Please select the " + parameter + ".");
	  return File.openDialog(parameter);
	  }
         else
          {
	  if (getBoolean("Use this " + parameter + "?\n" + currentValue))
           {return currentValue;}
	  else {return File.openDialog(parameter);}
	  }
  }


/**********************************************/	
		
  function getNewParameterNumber(description, unit, currentValue){
	return getNumber(description + " (" + unit + ")", parseFloat(currentValue));
  }


/**********************************************/	

  function getNewParameterFileName(description, suffix, currentValue){
	filename = getString(description, currentValue);
	if (!endsWith(filename, suffix)){filename = filename + suffix;}
	return filename;
  }


/**********************************************/	

  function getNewParameterLUT(name, description, currentValue){
	Dialog.create(name);
	Dialog.addChoice(description, newArray("mpl-inferno", "mpl-magma", "mpl-plasma", "mpl-viridis", "physics"), currentValue);
	Dialog.addHelp("https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html");
	Dialog.show();
	return Dialog.getChoice();
  }


/**********************************************/	

  function getNewParameterOneOf(name, unit, currentValue){
	choices = split(unit, ",");
	Dialog.create(name);
	Dialog.addChoice(name, choices, currentValue);
	Dialog.show()
	return Dialog.getChoice();
  }


/**********************************************/	

  function getNewParameterNumberInRange(name, unit, currentValue){
	numbers = split(unit, ",");
	bottom = parseFloat(numbers[0]);
	top = parseFloat(numbers[1]);
	Dialog.create(name);
	if (currentValue == ""){currentValue = toString((bottom + top) / 2);}
	Dialog.addSlider(name, bottom, top, parseFloat(currentValue));
	Dialog.show();
	return Dialog.getNumber();
  }
	

  // more "getNewParameter<Type>()" go here

/**********************************************/	

  function getNewParameterValue(name, currentValue, type, description, unit){
	// https://github.com/imagej/imagej/issues/171
	name = toString(name);
	currentValue = toString(currentValue);
	type = toString(type);
	description = toString(description);
	unit = toString(unit);
			
	if      (type == "file path")      {return toString(getNewParameterFilePath(name, currentValue));}
	else if (type == "number")         {return getNewParameterNumber(description, unit, currentValue);}
	else if (type == "directory")      {
	     if (name == "project directory"){return List.get("project directory");} // only loadConfig() or "Create/Open Project" can set this
		else {exit("Parameter " + name + " is a directory that isn't a project directory!");}} // no other directories (so far...)
		else if (type == "file name")      {return toString(getNewParameterFileName(description, unit, currentValue));}
		else if (type == "LUT name")       {return toString(getNewParameterLUT(name, description, currentValue));}
		else if (type == "one of")         {return toString(getNewParameterOneOf(name, unit, currentValue));}
		else if (type == "number in range"){return toString(getNewParameterNumberInRange(name, unit, currentValue));}
		// more "else if (type == "<type>"){return getNewParameter<Type>(parameter);}" go here
		else {exit("Parameter '" + name + "' has unknown type '" + type + "'!");}
		return "";
		}
	for (i=0; i<lengthOf(parameters); i++){
	 parameter = parameters[i];
	 if (logger) print(parameter);
	 newValue = getNewParameterValue(parameter, List.get(parameter), parameterTypes[i], parameterDescriptions[i], parameterUnits[i]);
	 List.set(parameter, newValue);
	}

}   // end of editConfig()
	

/***************************************************/		

function saveConfig(){
		if (File.exists(configPath)){
			oldConfigPath = configPath + ".old";
			if (File.exists(oldConfigPath)){File.delete(oldConfigPath);}
			File.rename(configPath, oldConfigPath);
			if (logger) print("Previous configuration saved to " + oldConfigPath);
		}
		config_file = File.open(configPath);
		print(config_file, "// Lines starting with two (or more) slashes will be ignored.\n"
+ "// This .csv file is uses tabs (instead of spaces or commas) to separate columns.\n"
+ "// This file probably doesn't look right in Excel.\n"
+ "// Follow these instructions to view this file in Excel:\n"
+ "//   Edit -> Select All\n"
+ "//   Data -> Text to Columns -> Delimited -> Tab -> General -> Finish\n");
		for (i=0; i<lengthOf(parameters); i++){
			parameter = parameters[i];
			unitText = "";
			if (parameterUnits[i] != ""){unitText = " ("+ parameterUnits[i] + ")";}
			if (logger) print(parameterDescriptions[i] + " = " + List.get(parameter));
			print(config_file, parameter + configDelimiter + List.get(parameter) + configDelimiter + parameterDescriptions[i] + unitText);
		}
		File.close(config_file);
		if (logger) print("Current configuration saved to " + configPath);

  }   // end of saveConfig()


/***************************************************/	
// Open/Create Project macro body
	
	showMessage("Project Directory", "Select the project directory.");
	projectPath = getDirectory("Select Project Directory");
	if (logger) print("projectPath: "+projectPath);
	List.set("project directory",projectPath);
	projectPrefix=File.getName(projectPath)+"_";

	configPath = projectPath + configFile;   // was "config.csv";
        //intervalsPath = projectPath + projectPrefix + intervalsFile;
        //if (logger) print("Open/Create Project: intervalsPath = "+intervalsPath);
	
// Get config for project. Create, fix, or edit as necessary.
	if (File.exists(configPath)){
		loadConfig(configPath);
		copyListToGlobals();
		configIsComplete = true;
		for (i=0; i<lengthOf(parameters); i++){
			parameter = parameters[i];
			if (List.get(parameter) == ""){
				configIsComplete = false;
			}
		}
		if (!configIsComplete){
			// The config file is incomplete.
			showMessage("This project's 'config.csv'. is incomplete. Use the following dialog boxes to edit it.");
			editInputFileNames();
			editOutputFileNames(true);
                	editAnalyzeFlowParameters();
                	editPlotParameters();
			//editConfig();
			//saveConfig();
		} else {
			// There config file is complete, but may need to be changed.
			if(List.get("project directory") != projectPath){
				List.set("project directory", projectPath);
				if (getBoolean("It looks like you copied this config file from somewhere else. Do you want to edit it?")){editConfig();}
				saveConfig(); // fixes project directory config line
			} else if (getBoolean("This project has a valid 'config.csv'. Do you want to edit it?")){
				editInputFileNames();
				editOutputFileNames(true);
            		    	editAnalyzeFlowParameters();
             			editPlotParameters();
				//editConfig();
				//saveConfig();
			}
		}
	} else {
		//showMessage("This project has no 'config.csv'. The following wizard will help you create one.");
		showMessage("This project has no 'config.csv'. Follow instructions to create file.");
		List.set("project directory", projectPath);
		editInputFileNames();
		editOutputFileNames(true);
                editAnalyzeFlowParameters();
                editPlotParameters();
		//editConfig();
		//saveConfig();
	}

	// Remember the last project (and config file) the user opened.
	lastConfigPath = getDirectory("temp") + "flow-analysis-last-project.conf";
	saveOldFile(lastConfigPath);
	lastConfigFile = File.open(lastConfigPath);
	print(lastConfigFile, configPath);
	File.close(lastConfigFile);
	
	showMessage("Project Opened", "The project has been successfully opened.");


//inputPath = getDirectory("Select Input File Directory");
//movieFile = getFile("Select Movie File");
//skeletonFile = getFile("Select Skeleton File");

}   // end of Open/Create Project macro


/**************************************************************/
/**************************************************************/

macro "Analyze Skeleton"
{
	loadConfig(getLastOpenedConfig());
	dependencies = newArray("skeleton file", "project directory");
	confirmExistence(dependencies);

	roiManager("reset");
	roiManager("show none");
	openAndSelect(List.get("skeleton file"));
	showStatus("Analyzing Skeleton...");
	edgeCSVText = eval("script", "result = '';"
	+ "importPackage(Packages.sc.fiji.analyzeSkeleton);"
	+ "analyzer = new AnalyzeSkeleton_();"
	+ "analyzer.setup('', Packages.ij.IJ.getImage());"
	+ "analysis = analyzer.run(AnalyzeSkeleton_.NONE, false, true, null, true, false);"
	+ "for each (skeleton in analysis.getGraph()){"
	+ "  for each (edge in skeleton.getEdges()){"
	+ "    if (edge.getSlabs().size() > 1){"
	+ "      line = '';"
	+ "      for each (var slab in edge.getSlabs()){"
	+ "        if (slab.z != 0){"
	+ "          line = '';"
	+ "          break;"
	+ "        }"
	+ "        line += slab.x + ',' + slab.y + ' ';"
	+ "      }"
	+ "      result += line + '\\n';"
	+ "    }"
	+ "  }"
	+ "}"
	+ "result"
	);
	edgeCSVLines = split(edgeCSVText, "\n");
	numEdges = lengthOf(edgeCSVLines);
	edgeNumDigits = lengthOf(toString(numEdges));
	for(edgeNum = 0; edgeNum < numEdges; edgeNum++){
		edgeName = IJ.pad(toString(edgeNum+1), edgeNumDigits);
		showStatus("Creating ROI " + edgeName + "/" + toString(numEdges));
		showProgress(edgeNum+1, numEdges);
		edgeText = edgeCSVLines[edgeNum];
		points = split(edgeText, " ");
		numPoints = lengthOf(points);
		xcoords = newArray(numPoints);
		ycoords = newArray(numPoints);
		for(pointNum = 0; pointNum < numPoints; pointNum++){
			point = points[pointNum];
			pointParts = split(point, ",");
			xcoords[pointNum] = parseInt(pointParts[0]);
			ycoords[pointNum] = parseInt(pointParts[1]);
		}
		makeSelection("freeline", xcoords, ycoords);
		run("Properties... ", "name=Segment" + edgeName);   // was =Edge
		roiManager("Add");
	}
	roiManager("show all with labels");
	showStatus("Exporting...");
	segmentFilePath = projectPath + projectPrefix + segmentFile;  //List.get("project directory") + List.get("segment file");
	saveOldFile(segmentFilePath);
	roiManager("save", segmentFilePath);
	showStatus("done");
	showMessage("Segment ROIs saved to " + segmentFilePath);

}   // end of Analyze Skeleton macro


/**************************************************************/
/**************************************************************/

macro "Edit Time Intervals"
{

/**********************************************/	
// Names all rectangular ROIs as 
// "interval frames " + frameStart + "-" + frameEnd,
// where all frame numbers are left-padded to be the same length.

  function nameKymoROIs(){
	maximumNameLength = 0;
	numROIs = roiManager("count");
	getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
	numFrameDigits = lengthOf(toString(imageHeight)); // frames of a video = height of a kymograph
	for(i=0; i<numROIs; i++){
	 roiManager("select", i);
	 Roi.getBounds(x, y, width, height);
	 name = "interval frames " + IJ.pad(toString(y), numFrameDigits) + "-" + IJ.pad(toString(y+height-1), numFrameDigits);
	 roiManager("rename", name);
	}
	roiManager("sort");
  }


/**********************************************/

  function saveKymoROIs(){
	numROI=roiManager("count");
	if (numROI<=0) return;

	intervalsPath = projectPath + projectPrefix + intervalsFile;
	if (logger) print("saveKymoROIs: intervalsPath = "+intervalsPath);
	if (File.exists(intervalsPath)) File.delete(intervalsPath);
	respFile = File.open(intervalsPath);

	print(respFile, "//first frame of interval,last frame of interval");
	for(roi=0; roi<numROI; roi++){
	 roiManager("select", roi);
	 if(Roi.getType == "rectangle"){
	   Roi.getBounds(x, y, width, height);
	   print(respFile, toString(y) + respirationDelimiter + toString(y+height-1));
	   if (logger) print("interval from " + toString(y) + " through " + toString(y+height-1));
	   } else if (logger) print("Ignored non-rectangular ROI number " + roi);
	 }

	File.close(respFile);
	showMessage("Saved!", "Intervals have been saved to " + intervalsPath);
  }


/**********************************************/

  function loadKymoROIs(){
	// All imported ROIs will be 90% as wide as the image, 
        //with a 5% gap on the left and right edges.
	getDimensions(kymoWidth, kymoHeight, kymoChannels, kymoSlices, kymoFrames);
	roiWidth = 0.90 * kymoWidth;
	roiX = 0.05 * kymoWidth;
	
	intervalsPath = projectPath + projectPrefix + intervalsFile;
        if (logger) print("loadKymoROIs: intervalsPath = "+intervalsPath);
	respText = File.openAsString(intervalsPath);
	respLines = split(respText, "\n");
	for(lineNum = 0; lineNum<lengthOf(respLines); lineNum++){
		line = respLines[lineNum];
		lineParts = split(line, respirationDelimiter);
		if(lengthOf(lineParts) >= 2 && !startsWith(line, "//")){
			respStart = parseInt(lineParts[0]);
			respEnd = parseInt(lineParts[1]);
			respHeight = respEnd - respStart + 1;
			makeRectangle(roiX, respStart, roiWidth, respHeight);
			roiManager("add");
			}
	 }
	nameKymoROIs();
  }

/**********************************************/
// have the user edit the ROIs / intervals

  function editKymoROIs(){
	roiManager("show all")
	setTool("rectangle");
	waitForUser("Make an ROI for each Time Interval", "Draw a rectangle around each time interval.\n"
        + " \n"
	+ "Add rectangle to ROI manager using 't' key or 'Add' button in ROI manager.\n"
        + " \n"
        + "Delete unwanted selections using 'Delete' button in ROI manager.\n"
        + " \n"
        + "Click OK when done creating rectangles.\n");
/*
	waitForUser("Make an ROI for Each Interval", "Select a rectangle around each interval.\n"
	+ "   (Your rectangles do not have to go all the way left-to-right,\n"
	+ "    but they do need to cross the top and bottom of the interval.)\n"
	+ " \n"
	+ "Add each rectangle to the ROI Manager with its 'add' button,\n"
	+ "    or by pressing the 't' key.\n"
	+ " \n"
	+ "Rectangles that do not correspond to intervals can be removed\n"
	+ "    by clicking the 'delete' button on the ROI Manager.\n"
	+ " \n"
	+ "Click 'OK' when you are done.");
*/

	// Name all ROIs and sort by their y position (the frame where interval stops).
	nameKymoROIs();
	
	// save ROIs in intervals file
        saveKymoROIs();
  }

/**********************************************/

  function makeKymo(){
	// open the video
	openAndSelect(List.get("video file"));
	
	// clear the roiManager and open the project's skeleton ROIs
	roiManager("reset");
	roiManager("show none"); // only highlight the selected ROI, not all of them
	segmentFilePath = projectPath + projectPrefix + segmentFile;  //List.get("project directory") + List.get("segment file");
	roiManager("Open", segmentFilePath);
	
	// pick the longest skeleton segment
	roiManager("measure");
	longestROI = 0;
	lengthOfLongestROI = 0;
	for (roi=0; roi<nResults; roi++){
		length = getResult("Length", roi);
		if (length > lengthOfLongestROI){
			longestROI = roi;
			lengthOfLongestROI = length;
		}
	}
	roiManager("select", longestROI);
	selectWindow("Results");
	run("Close");
	
    // make the kymograph
    showText("Slicing...", "Slicing the video into a kymograph.\nThis may take a minute..."); // showText("") doesn't stop script from running
    run("Reslice [/]...", "output=1.000 start=Top avoid");

    // close notification window
    selectWindow("Slicing...");
    run("Close");
  }

/**********************************************/
// macro Edit Time Intervals body
	
	roiManager("reset");
	loadConfig(getLastOpenedConfig());
	dependencies = newArray("video file", "project directory", "segment file");

	// there might be a kymograph already open
	videoFileName = File.getName(List.get("video file"));
	videoFileNameParts = split(videoFileName, ".");
	videoFileNameNoExtension = videoFileNameParts[0];
	kymographWindowName = "Reslice of " + videoFileNameNoExtension;
	if (isOpen(kymographWindowName)){
		if (getBoolean("A kymograph appears to already be open:\n" + kymographWindowName, "Use it", "Close it and make a new one")){
			// use existing kymograph: do nothing
		} else {
			// close existing kymograph and make a new one
			selectWindow(kymographWindowName);
			close(kymographWindowName);
			makeKymo();
		}
	} else {
		// no open kymograph, must make one
		makeKymo();
	}

    // there might be intervals to load
    roiManager("reset");
    intervalsPath = projectPath + projectPrefix + intervalsFile;
    if (logger) print("EditTimeIntervals: intervalsPath = "+intervalsPath);
    if (File.exists(intervalsPath)){
    	if (getBoolean(intervalsFile + " already exists.", "Load existing intervals", "Ignore")){
		loadKymoROIs();   // load existing intervals
    	}
    }
    editKymoROIs();

}   // end of Edit Time Intervals macro


/**************************************************************/
/**************************************************************/

macro "Analyze Flow"
{

// maximum measured speed was set to 2000 um/s in config file.
// notes say typically 1000-2500.  computed 8*100/0.84=952.38

  function computeMaxMeasuredSpeed()
  {	
  minSegmentLength=parseFloat(List.get("min. segment length"));
  frameRate=parseFloat(List.get("frame rate"));
  pixelSize=parseFloat(List.get("pixel size"));
  maxMeasuredSpeed=minSegmentLength*frameRate/pixelSize;
  List.set("max. speed",maxMeasuredSpeed);   // ,toString(maxMeasuredSpeed) ?
  }


/**********************************************/
// macro Analyze Flow body

	loadConfig(getLastOpenedConfig());
	//dependencies = newArray("video file", "pixel size", "frame rate", "project directory", "segment file", "intervals file", "min. segment length");
	//confirmExistence(dependencies);

        //computeMaxMeasuredSpeed();
        editAnalyzeFlowParameters();
        editOutputFileNames(false);

        Dialog.create("Analyze Flow");
        Dialog.addMessage("Click OK to start flow analysis");
        // undefined function wasCanceled() ?
        // if(Dialog.wasCanceled()) return; 

	// close any substacks that may be left open from a previous run
	close("Substack*");
	
	// open the video
if (logger) print("AnalyzeFlow: video file = "+List.get("video file"));
	openAndSelect(List.get("video file"));
	getDimensions(videoWidth, videoHeight, videoChannels, videoSlices, videoFrames);
	videoFrames = maxOf(videoSlices, videoFrames);
	videoWindowName = getTitle();

	// set the units to be right
	setVoxelSize(pixelSize, pixelSize, pixelSize, "um");
	Stack.setFrameRate(frameRate);

	// load skeleton segments
	roiManager("reset");
	roiManager("show none");
	segmentFilePath = projectPath + projectPrefix + segmentFile;  //List.get("project directory") + List.get("segment file");
	roiManager("Open", segmentFilePath);
	numEdges = roiManager("count");
	roiManager("measure");
	edgeLengths = newArray(numEdges);
	for (edge = 0; edge < numEdges; edge++){
		// results are already scaled to image size in micrometers
		length = getResult("Length", edge);
		edgeLengths[edge] = length;
	}
	selectWindow("Results");
	run("Close");   
	
	// load intervals
	loadKymoROIs2();

	// prepare data strings
	line = "//";
	for (edgeNum = 0; edgeNum < numEdges; edgeNum++){
		line = line + "Segment " + (edgeNum + 1);         // was Edge
		if (edgeNum != numEdges - 1){
			line = line + ",";
		}
	}
	velocitiesText = line + "\n";
	anglesText = line + "\n";
	angleFitsText = line + "\n";
	
	setBatchMode(true);
	// split timeseries into substacks by interval
	for (nonRespiration = 0; nonRespiration < lengthOf(intervalStarts); nonRespiration++){
		selectWindow(videoWindowName);
		showStatus("Creating Substack (" + intervalStarts[nonRespiration] + "-" + intervalEnds[nonRespiration] + ")...");
		run("Make Substack...", "  slices=" + intervalStarts[nonRespiration] + "-" + intervalEnds[nonRespiration]);
		substackWindowName = getTitle();
		substackFPS = Stack.getFrameRate();
		
		// kymograph-ize the substack
		velocitiesLine = "";
		anglesLine = "";
		angleFitsLine = "";
		setBatchMode(true);
		for(edgeNum = 0; edgeNum < numEdges; edgeNum++){
			selectWindow(substackWindowName);
			roiManager("select", edgeNum);
			run("Reslice [/]...", "output=1.000 slice_count=1 avoid");
			kymographWindowName = getTitle();

			// show status (after kymographing because "Reslice [/]..." changes status text)
			showStatus("Interval:" + toString(nonRespiration +  1) + "/" + lengthOf(intervalStarts)
			+ " segment:" + toString(edgeNum + 1) + "/" + numEdges);
			showProgress(((edgeNum + (nonRespiration * numEdges)) / (numEdges * numIntervals)));

	if (flickerCorrection)
	  {
          // use modified version of Jean-Yves Tinevez's Directionality plugin
	  directionalityPlugin="Packages.fiji.analyze.directionality.STAFF_Dir()";
	  }
	 else
	  {
	  // use original version of Jean-Yves Tinevez's Directionality plugin
	  directionalityPlugin="Packages.fiji.analyze.directionality.Directionality_()";
	  }

	directionAndFit = eval("script",
	  "analyzer = new " + directionalityPlugin + ";"
	 + "analyzer.setImagePlus(Packages.ij.IJ.getImage());"
	 + "analyzer.computeHistograms();"
	 + "results = analyzer.getFitAnalysis();"
	 + "gausianPeakCenter = results.get(0)[0];"
	 + "goodnessOfFit = results.get(0)[3];"
	 + "gausianPeakCenter.toString() + \" \" + goodnessOfFit.toString();");

		    resultParts = split(directionAndFit, " ");
		    direction = parseFloat(resultParts[0]);
		    fit = parseFloat(resultParts[1]);

		    velocity = (1/tan(direction)) * substackFPS * pixelSize;
                    velocityString=d2s(velocity,2);
                    if (velocityString=="NaN") if (logger) print("Segment: " + edgeNum +"  velocity: " + velocity + "  direction: "+direction+"  directionAndFit: " + directionAndFit + "  edgeLength: "+ edgeLengths[edgeNum]);    // was Edge:
                    if (edgeLengths[edgeNum] < minSegmentLength) velocitiesLine = velocitiesLine + "short,"; else
                    if (abs(velocity) > maxMeasuredSpeed) velocitiesLine = velocitiesLine + "out,";
                      else velocitiesLine = velocitiesLine + velocityString + ",";

			anglesLine = anglesLine + d2s(direction, 2) + ",";
			angleFitsLine = angleFitsLine + d2s(fit, 2) + ",";
			
			close(kymographWindowName);
		}
		velocitiesText = velocitiesText + velocitiesLine + "\n";
		anglesText = anglesText + anglesLine + "\n";
		angleFitsText = angleFitsText + angleFitsLine + "\n";
		close(substackWindowName);
	}
	setBatchMode(false);
	
	// output the velocities, angles, and goodness-of-fits to .csv files
	file_path = projectPath + projectPrefix + velocitiesFile;
	//if (logger) print("AnalyzeFlow: saving velocities in "+file_path);
	saveOldFile(file_path);
	velocities_file = File.open(file_path);
	print(velocities_file, velocitiesText);
	File.close(velocities_file);
	
	file_path = projectPath + projectPrefix + anglesFile;
	//if (logger) print("AnalyzeFlow: saving angles in "+file_path);
	saveOldFile(file_path);
	angles_file = File.open(file_path);
	print(angles_file, anglesText);
	File.close(angles_file);
	
	file_path = projectPath + projectPrefix + anglesFitFile;
	//if (logger) print("AnalyzeFlow: saving angle fitness in "+file_path);
	saveOldFile(file_path);
	fit_file = File.open(file_path);
	print(fit_file, angleFitsText);
	File.close(fit_file);
	
	showMessage("Flow has been analyzed!");

}   // end of Analyze Flow macro


/**************************************************************/
/**************************************************************/

macro "Produce Spatial Map"
{

/**********************************************/

function loadKymoROIs2(){
	intervalsPath = projectPath + projectPrefix + intervalsFile;
        //if (logger) print("loadKymoROIs2: intervalsPath = "+intervalsPath);
	intervalsText = File.openAsString(intervalsPath);
	intervalsLines = split(intervalsText, "\n");
	intervalStarts = newArray();
	intervalEnds = newArray();

	for(i=0; i<lengthOf(intervalsLines); i++){
		line = intervalsLines[i];
		lineParts = split(line, ",");
		if (lengthOf(lineParts) >= 2 && !startsWith(line, "//")){
			intervalStarts = append(intervalStarts, parseInt(lineParts[0]));
			intervalEnds = append(intervalEnds, parseInt(lineParts[1]));
		}
	}

	numIntervals = lengthOf(intervalStarts);
	//if (logger) print("loadKymoROIs2: " + numIntervals + " ROIs");
}


/**********************************************/
// macro Produce Spatial Map body

close("Scale");
close("Spatial Map");
//close("plot.tif");
	
	loadConfig(getLastOpenedConfig());
	//dependencies = newArray("video file", "project directory", "segment file", "intervals file", "velocities file", "color scale", "plot background color");
	//confirmExistence(dependencies);

        //computeMaxMeasuredSpeed()

	editPlotParameters();
        arrowType="filled "+arrowSize;
        //minSegmentLength=parseFloat(List.get("min. segment length"));

	// open video and get its size
	openAndSelect(List.get("video file"));
	getDimensions(videoWidth, videoHeight, videoChannels, videoSlices, videoFrames);
	videoFrames = maxOf(videoSlices, videoFrames);

	// load skeleton segments
	roiManager("reset");
	segmentFilePath = projectPath + projectPrefix + segmentFile;  //List.get("project directory") + List.get("segment file");
	roiManager("Open", segmentFilePath);
	numEdges = roiManager("count");

	// calculate the length of each edge
	edgeLengths = newArray(numEdges);
	roiManager("measure");
	for (roi=0; roi<nResults; roi++){edgeLengths[roi] = getResult("Length", roi);}
	selectWindow("Results");
	run("Close");
	
	// load intervals
        loadKymoROIs2();

	// make color scale look-up scale
	newImage("Scale", "8-bit ramp", 256, 8, 1);
	run(List.get("color scale"));
	run("RGB Color");
	lut = newArray(256);
	for (val=0; val<256; val++){lut[val] = getPixel(val, 0);}
	
	// make new image stack
	newImage("Spatial Map", "RGB " + List.get("plot background color"), videoWidth, videoHeight, lengthOf(intervalStarts));
	
	// load velocities
	velocitiesFilePath = projectPath + projectPrefix + velocitiesFile; //List.get("project directory") + List.get("velocities file");
	velocitiesText = File.openAsString(velocitiesFilePath);
	velocitiesLines = split(velocitiesText, "\n");
	
	// draw each interval's plot
	setBatchMode(true);
	roiManager("Deselect");
	scale = 255 / parseFloat(List.get("max. plot speed"));
	textLine = -1;

	for (slice=0; slice<nSlices; slice++){   // nSlices comes from image stack lib
		selectWindow("Spatial Map");
		setSlice(slice+1);

		do { // skip velocity lines that start with "//"
			textLine++;
			if (textLine >= lengthOf(velocitiesLines)){exit("There aren't as many velocity rows as there are intervals!");}
			velocitiesLine = velocitiesLines[textLine];
		} while (startsWith(velocitiesLine, "//"));

		velocities = split(velocitiesLine, ",");
		if (numEdges > lengthOf(velocities)){exit("There aren't as many velocities as there are edges in line" + textline + "!");}
		// plot each edge's velocity
		for (edge=0; edge<numEdges; edge++){
			velocity = velocities[edge];
			if (velocity == "too short"){
				exit("The velocities file\n" + velocitiesFilePath + "\n" + "has 'too short' entries.\n" + "Run 'Analyze Flow' to remove these.");
			} else if (edgeLengths[edge] < minSegmentLength){
				if (logger) print("Segment " + edge + " is shorter than ",minSegmentLength," um, not plotting.");    // was Edge
			} else if (abs(parseFloat(velocity)) > maxMeasuredSpeed){
				if (logger) print("Segment " + edge + " is faster than ",maxMeasuredSpeed," um/s in interval " + slice + ", not plotting.");
			} else {
				velocity = parseFloat(velocity);
				speed = minOf(abs(velocity), maxPlotSpeed);
				setColor(lut[scale * speed]);
				roiManager("select", edge);
				Roi.getCoordinates(xpoints, ypoints);
				setLineWidth(lineThickness); //setLineWidth(4);
				for (point=0; point<lengthOf(xpoints)-1; point++){
					drawLine(xpoints[point], ypoints[point], xpoints[point+1], ypoints[point+1]);
				}
				setForegroundColor(lut[scale * speed]);
				pxLength = lengthOf(xpoints);
				middle = pxLength / 2; // not always the true center, but always between 1/(1+sqrt(2)) and sqrt(2)/(1+sqrt(2)) of the true center
				start = minOf(middle+8, pxLength) - 1;
				end = maxOf(middle-8, 0);
				// if (velocity > 0){makeArrow(xpoints[start], ypoints[start], xpoints[end], ypoints[end], arrowSize);}
				// else {            makeArrow(xpoints[end], ypoints[end], xpoints[start], ypoints[start], arrowSize);}
// jlc - flow direction is unreliable for really low velocities, so dont draw arrow for them
if (velocity > arrowCutoff){makeArrow(xpoints[start], ypoints[start], xpoints[end], ypoints[end], arrowType);} else
if (velocity < -arrowCutoff){makeArrow(xpoints[end], ypoints[end], xpoints[start], ypoints[start], arrowType);}
				run("Draw", "slice");
			}
		}
	}

	roiManager("show all");
	roiManager("show none");
	roiManager("deselect");
	setBatchMode(false);

	// dont use spaces in multi-word folder or file names for plotPath.
	// the following run("Save"...) command seems to ignore all
	// text after the first space character.
	//
	plotPath = projectPath + projectPrefix + spatialMapFile;
	saveOldFile(plotPath);
	selectWindow("Spatial Map");
	run("Save", "save=" + plotPath);
	showMessage("Spatial map saved in "+plotPath);

}   // end of Produce Spatial Map macro