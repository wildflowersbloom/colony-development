% this function will take the area of a cc inside a blob and from a model 
% estimate the number of ants 

function count=count_model(blob_area, single_mean)
%model : use manual_count_in_cc to annotate several, different sized blobs
% and the number of ants within

%%dummy model
%prelim=blob_area/single_mean;
%alpha=1.1;
%count=round(43*(((prelim-1)/142)^alpha)+1);

%% data model
single_mean_model=149.0264; % (S9T9 with pixclass, thr 40)
%single_mean_model=168.9059; % (S9T9 with old intensity segmentation, thr 40)
K=single_mean_model/single_mean;
count=round(0.0027*blob_area*K+0.54);

%count=round(0.002756*single_mean*prelim+0.964);(S9T9 with old intensity segmentation, thr 40)
%count=round(0.0028*single_mean*prelim+1.1)%combined (S9T9, S4T9, intensity, thr30)

%count=round(0.0027*single_mean*prelim+0.54) %(S9T9 with pixclass, thr 40)



