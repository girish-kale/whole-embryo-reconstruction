// This macro sorts files into the various folders, one per embryo.
// Each folder will contain the trans-illumination image, and fluorescence images for the same embryo.

folder=getDirectory(""); // This is the directory with all embryos from one slide, AND imaged from both sides

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Following lines due to pre-organised folder structure
folderBottom=folder+"bottom/";		filesBottom=getFileList(folderBottom);
folderTop=folder+"top/";			filesTop=getFileList(folderTop);

// This will be used to sort the images based on their suffix number.
// In theory, both 'chronos' arrays should be the same. Unnecessarily explicit piece of code.
chronosBottom=newArray(filesBottom.length);		chronosTop=newArray(filesTop.length);

for (file=0; file<filesBottom.length; file++) {
	// extract the suffix string from the file name to fill the arrays
	chronosBottom[file]=substring(filesBottom[file], indexOf(filesBottom[file], ".tif")-3, indexOf(filesBottom[file], ".tif"));
	chronosTop[file]=substring(filesTop[file], indexOf(filesTop[file], ".tif")-3, indexOf(filesTop[file], ".tif"));
}

Array.sort(chronosBottom,filesBottom);
Array.sort(chronosTop,filesTop); // 'files' gets sorted the same way as 'chronos'
//Array.show(chronosBottom, chronosTop, filesBottom, filesTop);

numEmbryos=filesBottom.length/2; // each embryo has 2 files associated with it, trans-illumination and fluorescent

embryo=0;
do { // DO-WHILE loop to sort the embryo images
	
///////////////////////////////////////////////////////////////////////////////////////////
// First, we'll open and process the images from the 'bottom' folder
	open(folderBottom+filesBottom[embryo*2]);
	nameTransB=File.name;
	nameTransShortB=substring(nameTransB, 0, indexOf(nameTransB, "DRAQ5")-1);
	nameTransShortB=nameTransShortB+substring(nameTransB, indexOf(nameTransB, "trans")+5, indexOf(nameTransB, ".lif"));
	nameTransShortB=nameTransShortB+"_trans-bottom_"+substring(nameTransB, indexOf(nameTransB, ".tif")-3, indexOf(nameTransB, ".tif"));
	rename(nameTransShortB);
	
	open(folderBottom+filesBottom[embryo*2+1]);
	nameFluoB=File.name;
	nameFluoShortB=substring(nameFluoB, 0, indexOf(nameFluoB, "DRAQ5")-1);
	nameFluoShortB=nameFluoShortB+substring(nameFluoB, indexOf(nameFluoB, "trans")+5, indexOf(nameFluoB, ".lif"));
	nameFluoShortB=nameFluoShortB+"_DRAQ5-bottom_"+substring(nameFluoB, indexOf(nameFluoB, ".tif")-3, indexOf(nameFluoB, ".tif"));
	rename(nameFluoShortB);

	getDimensions(width, height, channels, slices, frames);			hyperStackBottom=channels*slices*frames;
	
///////////////////////////////////////////////////////////////////////////////////////////
// Now, we'll open and process the images from the 'top' folder
	open(folderTop+filesTop[embryo*2]);
	nameTransT=File.name;
	nameTransShortT=substring(nameTransT, 0, indexOf(nameTransT, "DRAQ5")-1);
	existance=indexOf(nameTransT, "_flip");
	if (existance>0){
		nameTransShortT=nameTransShortT+substring(nameTransT, indexOf(nameTransT, "trans_flip")+10, indexOf(nameTransT, ".lif"));
	}else{
		nameTransShortT=nameTransShortT+substring(nameTransT, indexOf(nameTransT, "trans")+5, indexOf(nameTransT, ".lif"));
	}
	nameTransShortT=nameTransShortT+"_trans-top_"+substring(nameTransT, indexOf(nameTransT, ".tif")-3, indexOf(nameTransT, ".tif"));
	rename(nameTransShortT);
	
	open(folderTop+filesTop[embryo*2+1]);
	nameFluoT=File.name;
	nameFluoShortT=substring(nameFluoT, 0, indexOf(nameFluoT, "DRAQ5")-1);
	existance=indexOf(nameFluoT,"_flip");
	if (existance>0){
		nameFluoShortT=nameFluoShortT+substring(nameFluoT, indexOf(nameFluoT, "trans_flip")+10, indexOf(nameFluoT, ".lif"));
	}else{
		nameFluoShortT=nameFluoShortT+substring(nameFluoT, indexOf(nameFluoT, "trans")+5, indexOf(nameFluoT, ".lif"));
	}
	nameFluoShortT=nameFluoShortT+"_DRAQ5-top_"+substring(nameFluoT, indexOf(nameFluoT, ".tif")-3, indexOf(nameFluoT, ".tif"));
	rename(nameFluoShortT);

	getDimensions(width, height, channels, slices, frames);			hyperStackTop=channels*slices*frames;
	
///////////////////////////////////////////////////////////////////////////////////////////
// Here we only make a guess for the stage. It doesn't need to be a 100% accurate.
// This might often be the case with pre-cellularization embryos.
// If the guess feels off, we can always rename the folder later on.
	
	run("Tile");

	Dialog.createNonBlocking("Guess the stage for embryo "+embryo);
	stage=newArray("inter_10","mito_10","inter_11","mito_11","inter_12","mito_12","inter_13","mito_13","inter_14-early","inter_14-mid","inter_14-late","pre-inter_10");
	Dialog.addRadioButtonGroup("cell cycle", stage, 6, 2, "inter_10");
	//Dialog.setLocation(1500,-600);
	Dialog.setLocation(100,-400);
	Dialog.show();

	embryoStage=Dialog.getRadioButton;

	// IF statement to make sure that both images are proper z-stacks.
	// ELSE, the embryo folder will have an underscore appended to it
	if (hyperStackBottom>1 && hyperStackTop>1){
		target=folder+"embryo_"+IJ.pad(embryo+1,3)+"_"+embryoStage+"/";
	}else if (hyperStackBottom>1){
		target=folder+"embryo_"+IJ.pad(embryo+1,3)+"_"+embryoStage+"_bottom/";
	}else if (hyperStackTop>1){
		target=folder+"embryo_"+IJ.pad(embryo+1,3)+"_"+embryoStage+"_top/";
	}else{
		target=folder+"embryo_"+IJ.pad(embryo+1,3)+"_"+embryoStage+"_skip/";
	}
	File.makeDirectory(target);
	
	selectWindow(nameTransShortB);		save(target+nameTransShortB);
	selectWindow(nameFluoShortB);		save(target+nameFluoShortB);

	selectWindow(nameTransShortT);		save(target+nameTransShortT);
	selectWindow(nameFluoShortT);		save(target+nameFluoShortT);

	close("*");
///////////////////////////////////////////////////////////////////////////////////////////

	embryo=embryo+1; // loop variable increases
} while (embryo<numEmbryos) // DO-WHILE loop to sort the embryo images
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

exit();

