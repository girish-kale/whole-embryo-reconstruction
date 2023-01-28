// This macro prepares images pre-processed using the BigWarp for the BigStitcher plugin.
// BigWarp does interest-points based transformation, and is used to do a pre-alignment of the stacks.
// Following this, BigStitcher refines the alignment further, and exports the fused image.

close("*");		dialogX=1500;		dialogY=-175;

// Choose the folder that has all the embryos from one coverslip
folder=getDirectory("Choose directory with the embryos"); // typically named as 'sample....'
embryos=getFileList(folder);

embryo=0;
do{ // DO-WHILE loop over all embryos from one slide

	if (startsWith(embryos[embryo], "embryo_")){ // IF statement to pick folders with embryo data

		target=folder+embryos[embryo];		files=getFileList(target); // this keeps changing for every embryo

		if (File.exists(target+"aligned.xml")) { // IF statement to check if the embryo is processed before
			close("*");
		}else{

			if (File.exists(target+"aligned-0.tif") && File.exists(target+"aligned-1.tif")) { // IF statement to check if the embryo is aligned
		
////////////////////////////////////////////////////////////////////////////
// Now we align the images in BigStitcher. This will automatically recognize
// the 'aligned' images in the target folder.
	
				run("BigStitcher", "select=define define_dataset=[Automatic Loader (Bioformats based)] project_filename=aligned.xml path=["+target+"aligned-*] exclude=10 pattern_0=Tiles move_tiles_to_grid_(per_angle)?=[Move Tiles to Grid (interactive)] how_to_load_images=[Re-save as multiresolution HDF5] dataset_save_path=["+target+"] check_stack_sizes subsampling_factors=[{ {1,1,1}, {2,2,2}, {4,4,4} }] hdf5_chunk_sizes=[{ {16,16,16}, {16,16,16}, {16,16,16} }] timepoints_per_partition=1 setups_per_partition=0 use_deflate_compression export_path=["+target+"aligned]");
		
				Dialog.createNonBlocking("Pause for BigStitcher");
				Dialog.addMessage("Try various options to refine the alignment,\nuse 'Resave Dataset- As compressed HDF5...'\nexport the stiched image using 'nearest neighbor',\nclose the BigStitcher, and click ok");
				Dialog.setLocation(dialogX,dialogY);		Dialog.show();

// comment on automating BigStitcher: it is not clear if BigStitcher can be closed from macro. And as a result, the output needs to be
// processed manually.
		
				images=getList("image.titles");
		
				for (image=0; image<images.length; image++) {
					selectImage(images[image]);			setMinAndMax(0, 255);			run("8-bit");			saveAs("TIFF...", target+images[image]);
				} // all fused images are now saved
		
				close("*");
				
			} // IF statement to check if the embryo is aligned
	
		} // IF statement to check if the embryo is processed before

	} // IF statement to pick folders with embryo data

	embryo=embryo+1;
} while (embryo<embryos.length) // DO-WHILE loop over all embryos from one slide

exit();

