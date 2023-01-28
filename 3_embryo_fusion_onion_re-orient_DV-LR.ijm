// In this macro, we will first segment the embryo volume based on the nuclear staining. This will be used to define
// the cortical, basal, and yolk volumes. Following this, we will produce dorsal-ventral and lateral views of the embryo.

// The macro should be executed after the 'embryo_fusion_gray-composite' macro, as we will use the fused embryos thereof.

roiManager("reset");		close("*");		run("Clear Results"); // clean slate
dialogX=1500;		dialogY=-175;

// Choose the folder that has all the embryos from one coverslip
folder=getDirectory("Choose directory with the embryos"); // typically named as 'sample....'
embryos=getFileList(folder);

embryo=0;
do{ // DO-WHILE loop over all embryos from one slide
	
	if (startsWith(embryos[embryo], "embryo_") ){ // IF statement to pick folders with embryo data

		target=folder+embryos[embryo];
		//setBatchMode(true);
		
		if (File.exists(target+"fused_grayscale.tif") && File.exists(target+"fused_composite.tif")) { // IF statement to check if the embryo is already fused

			// Explicitly stating/setting the measurements and color options
			run("Set Measurements...", "area mean center display redirect=None decimal=6");
			
			run("Colors...", "foreground=white background=black selection=white");		
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// We are starting with opening the pre-fused embryos, both the grayscale and composite versions.
// Based on the grayscale verion of the embryo, we'll also first segment-out the volume of the embryo.
		
			open(target+"fused_composite.tif");		nameComp=File.nameWithoutExtension;		
			open(target+"fused_grayscale.tif");		nameGray=File.nameWithoutExtension;		run("Duplicate...", "title=["+nameGray+"_volume] duplicate");
			
			getVoxelSize(width, height, depth, unit); // this will be used when reslicing the images at the end
			output=(round(width*1000))/1000; // a trick to round off till 3rd decimal place
			
			selectWindow(nameGray+"_volume");		run("Gaussian Blur 3D...", "x=2 y=2 z=2"); // Smoothening the signal a bit
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(0.1, 255);			setOption("BlackBackground", true);
			run("Convert to Mask", "method=Default background=Dark black");

// Basic segmentation is now ready. At times, this also includes bright structures outside the embryo (mostly dirt).
// So, now we will try to segment the volume from the 3 orthogonal orientations, and eventually keep the intersectional volume 

			selectWindow(nameGray+"_volume");		run("Reslice [/]...", "output="+output+" start=Top avoid"); // y-view
			selectWindow("Reslice of "+nameGray+"_volume");			rename(nameGray+"_volume-y");
			
			selectWindow(nameGray+"_volume");		run("Reslice [/]...", "output="+output+" start=Left rotate avoid"); // x-view
			selectWindow("Reslice of "+nameGray+"_volume");			rename(nameGray+"_volume-x");
			
	// first the volume segmentation along z-view
			selectWindow(nameGray+"_volume");		slices=nSlices;
			
			for (slice=0; slice<slices; slice++){ // FOR loop to go through z-slices of the thresholded volume
				selectWindow(nameGray+"_volume");			setSlice(slice+1);			run("Measure");
				
				if (getResult("Mean")>0){ // IF statement to perform convex-hull only in the slices that have some intensity contribution
					run("Create Selection");				run("Convex Hull");
					setForegroundColor(255, 255, 255);		run("Fill", "slice");		run("Select None");
				} // IF statement to perform convex-hull only in the slices that have some intensity contribution
			} // FOR loop to go through z-slices of the thresholded volume
			
			run("Clear Results");
			
	// now the volume segmentation along y-view
			selectWindow(nameGray+"_volume-y");		slices=nSlices;
			
			for (slice=0; slice<slices; slice++){ // FOR loop to go through y-slices of the thresholded volume
				selectWindow(nameGray+"_volume-y");			setSlice(slice+1);			run("Measure");
				
				if (getResult("Mean")>0){ // IF statement to perform convex-hull only in the slices that have some intensity contribution
					run("Create Selection");				run("Convex Hull");
					setForegroundColor(255, 255, 255);		run("Fill", "slice");		run("Select None");
				} // IF statement to perform convex-hull only in the slices that have some intensity contribution
			} // FOR loop to go through y-slices of the thresholded volume
			
			run("Clear Results");
			
			selectWindow(nameGray+"_volume-y");		run("Reslice [/]...", "output="+output+" start=Top avoid");			close(nameGray+"_volume-y");
			selectWindow("Reslice of "+nameGray+"_volume-y");			rename(nameGray+"_volume-y"); // reslice reverted
			
			imageCalculator("Min stack", nameGray+"_volume",nameGray+"_volume-y");		close(nameGray+"_volume-y"); // keeping the intersectional volume
			
	// now the volume segmentation along x-view
			selectWindow(nameGray+"_volume-x");		slices=nSlices;
			
			for (slice=0; slice<slices; slice++){ // FOR loop to go through x-slices of the thresholded volume
				selectWindow(nameGray+"_volume-x");			setSlice(slice+1);			run("Measure");
				
				if (getResult("Mean")>0){ // IF statement to perform convex-hull only in the slices that have some intensity contribution
					run("Create Selection");				run("Convex Hull");
					setForegroundColor(255, 255, 255);		run("Fill", "slice");		run("Select None");
				} // IF statement to perform convex-hull only in the slices that have some intensity contribution
			} // FOR loop to go through x-slices of the thresholded volume
			
			run("Clear Results");
			
			selectWindow(nameGray+"_volume-x");		run("Reslice [/]...", "output="+output+" start=Left rotate avoid");		close(nameGray+"_volume-x");
			selectWindow("Reslice of "+nameGray+"_volume-x");			rename(nameGray+"_volume-x"); // reslice reverted
			
			imageCalculator("Min stack", nameGray+"_volume",nameGray+"_volume-x");		close(nameGray+"_volume-x"); // keeping the intersectional volume
			
	// Finally, now we can calculate the Euclidean distances
			selectWindow(nameGray+"_volume");
			run("3D Distance Map", "map=EDT image=["+nameGray+"_volume] mask=Same threshold=1");		
			
			// Following will be used later on to correct for the tilt of DV axis, if any
			selectWindow(nameGray+"_volume");			run("Z Project...", "projection=[Sum Slices]");
			selectWindow("SUM_"+nameGray+"_volume");		rename("DV_vector");			close(nameGray+"_volume");
			
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Based on the Euclidean distance maps, now we'll generate layers, i.e. volumes between surfaces that are parallel to the surface of the 
// segmented embryo volume. In this sense, these aren't concentric circles/surfaces, as the distances are calculated from a reference surface,
// rather than a reference point/line-segment.

			cortical=10; // depth till which the nuclei will be considered to be in the cortical layer (in um)
			fallen=30; // depth till which the recently expelled nuclei reside (in um), beneath the cortical layer
			// everything else would be considered as yolk nuclei
		
// First getting the cortical volume
			selectWindow("EDT");		run("Duplicate...", "title=EDT_cortical duplicate");		selectWindow("EDT_cortical");
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(0.1, cortical);	run("Convert to Mask", "method=Default background=Dark black");
			
			run("Divide...", "value=255 stack");		setMinAndMax(0, 1); // This will create a zero-one image
			
			// this calculation will allow us to keep the pixel intensities only in the current layer and set 0 everywhere else
			// first grayscale
			imageCalculator("Multiply create stack", nameGray+".tif","EDT_cortical");
			selectWindow("Result of "+nameGray+".tif");			rename(nameGray+"_cortical");
			// and now composite
			run("Merge Channels...", "c2=EDT_cortical c6=EDT_cortical create keep");
			imageCalculator("Multiply create stack", nameComp+".tif","Composite");		close("Composite");
			selectWindow("Result of "+nameComp+".tif");			rename(nameComp+"_cortical");

// Now going for the sub-cortical volume containing expelled nuclei
			selectWindow("EDT");		run("Duplicate...", "title=EDT_fallen duplicate");			selectWindow("EDT_fallen");
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(cortical+0.1, fallen);		run("Convert to Mask", "method=Default background=Dark black");
			
			run("Divide...", "value=255 stack");		setMinAndMax(0, 1); // This will create a zero-one image
			
			// this calculation will allow us to keep the pixel intensities only in the current layer and set 0 everywhere else
			// first grayscale
			imageCalculator("Multiply create stack", nameGray+".tif","EDT_fallen");
			selectWindow("Result of "+nameGray+".tif");			rename(nameGray+"_fallen");
			// and now composite
			run("Merge Channels...", "c2=EDT_fallen c6=EDT_fallen create keep");
			imageCalculator("Multiply create stack", nameComp+".tif","Composite");		close("Composite");
			selectWindow("Result of "+nameComp+".tif");			rename(nameComp+"_fallen");
		
// Finally keeping the yolk volume containing (surprise! surprise!!) yolk nuclei
			selectWindow("EDT");		rename("EDT_yolk");			selectWindow("EDT_yolk");
			
			setAutoThreshold("Default dark");
			//run("Threshold...");
			setThreshold(fallen+0.1, 100000);		run("Convert to Mask", "method=Default background=Dark black");
			
			run("Divide...", "value=255 stack");		setMinAndMax(0, 1); // This will create a zero-one image
			
			// this calculation will allow us to keep the pixel intensities only in the current layer and set 0 everywhere else
			// first grayscale
			imageCalculator("Multiply stack", nameGray+".tif","EDT_yolk");
			selectWindow(nameGray+".tif");			rename(nameGray+"_yolk");
			// and now composite
			run("Merge Channels...", "c2=EDT_yolk c6=EDT_yolk create keep");
			imageCalculator("Multiply stack", nameComp+".tif","Composite");		close("Composite");
			selectWindow(nameComp+".tif");			rename(nameComp+"_yolk");

// Here we quickly combine various volumes (cortical, sub-cortical, and yolk) as different color channels in the same hyperstack
			
			// Hyperstack containing all the segmented volumes
			run("Merge Channels...", "c2=EDT_cortical c6=EDT_fallen c7=EDT_yolk create");
			selectWindow("Composite");		rename("volume_layers");
			
			// Hyperstack containing all the grayscale layers from fused embryo
			run("Merge Channels...", "c2=["+nameGray+"_cortical] c6=["+nameGray+"_fallen] c7=["+nameGray+"_yolk] create");
			selectWindow("Composite");		rename(nameGray+"_layers");
			
			// Hyperstack similar to the grayscale one, except the two half-embryos are not merged
			selectWindow(nameComp+"_cortical");		run("Split Channels");
			selectWindow(nameComp+"_fallen");		run("Split Channels");
			selectWindow(nameComp+"_yolk");			run("Split Channels");
			
			run("Merge Channels...", "c1=C1-"+nameComp+"_cortical c2=C1-"+nameComp+"_fallen c3=C1-"+nameComp+"_yolk c5=C2-"+nameComp+"_yolk c6=C2-"+nameComp+"_fallen c7=C2-"+nameComp+"_cortical create ignore");
			selectWindow(nameComp+"_cortical");		rename(nameComp+"_layers");
			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// now that we have prepared the onion slices of the fused embryo, let's re-orient it, to produce dorsal-ventral and lateral views of the embryo

	// In most cases the DV axis of the embryo is not aligned along the X-axis of the image. So, now we are starting that correction.
			selectWindow("DV_vector");		setTool("line");		
			
			if (File.exists(target+"line_DV.roi")){ // IF statement to check if that line ROI already exists
				roiManager("open", target+"line_DV.roi");		roiManager("Select", 0);
			}else{ // IF not then
				Dialog.createNonBlocking("Processing "+embryos[embryo]);
				Dialog.addMessage("Draw line from Dorsal to ventral");		Dialog.setLocation(dialogX,dialogY);		Dialog.show();
				
				roiManager("add");		roiManager("save", target+"line_DV.roi");
			} // IF statement to check if that line ROI already exists
			
			run("Measure");		run("Select None");		thetaDV=getResult("Angle");		run("Clear Results");	roiManager("reset");	close("DV_vector");
			
			run("Tile");
			
			selectWindow("volume_layers");			run("Rotate... ", "angle="+thetaDV+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			selectWindow(nameGray+"_layers");		run("Rotate... ", "angle="+thetaDV+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			selectWindow(nameComp+"_layers");		run("Rotate... ", "angle="+thetaDV+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			// Now the DV axis should be from left to right in the image
			
			// preparing the dorsal-ventral views. In other words, the reslice makes the DV axis aligned along the z-axis of the stack
			selectWindow("volume_layers");					run("Reslice [/]...", "output="+output+" start=Left rotate");
			selectWindow("Reslice of volume_layers");			rename("volume_layers_DV");				close("volume_layers");
			
			selectWindow(nameGray+"_layers");				run("Reslice [/]...", "output="+output+" start=Left rotate");
			selectWindow("Reslice of "+nameGray+"_layers");		rename(nameGray+"_layers_DV");			close(nameGray+"_layers");
			
			selectWindow(nameComp+"_layers");				run("Reslice [/]...", "output="+output+" start=Left rotate");
			selectWindow("Reslice of "+nameComp+"_layers");		rename(nameComp+"_layers_DV");			close(nameComp+"_layers");
			
	// In most cases the AP axis of the embryo is not aligned along the X-axis of the image. So, now we are starting that correction.
			selectWindow(nameGray+"_layers_DV");			run("Z Project...", "projection=[Max Intensity]");
			selectWindow("MAX_"+nameGray+"_layers_DV");		rename("AP_vector");

			selectWindow("AP_vector");		setTool("line");		
			
			if (File.exists(target+"line_AP.roi")){ // IF statement to check if that line ROI already exists
				roiManager("open", target+"line_AP.roi");		roiManager("Select", 0);
			}else{ // IF not then
				Dialog.createNonBlocking("Processing "+embryos[embryo]);
				Dialog.addMessage("Draw line from Anterior to posterior");		Dialog.setLocation(dialogX,dialogY);		Dialog.show();
				
				roiManager("add");		roiManager("save", target+"line_AP.roi");
			} // IF statement to check if that line ROI already exists
			
			run("Measure");		run("Select None");		thetaAP=getResult("Angle");		run("Clear Results");	roiManager("reset");	close("AP_vector");			
			
			selectWindow("volume_layers_DV");			run("Rotate... ", "angle="+thetaAP+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			selectWindow(nameGray+"_layers_DV");		run("Rotate... ", "angle="+thetaAP+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			selectWindow(nameComp+"_layers_DV");		run("Rotate... ", "angle="+thetaAP+" grid=1 interpolation=Bilinear enlarge stack");		run("Remove Overlay");
			// Now the AP axis should be from left to right in the image
			
			// Saving the DV views
			selectWindow("volume_layers_DV");			saveAs("Tiff...", target+"volume_layers_DV.tif");
			selectWindow(nameGray+"_layers_DV");		saveAs("Tiff...", target+nameGray+"_layers_DV.tif");
			selectWindow(nameComp+"_layers_DV");		saveAs("Tiff...", target+nameComp+"_layers_DV.tif");
			
			// preparing and saving the lateral views. In other words, the reslice makes the AP-DV plane aligned along the x-y plane of the stack
			selectWindow("volume_layers_DV.tif");			run("Reslice [/]...", "output="+output+" start=Top");
			saveAs("Tiff...", target+"volume_layers_lateral.tif");
			selectWindow(nameGray+"_layers_DV.tif");		run("Reslice [/]...", "output="+output+" start=Top");
			saveAs("Tiff...", target+nameGray+"_layers_lateral.tif");
			selectWindow(nameComp+"_layers_DV.tif");		run("Reslice [/]...", "output="+output+" start=Top");
			saveAs("Tiff...", target+nameComp+"_layers_lateral.tif");
				
			close("*");		run("Collect Garbage");
			
		} // IF statement to check if the embryo is already fused

	} // IF statement to pick folders with embryo data

	embryo=embryo+1;
} while (embryo<embryos.length) // DO-WHILE loop over all embryos from one slide

exit();

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

