function Data_cell = np_dist_average()
matlab_folder = pwd;

Main_folder = uigetdir();
cd(Main_folder);
files = dir('*M*');

Data_cell = {};

for  i = 1:size(files,1)
    
    dir_timepoint = strcat(Main_folder,'\',files(i).name);
    cd(dir_timepoint)

    tic

    %Gets image name 
    [~,shortfile] = fileparts(files(i).name); %Gets image name 

    %Displays image being anaylzed and gets the file directory
    display(['Analyzing NPs around vessels for ' shortfile]) 
    main_dir_file_name = strcat(dir_timepoint,'\',shortfile);
    
    %finds post_processed_image for analyzing 
   
    post_pro_dir = strcat(dir_timepoint, '\', 'Post processing images 100k');
    %vess_thresh_dir = strcat(main_dir_file_name,'\ves_thresh');
    %cd(vess_thresh_dir)
    
    %finds ilastik segmented image in main folder and loads image
    cd(post_pro_dir)
    vess_thresh_name = strcat(shortfile,'_post_processed_vessels.tif');
    ves_thresh = loadtiff(vess_thresh_name);

    
    if(sum(sum(sum(ves_thresh))) == 0)
        continue
    end
    
    
    %Gets vessel and NP image names then loads the images
    
    cd(dir_timepoint)
    np_name = strcat(shortfile,'_iso_ch2.tif');
    
    vess_name = strcat(shortfile,'_iso_ch3.tif');
    
    np_ch = loadtiff(np_name);
    vess_ch = loadtiff(vess_name); 
    
    
    
    %Locates microscope metadata, reads the metadata and gets the
    %conversion from pixels into micrometer.
    
    metadata_name = strcat(shortfile,'_iso_info.csv');
    %metadata = readtable(metadata_name,delimitedTextImportOptions);
    %px_per_um = str2num(metadata.ExtraVar1{2})*1E6;
    
    
    metadata = readtable(metadata_name);
        %### Grabs the z value of the pixel and sets that as the size.
    px_per_um = metadata.newphys(3)*10^6;

    %makes binary image of segmented vessels
    %vess_thresh = smartthresh(vess_ch,2,10);
        %### makes a 3D array of 1's in the shape of the threshold vessel
        %image. 
    vess_bin = ves_thresh~=0;

    
    
  
   

    %creates a distance transform of the binary vessel image
        %### Finds the pixel distance from the vessel = 1's in the 3D array.
        % See the matlab documentation for example. Vessels are labeled
        % with a 1. Everything else is 0. When run through bwdist, it
        % assigns all of the zeros with a value from the closest 1. So for
        % example, the vessels are assigned with a zero value - since its
        % right on top of the vessel. The pixels next to the vessel are
        % given values of 1 since they are 1 pixel away from the 1. Pixels
        % two vessels away are given values of 2 and so on. 
    vess_dist = bwdist(vess_bin);

    %specifies the size of the z_pixel (this is the lightsheet thickness)
    z_physsize = px_per_um


    %Takes the 3D vessel distance transform array and makes it into 1D and
    %rounds to the nearest whole number.
    
    %works by scanning 3D array row by row for every slice. 
    %I.e linear_dist(3)= vess_dist(1,3,1) 
        %### the vess_dist(:) turns the 3d array into a 1d one. 
    linear_dist = round(single(vess_dist(:)));
    
    %Linear_all concatenates np array to an array of ones the size of
    %linear_dist
        %### NP array also transformed into a 1D array. cat makes a 2D
        % array, 2 columns, 1st is all 1's, second are the np channel
        % .
        % with the above linear_dist, you know how far each pixel
        % in the image is away from the vessel. Because the np was imaged
        % at the same time, those pixels in the np channel are also that
        % distance from the vessel. e.g. at
        % pixel location [1,1,1] say the bwdist function gave a value of 5.
        % the np signal at [1,1,1] would therefore be a distance 5 away
        % from the vessel. if you tallied all of these up, you get np
        % signal vs. distance in a distribution.
        %### First column used to tally the
        % number of pixels at a particular distance in the for loop below. 
    linear_all = cat(2, ones(size(linear_dist)), (np_ch(:)));
    
    

    
    %Column 1 in the array will display the conversion of pixel distances 
    %into micrometer distances 
    
    %Column 2:  the number of voxels in the image at a given distance
    
    %Column 3:  Sum of NP intensity at a given distance region
   
        %### Setting Max and Min Distances
        %minimum is set at the vessel wall (a value of zero is inside)
        %maximum is set at 350um
        max_d = floor(350/z_physsize);
        min_d = 1; 
    
    part_vs_dist_raw = zeros(max_d+1-min_d,3);
    pixeldistances = min_d:1:max_d;
    
    %for loop which looks at a given pixeldistance from 1:max.
    %asks logical questions where does linear distance = given
    %pixeldistance
    
    % reassigns corresponding row values in part_vs_dist_raw
    
    %Recall that linear_all = (ones, np_values) in the last line of the for 
    %loop we are reassigning the ones column to the sum of the 
    %temp_locations which is a logical array obtained from asking where
    %does linear_dist == pixeldistances. We also obtain the corresponding
    %NP values
        %### Loops through all of the distance values. Finds the total NP
        %signal for that distance value. Distance from LV is defined as 
        %pixel distance times z per pixel. 
        %### The voxel intensity, i.e. 2nd column, is just the sum of the
        %NP signal at that pixel distance. 
        %### Linear_all has two columns, the first is all 1s and the second
        %is the NP intensity.  'Voxel Number' is the number of voxels
        %that are at a particular distance from the LV. 
    for c = 1: size(pixeldistances,2) 
        temp_locations = linear_dist==pixeldistances(c);
        part_vs_dist_raw(c,:) = [pixeldistances(c)*z_physsize sum(linear_all(temp_locations,:),1)];
    end
    
    %Appends a 4th column to the matrix for futher storing results of
    %processing data.
    part_vs_dist = [part_vs_dist_raw zeros(max_d+1-min_d,1) zeros(max_d+1-min_d,1) zeros(max_d+1-min_d,1)];

    
    %Convert into mean NP intensity (divide by volume)
        %### This is the total NP intensity divided by the number of voxels
        % that intensity was found in. So its the average NP intensity per voxel at
        % a given distance. 
    part_vs_dist(:,6) = part_vs_dist(:,3)./part_vs_dist(:,2);

    %Remove background noise - set lowest conc to 0
    part_vs_dist(:,3) = part_vs_dist(:,3)-min(part_vs_dist(:,3));  
    
    
    part_vs_dist(:,6) = part_vs_dist(:,6)./max(part_vs_dist(:,6));  
    part_vs_dist(:,6) = part_vs_dist(:,6)-min(part_vs_dist(:,6));  
    
    %Normalize relative to max (Note, this is not useful to use across
    %different time points or images). 
    
    part_vs_dist(:,4) = part_vs_dist(:,3)./max(part_vs_dist(:,3));  
    
    

    %Calculation of average distances, voxel normalized (line 233) and
    %non-normalized (line 232)
    distancesum_avg = sum(part_vs_dist(:,4).*part_vs_dist(:,1))./sum(part_vs_dist(:,4));
    distancesum_avg_voxel = sum(part_vs_dist(:,6).*part_vs_dist(:,1))./sum(part_vs_dist(:,6))
    
    part_vs_dist(1,5) = distancesum_avg;
    part_vs_dist(2,5) = distancesum_avg_voxel;
    
    % Outputs normalized nanoparticle intensity at vessel wall
    nanoparticle_intensity_at_wall = part_vs_dist(1,6)

    %Saves results in a new subfolder called results if the results folder
    %does not already exsit.
    save_dir_name = strcat(main_dir_file_name,'\Results');


     if exist(save_dir_name, 'dir')~=7
            mkdir(save_dir_name);
     end
     
    cd(save_dir_name)
    
    %saves the ilatik segmentation image in the results folder. This is not
    %necessary further processing is done to the image. 
    img_skel_name = strcat(shortfile,'_vess_thresh_ilastik.tif');
    clear options;
                options.overwrite = true;
                options.compress = 'lzw';
                saveastiff(uint16(vess_bin), img_skel_name, options);

    results_table = table(part_vs_dist);
    table_name = strcat(shortfile,'_Results_Vessel_analysis_ilastik_dist200_nonorm_bkrndsub.csv');

    %writetable(results_table,table_name);
    
    labled_table = array2table(part_vs_dist, 'VariableNames', {'Distance_From_Vessel', 'Number_of_Voxels', 'Mean_Nanoparticle_Intensity', 'Normalized_Nanoparticle_Intensity', 'Distances','Voxel_NP_ \Normalized'});
    labled_name = strcat(shortfile, '_Distance_analysis_results.csv')
    writetable(labled_table, labled_name)
    toc
   
    
    Data_cell{i} = {shortfile,part_vs_dist(:,1),part_vs_dist(:,4),distancesum_avg,part_vs_dist(:,6),distancesum_avg_voxel};
    
end

     
    
end
