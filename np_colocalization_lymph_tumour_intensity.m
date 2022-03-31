% iDISCO Analysis Script 2
% This MATLAB script quantifies the nanoparticle intensity as a function of
% the lymphatic vessel distance after applying the vessel mask. 

function [pre_vessels, pre_nanoparticle, pre_nuclei] = pre_process_func(vessels,nanoparticle_masked,tissue,save_dir,sample_name);

% set matlab folder to return at the end
matlab_folder = pwd;
% select folder with the data to read files
data_folder = uigetdir('','Select folder with image files'); 


cd(data_folder);

%select save directory
save_dir = uigetdir('','Select save folder');

% select and read vessel file


% select and read nanoparticle file
nanoparticle_masked_file = uigetfile('','Select processed nanoparticle image file');
nanoparticle_masked_info = imfinfo(nanoparticle_masked_file);
nanoparticle_masked = imread(nanoparticle_masked_file);
for ii = 2 : size(nanoparticle_masked_info, 1)
    temp_nanoparticle_tiff = imread(nanoparticle_masked_file, ii);
    nanoparticle_masked = cat(3 , nanoparticle_masked, temp_nanoparticle_tiff);
end



num_slices = size(nanoparticle_masked,3);


img_mean = zeros(num_slices,1);
for i = 1 : size(nanoparticle_masked_info, 1)
    img_mean(i) = mean(nonzeros(nanoparticle_masked(:,:,i)));
end 



nanoparticle_BG_file = uigetfile('','Select background nanoparticle image file');
nanoparticle_BG_info = imfinfo(nanoparticle_BG_file);
nanoparticle_BG = imread(nanoparticle_BG_file);
for ii = 2 : size(nanoparticle_BG_info, 1)
    temp_BG_nanoparticle_tiff = imread(nanoparticle_BG_file, ii);
    nanoparticle_BG = cat(3 , nanoparticle_BG, temp_BG_nanoparticle_tiff);
end
Background_NP = mean(nanoparticle_BG);

img_BG = zeros(num_slices,1);
for b = 1 : size(nanoparticle_BG_info, 1)
    img_BG(b) = mean(nonzeros(nanoparticle_BG(:,:,b)));
end 

% input sample name for rename in the terminal
% sample_name = input('Enter the name of the smple: ','s');
[~,name,~]=fileparts(pwd);
sample_name = name; %strcat(cell2mat(inputdlg('Enter the name of the smple:')));
shortfile = sample_name;
display(['Analyzing ' shortfile])


plot(img_mean, 'b');
hold on;
plot(img_BG, 'r');


tic;


cd(save_dir)

result = table(img_mean,img_BG);
table_name = strcat(shortfile,'_Results_nanoparticle_along_lymphs.csv'); 
labled_table = array2table(result, 'VariableNames', {'mean intensity' 'background'});
labled_table_2 = splitvars(labled_table);
writetable(labled_table_2, table_name) 
   
toc 
cd(matlab_folder)


end
