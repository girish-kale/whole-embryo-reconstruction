// In this macro, we will fuse the two half embryos based on the 'center of mass' of the intensity distribution.
// Based on the centers of mass for the two halves, we will use voronoi to identify the regions in the two halves
// which should be copied and merged to create the full fused embryo.

roiManager("reset");		close("*");		run("Clear Results"); // clean slate
dialogX=1500;		dialogY=-175;

// Choose the folder that has all the embryos from one coverslip
folder=getDirectory("Choose directory with the embryos"); // typically named as 'sample....'
embryos=getFileList(folder);

embryo=0;
do{ // DO-WHILE loop over all embryos from one slide
	
	//if (startsWith(embryos[embryo], "embryo_")){ // IF statement to pick folders with embryo data
	if (startsWith(embryos[embryo], "embryo_") && endsWith(embryos[embryo], "_13/")){ // IF statement to pick folders with cycle-13 embryo data

		target=folder+embryos[embryo];
		
		if (File.exists(target+"fused_tp_0_vs_0.tif") && File.exists(target+"fused_tp_0_vs_1.tif")) { // IF statement to check if the embryo is already fused

			// Explicitly stating/setting the measurements and color options
			run("Set Measurements...", "area mean center display redirect=None decimal=6");
			
			run("Colors...", "foreground=white background=black selection=white");		
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// We are starting with opening the pre-fused half embryos, and identifying where the center of mass should be for each slice of the whole stack.
// Note that the anterior-posterior axis of the embryo is along the z-axis of the stack.

// In theory, we can also prepare a SUM projection of the z-stack first, and then identify the center of mass. Not sure if that will have any advantage
// over the current procedure. One downside with the sum projection might be that we end up with intensities beyond those allowed in a 32-bit image

			// First processing the top half of the embryo
			
			open(target+"fused_tp_0_vs_0.tif");			nameTop=File.nameWithoutExtension;			run("Grays");
	
			// First, we will set all the 0-pixels to NaN
			run("32-bit");
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(0.1000, 1000000000000000000000000000000.0000);
			run("NaN Background", "stack");
	
			// now, we are estimating the locations of 'center of mass' for each slice, followed by imprining those on a blank image-stack
			run("Clear Results");		run("Measure Stack...");			run("Grays");
			
			xTop=Table.getColumn("XM");		yTop=Table.getColumn("YM");		sliceTop=Table.getColumn("Slice");		run("Clear Results");
	
			// now create the blank image stack
			selectWindow("fused_tp_0_vs_0.tif");		rename("top-blank");		run("8-bit");		run("Multiply...", "value=0 stack");
	
			Stack.getDimensions(widthTop, heightTop, channels, slices, frames); // Dimensions are in pixel units
	
			for(coor=0; coor<xTop.length; coor++){ // FOR loop in paint centers of mass on each slice
				xIterTop=xTop[coor];		yIterTop=yTop[coor];
				
				if (isNaN(xIterTop*yIterTop)) { // If a slice in the top half doesn't have any intensity contribution then...
					
				}else{
					toUnscaled(xIterTop, yIterTop);					selectWindow("top-blank");				setSlice(sliceTop[coor]);
					makeOval(xIterTop-1, yIterTop-1, 2, 2);			run("Fill", "slice");
				}
			} // FOR loop in paint centers of mass on each slice
			
			selectWindow("top-blank");			run("Z Project...", "projection=[Sum Slices]");			run("Measure");			close("top-blank");
			
			selectWindow("SUM_top-blank");		rename("top-blank");			run("8-bit");			run("Multiply...", "value=0");
	
			xTop=getResult("XM");			yTop=getResult("YM");		toUnscaled(xTop, yTop);			selectWindow("top-blank");
			makeOval(xTop-1, yTop-1, 2, 2);		run("Fill");
			
			//////////////////////////////////////////////////////////////////////////
			// Now processing the bottom half of the embryo
			
			open(target+"fused_tp_0_vs_1.tif");			nameBottom=File.nameWithoutExtension;			run("Grays");
			
			// First, we will set all the 0-pixels to NaN
			run("32-bit");
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(0.1000, 1000000000000000000000000000000.0000);
			run("NaN Background", "stack");
	
			// now, we are estimating the locations of 'center of mass' for each slice, followed by imprining those on a blank image-stack
			run("Clear Results");			run("Measure Stack...");			run("Grays");
			
			xBottom=Table.getColumn("XM");		yBottom=Table.getColumn("YM");		sliceBottom=Table.getColumn("Slice");		run("Clear Results");
	
			// now create the blank image stack
			selectWindow("fused_tp_0_vs_1.tif");		rename("bottom-blank");		run("8-bit");		run("Multiply...", "value=0 stack");
	
			Stack.getDimensions(widthBottom, heightBottom, channels, slices, frames); // Dimensions are in pixel units
	
			for(coor=0; coor<xBottom.length; coor++){ // FOR loop in paint centers of mass on each slice
				xIterBottom=xBottom[coor];		yIterBottom=yBottom[coor];
				
				if (isNaN(xIterBottom*yIterBottom)) { // If a slice in the bottom half doesn't have any intensity contribution then...
					
				}else{				
					toUnscaled(xIterBottom, yIterBottom);				selectWindow("bottom-blank");			setSlice(sliceBottom[coor]);
					makeOval(xIterBottom-1, yIterBottom-1, 2, 2);		run("Fill", "slice");
				}
			} // FOR loop in paint centers of mass on each slice
	
			selectWindow("bottom-blank");			run("Z Project...", "projection=[Sum Slices]");			run("Measure");			close("bottom-blank");
			
			selectWindow("SUM_bottom-blank");		rename("bottom-blank");			run("8-bit");			run("Multiply...", "value=0");
	
			xBottom=getResult("XM");			yBottom=getResult("YM");		toUnscaled(xBottom, yBottom);			selectWindow("bottom-blank");
			makeOval(xBottom-1, yBottom-1, 2, 2);		run("Fill");
	
			// Now printing the centers of mass on an image for the steps to follow
			imageCalculator("Max create", "top-blank","bottom-blank");		selectWindow("Result of top-blank");		rename("centers-of-mass");

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Now that we have the centers of mass for the top and bottom halves imprinted on the image, we can go ahead and define the masks for the two halves.
	
			// First, calculating the line that splits the two half embryos
			selectWindow("centers-of-mass");		run("Invert");			run("Voronoi");
	
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(1, 255);
			setOption("BlackBackground", false);
			run("Convert to Mask", "method=Default background=Dark black");
	
			run("Invert");	// might need eroding/dialating, so that the analyzed particles don't touch each other

			run("Analyze Particles...", "size=0-Infinity pixel add");		roiManager("save", target+"mask-roi.zip"); // saving the ROIs for future use, if any
	
			// Now creating the basic masks for the two halves
			// First, the mask for the top half
			selectWindow("top-blank");			run("Multiply...", "value=0");		run("8-bit");				roiManager("Show None");
			roiManager("Select", 0);			run("Fill", "slice");				run("Select None");			run("Divide...", "value=255");
			rename("mask_0");		selectWindow("mask_0");			saveAs("Tiff", target+"mask_0.tif"); // mask saved as 0-1 image
			
			// And now, the mask for the bottom half
			selectWindow("bottom-blank");		run("Multiply...", "value=0");		run("8-bit");				roiManager("Show None");
			roiManager("Select", 1);			run("Fill", "slice");				run("Select None");			run("Divide...", "value=255");
			rename("mask_1");		selectWindow("mask_1");			saveAs("Tiff", target+"mask_1.tif"); // mask saved as 0-1 image
			
			// Of note, the two masks still have a 1-pixel-wide line separating them. In other words, the masks don't overlap
			
			run("Clear Results");		roiManager("reset");		close("*"); // a bit of clean-up

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The masks defined above essentially chalk-out the most relevant regions in the two halves. The steps below will dictate how the two halves 
// will be stitched, how extensive the overlap will be, and if the overlaping regions will have a gradient of intensity or not.
	
			// Let's start with opening the images again. Later on, we'll open the masks as well
			open(target+"fused_tp_0_vs_0.tif");			run("Grays");		open(target+"fused_tp_0_vs_1.tif");			run("Grays");
			
			// by default, we will go for extensive overlap, with a linear gradient of intensity
			extensive=true;			gradient=true;
			
			do{ // DO-WHILE loop to identify the overlap parameters that works the best
			
				selectWindow("fused_tp_0_vs_0.tif");		run("Duplicate...", "title=temp_fused_tp_0_vs_0.tif duplicate");
				selectWindow("fused_tp_0_vs_1.tif");		run("Duplicate...", "title=temp_fused_tp_0_vs_1.tif duplicate");
				
				open(target+"mask_0.tif");			open(target+"mask_1.tif");				
				
				// below we are calculating the approx distance of the two center of masses from the line that separates the half embryos
				radius=round(sqrt((xTop-xBottom)*(xTop-xBottom)+(yTop-yBottom)*(yTop-yBottom))/2); // there is no easy way to calculate square of a number :(
				
				selectWindow("mask_0.tif");		run("Maximum...", "radius=1");		selectWindow("mask_1.tif");		run("Maximum...", "radius=1");
				
				if (extensive==true && gradient==true){
					selectWindow("mask_0.tif");		run("Maximum...", "radius="+round(radius/3));		run("32-bit");		run("Mean...", "radius="+round(radius/3));	
					selectWindow("mask_1.tif");		run("Maximum...", "radius="+round(radius/3));		run("32-bit");		run("Mean...", "radius="+round(radius/3));
				}
				if (extensive==true && gradient==false){
					selectWindow("mask_0.tif");		run("Maximum...", "radius="+round(radius/3));		
					selectWindow("mask_1.tif");		run("Maximum...", "radius="+round(radius/3));
				}
				
				imageCalculator("Multiply stack", "temp_fused_tp_0_vs_0.tif","mask_0.tif"); // top half
				imageCalculator("Multiply stack", "temp_fused_tp_0_vs_1.tif","mask_1.tif"); // bottom half
		
				imageCalculator("Max create stack", "temp_fused_tp_0_vs_0.tif","temp_fused_tp_0_vs_1.tif");
				selectWindow("Result of temp_fused_tp_0_vs_0.tif");		rename("temp_fused");
				
				run("Merge Channels...", "c2=temp_fused_tp_0_vs_0.tif c6=temp_fused_tp_0_vs_1.tif create");
				selectWindow("Composite");		rename("temp_fused-composite");
				
				selectWindow("temp_fused");
				
				// Now we check if the choice of overlap makes sense. If not, we can change the choices and try again.
				Dialog.createNonBlocking(embryos[embryo]);
				Dialog.addMessage("Use orthogonal views to check the quality of fusion.\n");
				Dialog.addCheckbox("extensive overlap", extensive);		
				Dialog.addCheckbox("gradient of intensity", gradient);
				Dialog.addMessage("\nThe overlap looks fine");		Dialog.addCheckbox("Yes?", false); 
				Dialog.setLocation(dialogX,dialogY);				Dialog.show();
				
				extensive=Dialog.getCheckbox();			gradient=Dialog.getCheckbox();			proceed=Dialog.getCheckbox();
				
				if (proceed==false){ // IF statement to know if we have finalised the overlap parameters
					close("temp*");		close("mask*");			
				}else{ // When the parameters are finalised
					close("temp*");
				}// IF statement to know if we have finalised the overlap parameters
				
			} while (proceed==false) // DO-WHILE loop to identify the overlap parameters that works the best
	
// We have finalised what sort of overlap works best			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Now we will process the actual images, and save a grayscale and color composite version of the fused embryo

			imageCalculator("Multiply stack", "fused_tp_0_vs_0.tif","mask_0.tif"); // top half
			imageCalculator("Multiply stack", "fused_tp_0_vs_1.tif","mask_1.tif"); // bottom half
	
			imageCalculator("Max create stack", "fused_tp_0_vs_0.tif","fused_tp_0_vs_1.tif"); // grayscale version of the fused embryo
			selectWindow("Result of fused_tp_0_vs_0.tif");		rename("fused_grayscale");		saveAs("Tiff", target+"fused_grayscale.tif");
			
			run("Merge Channels...", "c2=fused_tp_0_vs_0.tif c6=fused_tp_0_vs_1.tif create"); // color composite version of the fused embryo
			selectWindow("Composite");			rename("fused-composite");					saveAs("Tiff", target+"fused_composite.tif");
			
			close("*");
			
		} // IF statement to check if the embryo is already fused

	} // IF statement to pick folders with embryo data

	embryo=embryo+1;
} while (embryo<embryos.length) // DO-WHILE loop over all embryos from one slide

exit();

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

