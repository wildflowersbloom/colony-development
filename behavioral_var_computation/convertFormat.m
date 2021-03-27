%This script converts FERDA format into the format that Ctrax output (in order to be able to use the older scripts without further adjustment 22.01.15)

%A FERDA file is an cell array with fields:         
%       head_y, back_x, back_y, head_x,  y , x, moviename, theta
%A ctrax file is a struct array with fields:
%        x,    y,    theta,    a,    b,    id,    moviename,    firstframe,    arena,    off,    nframes,    endframe,    timestamps,    matname,    x_mm,    y_mm,    a_mm,    b_mm,    pxpermm,    fps
 
% Load FERDA tracks
%matFileName='/home/casillas/Documents/FERDAWD/f1c5final/part1_out_finer.mat';
%load (matFileName);

% Save into trx into file; now the file will contain a trx and FERDA outputs (will this be to much waste of space?)
%save(matFileName, 'FERDA','trx');


function trx= convertFormat(FERDA) 
numTracklets =size(FERDA,2);
% Create ctrax struct array
trx = struct([]);

%fieldnames(trx)
% Make trx fields for each tracklet
    for i = 1:numTracklets
        nframes=size(FERDA{i}.x,2);
        trx(i).x = FERDA{i}.x;
        trx(i).y = FERDA{i}.y;
        %trx(i).theta = FERDA{i}.orientation; 
        %trx(i).a = FERDA{i}.minor_axis;
        %trx(i).b= FERDA{i}.major_axis;
        trx(i).true_area=NaN(1,nframes);
        trx(i).area = FERDA{i}.area;
        %trx(i).score= FERDA{i}.score;
        trx(i).firstframe = int32(FERDA{i}.frame_offset)+1;
        trx(i).off = -int32(FERDA{i}.frame_offset);
        trx(i).nframes = nframes;
        trx(i).endframe = int32(FERDA{i}.frame_offset)+nframes;
        trx(i).fps = 15;
        %trx(i).moviename=FERDA{i}.moviename;
        trx(i).ID=FERDA{i}.region_id;
        trx(i).region=FERDA{i}.region;
        trx(i).contour=FERDA{i}.region_contour;
        trx(i).counter=zeros(1,nframes); %initialize counter to keep track of ants in blobs
        trx(i).msd=FERDA{i}.mean_squared_displacement;
        trx(i).type=0; %by default
        trx(i).mean_area=mean(int32(FERDA{i}.area));
        trx(i).overestimate=zeros(1,nframes);
        trx(i).underestimate=zeros(1,nframes);
        if trx(i).nframes > 1
            trx(i).velocity=[NaN sqrt((trx(i).x(2:end)-trx(i).x(1:end-1)).^2 + (trx(i).y(2:end)-trx(i).y(1:end-1)).^2 )];
        else 
            trx(i).velocity=NaN;
        end
    end
end
