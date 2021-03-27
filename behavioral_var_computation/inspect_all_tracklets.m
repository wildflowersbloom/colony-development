resulDir=params.path_FERDA_output;
videoFileName=params.path_video_file;
fps = params.fps;
video_start = params.video_start;

samplerate = 5; % how often do we display

filesToLoad = {strcat(resulDir,'object.mat'), strcat(resulDir,'arena.mat') };
for ftln = 1:numel(filesToLoad)
    ftl = filesToLoad{ftln};
    if exist(ftl, 'file') ~= 2
        fprintf('skipping  because of missing %s \n\n',  ftl);
        return
    end
    load(ftl);
end
trx.pathToParts=resulDir;
listAlive=trx.listAlivePerFrame;
numParts = numel(trx.numTracksPerPart);
v=VideoReader(videoFileName);
pn = 1;
trx=trx.load_part(pn);
trx_struct = trx.currentStruct;
deaths = getstructarrayfield(trx_struct,'endframe');
births = getstructarrayfield(trx_struct,'firstframe');
maxFrameThisPart = max(deaths);
nframes=maxFrameThisPart -min(births)+1;
firstFrame_inPart=min(births);
listAliveThisPart = cell(nframes,1);
%tracklets offset is the difference between the tracklet numbers in the
%current track, and the tracklet numbers
tracklet_number_Offset = sum(trx.numTracksPerPart(1:pn))-size(trx_struct,2);
listAliveThisPart{1} = find(births==1+firstFrame_inPart-1) + tracklet_number_Offset;
for f_inPart=2:nframes
    listAliveThisPart{f_inPart} = find((births<=f_inPart+firstFrame_inPart-1) & (deaths>=f_inPart+firstFrame_inPart-1)) + tracklet_number_Offset;
end

initialFrame = min(getstructarrayfield(trx_struct,'firstframe'));
finalFrame   = max(getstructarrayfield(trx_struct,'endframe'));

for f=initialFrame:samplerate:initialFrame+500
    I=read(v,f+video_start);
    I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);              
    imshow(I);
    %Plot image here
    %plot([1,1200],[1,1200],'wo');
    hold on

    f_inPart = f - firstFrame_inPart+1;
    all_tracklets_f = listAliveThisPart{f_inPart};
    alive_tracklets = listAlive{f};
    dead_tracklets = setdiff(all_tracklets_f,alive_tracklets);
    fprintf('f: %d, all:%d, alive:%d, dead:%d \n',...
        f,numel(all_tracklets_f),numel(alive_tracklets),numel(dead_tracklets))

    for tn = 1:numel(alive_tracklets)
        a=alive_tracklets(tn);
        [trx,this_tracklet]=trx.get_tracklet(a);
        lf=f+this_tracklet.off;
        if trx.types(a)==1
            %singles
            plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1,'w.-')
            text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','white');
        elseif trx.types(a)==2
            plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1,'m.-')
            text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','magenta');

        else
            %blobs & queen
            plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1,'g-')
            text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','green');


        end

    end

    for tn = 1:numel(dead_tracklets)
        % marked spurious
        a=dead_tracklets(tn);
        [trx,this_tracklet]=trx.get_tracklet(a);
        lf=f+this_tracklet.off;
        plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1,'r-')
        text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','red');
    end


    pause((1/(samplerate*fps)))
    if numel(dead_tracklets) > 0
        pause(0.2)
    end

    hold off
end

    
