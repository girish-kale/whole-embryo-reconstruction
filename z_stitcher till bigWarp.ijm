// This macro prepares images to be processed using the BigWarp plugin.
// BigWarp does interest-points based transformation, and we'll be using this to do a pre-alignment of the stacks.

roiManager("reset");		close("*");		dialogX=1500;		dialogY=-175;

// Choose the folder that has all the embryos from one coverslip
folder=getDirectory("Choose directory with the embryos"); // typically named as 'sample....'
embryos=getFileList(folder);

embryo=28;		lineWidth=400;
do{ // DO-WHILE loop over all embryos from one slide

	existanceCellularization=indexOf(embryos[embryo], "inter_14"); // identifying the embryos that are not in cellularization

	if (startsWith(embryos[embryo], "embryo_") && existanceCellularization<0){ // IF statement to pick folders with embryo data
		
//	if (startsWith(embryos[embryo], "embryo_")){ // IF statement to pick folders with embryo data

		target=folder+embryos[embryo];		files=getFileList(target); // this keeps changing for every embryo

		for (file=0; file<files.length; file++){ // FOR loop through all files associated with one embryo
			
			existanceBottom=indexOf(files[file], "DRAQ5-bottom");		existanceTop=indexOf(files[file], "DRAQ5-top");
			
			if (existanceBottom>0 && endsWith(files[file], ".tif")){ // IF-ELSE statements to only open the 'bottom' file
				//setBatchMode(true);
				open(target+files[file]);			nameBottom=File.nameWithoutExtension;		run("Grays");

				// little bit of filtering to smoothen the image and reduce the size of the nuclei a bit along z-axis
				run("Minimum 3D...", "x=1 y=1 z=3");		run("Median 3D...", "x=1 y=1 z=1");		//run("Maximum 3D...", "x=1 y=1 z=1");
				run("16-bit");		run("HiLo");		setSlice(floor(nSlices*2/3));
				
				//setBatchMode("exit and display");		
				run("Enhance Contrast", "saturated=0.35");

				// the filtering affects the overall contrast of the image. So, re-adjusting that below
				Dialog.createNonBlocking("processing "+embryos[embryo]);
				Dialog.addMessage("Pause to adjust brightness-contrast");
				Dialog.setLocation(dialogX,dialogY);				Dialog.show();

				getMinAndMax(min, max);			maxBottom=8*floor((max+1)/8)-1;		setMinAndMax(0, maxBottom);		run("8-bit");		run("Grays");

				// starting with reducing the image dimentions to improve speed
				Stack.getDimensions(wid, hei, channels, slices, frames);
				
				run("Size...", "width="+(wid/2)+" height="+(hei/2)+" depth="+nSlices+" constrain average interpolation=Bilinear");

				getVoxelSize(width, height, depth, unit);		Stack.getDimensions(wid, hei, channels, slices, frames);

				setTool("line");				setSlice(floor(nSlices/2));			run("Z Project...", "projection=[Max Intensity]");
				
				Dialog.createNonBlocking("processing "+embryos[embryo]);
				Dialog.addMessage("Pause to draw line from Anterior to Posterior");
				Dialog.addNumber("Line width =", lineWidth);
				Dialog.setLocation(dialogX,dialogY);				Dialog.show();

				lineWidth=Dialog.getNumber();

				roiManager("add");				roiManager("select", 0);			roiManager("save selected", target+nameBottom+"_line.roi");
				close("MAX*");				selectWindow(nameBottom+".tif");		roiManager("select", 0);
				run("Straighten...", "title=["+nameBottom+"_AP] line="+lineWidth+" process");		close(nameBottom+".tif");			roiManager("reset");
				
				// The process of straightening removes image calibrations. So...
				Stack.setXUnit("micron");		Stack.setYUnit("micron");		Stack.setZUnit("micron");
				run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" pixel_width="+width+" pixel_height="+height+" voxel_depth="+depth);

				// The process of straightening also makes the image 32-bit. So...
				selectWindow(nameBottom+"_AP");		//run("Brightness/Contrast...");
				setMinAndMax(0, 255);			run("8-bit");

				run("Reslice [/]...", "output="+width+" start=Left");			close(nameBottom+"_AP");
				selectWindow("Reslice of "+nameBottom+"_AP");					rename(nameBottom+"_AP");
			
			} else if(existanceTop>0 && endsWith(files[file], ".tif")){ // IF-ELSE statements to only open the 'top' file
				//setBatchMode(true);
				open(target+files[file]);			nameTop=File.nameWithoutExtension;			run("Grays");

				// little bit of filtering to smoothen the image and reduce the size of the nuclei a bit along z-axis
				run("Minimum 3D...", "x=1 y=1 z=3");		run("Median 3D...", "x=1 y=1 z=1");		//run("Maximum 3D...", "x=1 y=1 z=1");
				run("16-bit");		run("HiLo");		setSlice(floor(nSlices*2/3));
				
				//setBatchMode("exit and display");		
				run("Enhance Contrast", "saturated=0.35");

				// the filtering affects the overall contrast of the image. So, re-adjusting that below
				Dialog.createNonBlocking("processing "+embryos[embryo]);
				Dialog.addMessage("Pause to adjust brightness-contrast");
				Dialog.setLocation(dialogX,dialogY);				Dialog.show();

				getMinAndMax(min, max);			maxTop=8*floor((max+1)/8)-1;		setMinAndMax(0, maxTop);		run("8-bit");		run("Grays");
				
				// starting with reducing the image dimentions to improve speed
				Stack.getDimensions(wid, hei, channels, slices, frames);
				
				run("Size...", "width="+(wid/2)+" height="+(hei/2)+" depth="+nSlices+" constrain average interpolation=Bilinear");

				getVoxelSize(width, height, depth, unit);		Stack.getDimensions(wid, hei, channels, slices, frames);

				setTool("line");				setSlice(floor(nSlices/2));			run("Z Project...", "projection=[Max Intensity]");
				
				Dialog.createNonBlocking("processing "+embryos[embryo]);
				Dialog.addMessage("Pause to draw line from Anterior to Posterior ");
				Dialog.addNumber("Line width =", lineWidth);
				Dialog.setLocation(dialogX,dialogY);				Dialog.show();

				lineWidth=Dialog.getNumber();

				roiManager("add");				roiManager("select", 0);			roiManager("save selected", target+nameTop+"_line.roi");
				close("MAX*");				selectWindow(nameTop+".tif");		roiManager("select", 0);
				run("Straighten...", "title=["+nameTop+"_AP] line="+lineWidth+" process");			close(nameTop+".tif");				roiManager("reset");
				
				// The process of straightening removes image calibrations. So...
				Stack.setXUnit("micron");		Stack.setYUnit("micron");		Stack.setZUnit("micron");
				run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" pixel_width="+width+" pixel_height="+height+" voxel_depth="+depth);

				// The process of straightening also makes the image 32-bit. So...
				selectWindow(nameTop+"_AP");		//run("Brightness/Contrast...");
				setMinAndMax(0, 255);			run("8-bit");

				run("Reslice [/]...", "output="+width+" start=Left");			close(nameTop+"_AP");
				selectWindow("Reslice of "+nameTop+"_AP");						rename(nameTop+"_AP");
				
				run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear stack");			run("Remove Overlay");
				
			} // IF-ELSE statements to figure out which files are being opened
			
		} // FOR loop through all files associated with one embryo
		
////////////////////////////////////////////////////////////////////////////
// By now we should have 2 images open, one corresponding to bottom half, and another for the top half of the embryo.

		selectWindow(nameTop+"_AP");		Stack.getDimensions(widthTop, heightTop, channels, slices, frames);
		
		selectWindow(nameBottom+"_AP");		Stack.getDimensions(widthBottom, heightBottom, channels, slices, frames);
		
		selectWindow(nameTop+"_AP");		run("Canvas Size...", "width="+(widthTop)+" height="+(heightBottom+heightTop)+" position=Top-Center zero");			setSlice(floor(nSlices/2));
		
		selectWindow(nameBottom+"_AP");		run("Canvas Size...", "width="+(widthBottom)+" height="+(heightBottom+heightTop)+" position=Bottom-Center zero");	setSlice(floor(nSlices/2));

////////////////////////////////////////////////////////////////////////////
// Now we align the images in BigWarp. Press F2, and make sure that the transformation type is 'rotation'.
// The 'rotation' mode essentially has 6 degrees of freedom, i.e. translation or rotation along x, y, or z axis.
// Other modes also include scaling, or non-linear deformations, and are thus not desirable.
		do{
			run("Big Warp", "moving_image=["+nameTop+"_AP] target_image=["+nameBottom+"_AP]");
	
			Dialog.createNonBlocking("Pause for BigWarp");
			Dialog.addMessage("'F2' transform type is 'rotation',\nidentify and save the 'landmarks.csv',\nthen use 'export as ImagePlus',\nclose BigWarp, and click ok");
			Dialog.setLocation(dialogX,dialogY);		Dialog.show();
	
			selectWindow(nameTop+"_AP channel 1_"+nameTop+"_AP channel 1_xfm_0");		rename(nameTop+"_AP-aligned");
	
			run("Merge Channels...", "c2=["+nameTop+"_AP-aligned] c6=["+nameBottom+"_AP] create keep");		close(nameTop+"_AP-aligned");

			selectWindow("Composite");		rename("aligned");

			Dialog.createNonBlocking("Checking transformed image");
			Dialog.addCheckbox("Repeat?", false);		
			Dialog.setLocation(dialogX,dialogY);		Dialog.show();

			repeat=Dialog.getCheckbox();

		}while (repeat==true)

		selectWindow("aligned");		run("Z Project...", "projection=[Max Intensity]");			run("RGB Color");			
		close("MAX_aligned");			rename("MAX_aligned");
		
		// this is for the whole embryo
		setTool("rectangle");		selectWindow("MAX_aligned");
		
		Dialog.createNonBlocking("Pause to draw a box");
		Dialog.addMessage("...to keep only the relevant part of the embryo,\nmaking sure that it captures all of it");
		Dialog.setLocation(dialogX,dialogY);				Dialog.show();

		roiManager("add");				roiManager("select", 0);		roiManager("save selected", target+"embryo_crop.roi");

		selectWindow("aligned");		roiManager("select", 0);		run("Duplicate...", "title=aligned_crop duplicate");		save(target+"aligned_crop_B-"+maxBottom+"_T-"+maxTop+".tif");			
		
		close("aligned");			selectWindow("aligned_crop");		rename("aligned");

		selectWindow("MAX_aligned");	roiManager("select", 0);		run("Duplicate...", "title=MAX_aligned_crop");

		close("MAX_aligned");			selectWindow("MAX_aligned_crop");		rename("MAX_aligned");
		
		roiManager("reset");		
		
		// this is for the top image
		setTool("rectangle");		selectWindow("MAX_aligned");
		
		Dialog.createNonBlocking("Pause to draw a box");
		Dialog.addMessage("...to keep only the relevant part of the embryo,\nmaking sure that it captures the top half");
		Dialog.setLocation(dialogX,dialogY);				Dialog.show();

		roiManager("add");				roiManager("select", 0);		roiManager("save selected", target+nameTop+"_crop.roi");

		selectWindow("aligned");		roiManager("select", 0);		run("Duplicate...", "title=aligned-0 duplicate channels=1");		save(target+"aligned-0.tif");			
		
		roiManager("reset");

		// this is for the bottom image
		setTool("rectangle");		selectWindow("MAX_aligned");
		
		Dialog.createNonBlocking("Pause to draw a box");
		Dialog.addMessage("...to keep only the relevant part of the embryo,\nmaking sure that it captures the bottom half");
		Dialog.setLocation(dialogX,dialogY);				Dialog.show();

		roiManager("add");				roiManager("select", 0);		roiManager("save selected", target+nameBottom+"_crop.roi");

		selectWindow("aligned");		roiManager("select", 0);		run("Duplicate...", "title=aligned-1 duplicate channels=2");		save(target+"aligned-1.tif");			
		
		roiManager("reset");			close("*");
		
////////////////////////////////////////////////////////////////////////////
// This should be followed by the image alignment in BigStitcher, which will automatically
// identify and open the 'aligned' images saved above.

	} // IF statement to pick folders with embryo data

	embryo=embryo+1;
} while (embryo<embryos.length) // DO-WHILE loop over all embryos from one slide

exit();

