function threshold = trySeveralThresholdsOnOneFrame(v,trx,arena,single_mean,single_sd, expectedNumAnts,video_start)
close all

threshold = 0;
while threshold <= 0
    partNum = trx.currentPartNum;
    initialFrame = min(getstructarrayfield(trx.currentStruct,'firstframe'));
    finalFrame   = max(getstructarrayfield(trx.currentStruct,'endframe'));
    listAlive=trx.listAlivePerFrame;

    foundFrameWithQueen = 0;
    %% find a frame that has a queen
    for f = initialFrame:finalFrame
        aliveNow=listAlive{f};
        vstatus = trx.types(aliveNow);    % [2,1,0,3....] corresponding to ['queen' 'single' 'blob' 'spurious' ...]
        % skip if queen blob was not found
        if (sum(vstatus==2)==1) && (sum(vstatus==0)>=1)
            foundFrameWithQueen = 1;
            break
        end
    end
    if foundFrameWithQueen > 0

        I=read(v,f+video_start);
        I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);

        trxO = trx;
        subplotNum = 0;
        rowNum = 1;
        for intensity_thr = 34:4:54
            if subplotNum>2
                rowNum = 2
            end
            colNum = mod(subplotNum,3);
            subplot('Position',[0.01+colNum*0.33 0.99-rowNum*0.49 0.32 0.47]);
            
            subplotNum = subplotNum + 1;

            trx = trxO;
            %f = min(getstructarrayfield(trx.currentStruct,'firstframe'));

            n_singles=0;
            in_blobs=0;

            % count singles
            n_singles=numel(find(vstatus==1));
            % list blobs
            listBlobs = aliveNow(find(vstatus==0));
            I=read(v,f+video_start);
            I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);

            %%
            if numel(listBlobs) > 0
                intI=(I(:,:,2)); % green channel intensity image, contrast is best
                thrI=intI<intensity_thr; %logical
                %thrI=imdilate(thrI,se); %dilation
                Ired = I(:,:,3);
                Iblue = I(:,:,1);
                Igreen = I(:,:,2);
                Ired(find(thrI))=85;
                ItoShow =  cat(3,Ired,Igreen,Iblue);
                trackletBlobs = {};
                %% It is in three different for loops to allow for paralellization
                for j=1:numel(listBlobs)
                    e=listBlobs(j);
                    [trx,ae]=trx.get_tracklet(e);
                    trackletBlobs{j} = ae;
                end
                countersBlobls = zeros(numel(listBlobs),1);
                areasBlobls = zeros(numel(listBlobs),1);
                %we explicitly name this variables so that parfor can work
                singleMean = single_mean;
                singleSD   = single_sd;
                for j=1:numel(listBlobs)

                    ae = trackletBlobs{j};
                    [counter , blob_area] = computeCounterForBlob(ae,singleMean,singleSD,thrI,f);
                    countersBlobls(j) = counter;
                    areasBlobls(j) = blob_area;
                    in_blobs=in_blobs+counter;
                    fprintf('tracklet %d area %d \n',listBlobs(j),blob_area);

                end
                for j = 1:numel(listBlobs)
                    e=listBlobs(j);
                    trx=trx.modify_property(e,'true_area',f,double(areasBlobls(j)));
                    trx=trx.modify_property(e,'counter',f,countersBlobls(j));
                end
                %%
            end
            % queen counter
            for k = find(vstatus==2)
                q=aliveNow(k);
                trx=trx.modify_property(q,'counter',f, expectedNumAnts-in_blobs-n_singles);
               
            end

            fprintf('threshold:%d \t Q:%d \n',intensity_thr ,expectedNumAnts-in_blobs-n_singles);  
            aliveNow=listAlive{f};
            imshow(ItoShow);
            title(num2str(intensity_thr))
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            axis square
            hold on;
            text(20,20,num2str(f),'Color', 'white');
            linecolors = {'b','g','r','y','w'};
            lcount = 0;

            for i=1:length (aliveNow)
                a=aliveNow(i);
                [trx,this_tracklet]=trx.get_tracklet(a);
                lf=f+this_tracklet.off;
                plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1); %(region idx 0, image idx 1)
                text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','white');  
                %text(this_tracklet.x(lf)+12,this_tracklet.y(lf)+12,num2str(trx.types(a)), 'Color','red'); 
                %text(this_tracklet.x(lf)+12,this_tracklet.y(lf)+12,num2str(a), 'Color','red'); 
                text(this_tracklet.x(lf)+12,this_tracklet.y(lf)+12,num2str(this_tracklet.true_area(lf)), 'Color','red'); 
            end


        end

        threshold=input('\n what is the best threshold (0 for new frame)?');
    end
    if threshold <= 0 
        numParts = numel(trx.numTracksPerPart);
        newPart  = mod(partNum + 1,numParts); 
        trx=trx.load_part(newPart);
    end
    close all
end