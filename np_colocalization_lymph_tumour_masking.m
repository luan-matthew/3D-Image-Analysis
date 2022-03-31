% % iDISCO Analysis Script 1
% This MATLAB script creates a mask of the segmented tumour image and
% applies it to the nanoparticle channel. 

function [pre_vessels, pre_nanoparticle, pre_nuclei] = pre_process_func(vessels,nanoparticle,tissue,save_dir,sample_name);

% set matlab folder to return at the end
matlab_folder = pwd;
% select folder with the data to read files
data_folder = uigetdir('','Select folder with image files'); 


cd(data_folder);

%select save directory
save_dir = uigetdir('','Select save folder');

% select and read vessel file
vessel_file = uigetfile('','Select vessel image file');
vessel_info = imfinfo(vessel_file);
vessels = imread(vessel_file,1);
for ii = 2 : size(vessel_info, 1)
    temp_vessels_tiff = imread(vessel_file, ii);
    vessels = cat(3 , vessels, temp_vessels_tiff);
end

% select and read nanoparticle file
nanoparticle_file = uigetfile('','Select nanoparticle image file');
nanoparticle_info = imfinfo(nanoparticle_file);
nanoparticle = imread(nanoparticle_file);
for ii = 2 : size(nanoparticle_info, 1)
    temp_nanoparticle_tiff = imread(nanoparticle_file, ii);
    nanoparticle = cat(3 , nanoparticle, temp_nanoparticle_tiff);
end

% select and read tissue background file
tissue_file = uigetfile('','Select tissue background image file');
tissue_info = imfinfo(tissue_file);
tissue = imread(tissue_file);
for ii = 2 : size(tissue_info, 1)
    temp_nanoparticle_tiff = imread(tissue_file, ii);
    tissue = cat(3 , tissue, temp_nanoparticle_tiff);
end




% input sample name for rename in the terminal
% sample_name = input('Enter the name of the smple: ','s');
[~,name,~]=fileparts(pwd);
sample_name = name; %strcat(cell2mat(inputdlg('Enter the name of the smple:')));
shortfile = sample_name;
display(['Pre-processing ' shortfile])


%define tissue boundaries
% Ilastik labeling, 1 = tumour area, 2 = possible vessels, 3 = skin area
% and empty background
tissue_mask = tissue<3;
%define vessel segmentation, vessel = 1 in ilastik
vessel_mask = vessels==1;
%crop vessels
vessel_crop = vessel_mask.*tissue_mask;
%find NP and vessel colocalization
NP_crop = int16(nanoparticle).*int16(vessel_crop);


tic;


%Write pre-processed files
cd(save_dir)

nanoparticle_processed_name = strcat(shortfile,'_colocalized_nanoparticle.tif');
vessels_processed_name = strcat(shortfile,'_croped_vessels.tif');

num_slices = size(vessels,3);



imwrite(uint16(vessel_crop(:,:,1)),vessels_processed_name);
        
   for p = 2:num_slices
            imwrite(uint16(vessel_crop(:,:,p)),vessels_processed_name, 'WriteMode','append');
   end
   
   
imwrite(uint16(NP_crop(:,:,1)),nanoparticle_processed_name);
        
   for p = 2:num_slices
            imwrite(uint16(NP_crop(:,:,p)),nanoparticle_processed_name, 'WriteMode','append');
   end
   
   

toc
   
   
cd(matlab_folder)



end
