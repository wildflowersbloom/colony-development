function [trx,listAlive] = findAndRemoveSpuriousFromLoadedPart(trx,xv,yv,listAlive,arena,force)
SF  = (2*arena.radius) / arena.diameter;
SF2 = SF^2;
margin=0 *SF; % pix equiv of 2mm
%what are the tracklets of the currently loaded part
currentPart = trx.currentPartNum;
upperLimit=cumsum(trx.numTracksPerPart);
if currentPart == 1
    firstTracklet = 1;
else
    firstTracklet = upperLimit(currentPart-1)+1;
end
lastTracklet = upperLimit(currentPart);

%if there is already something marked as spurious in this part, we
%don't do anything
typesThisPart = trx.types(firstTracklet:lastTracklet);
if sum(typesThisPart==3)>0 && force==0
    return
end
spu = [];
for t=firstTracklet:lastTracklet %for each trx element
    %% mark spurious
    [trx,at]=trx.get_tracklet(t);
    if (trx.currentPartNum ~=currentPart)
        disp('PART CHANGED WHILE MARKING SPURIOUS!!!!!!!!!');
    end
    % if 20 percent contour is outside the arena, mark as spurious detection
    distToArenaCenter = sqrt(double( (at.contour{1}.x-arena.cx).^2 + (at.contour{1}.y-arena.cy).^2 ));
    if sum(distToArenaCenter*SF > arena.radius*SF-margin) > 0.2 * numel(at.contour{1}.x)
        trx=trx.modify_property(t,'type',3);
        spu=[spu;t];
        continue
    end
    xq=int32(at.x);
    yq=int32(at.y);
    for c=1:numel(xv)
        in=inpolygon(xq,yq,xv{c},yv{c});
        % if centroids of the whole tracklet are inside contour of marked
        % spurious,then mark spurious
        if sum(in)>=numel(in)*0.95
            trx=trx.modify_property(t,'type',3);
            spu=[spu;t];
            break
        end
    end
end
if numel(spu) > 0
    trx = trx.remove_tracklets(spu);
    listAlive=trx.listAlivePerFrame;
    fprintf('\t removed %d spurious from  part %d,numel spu %d\n',numel(spu),currentPart,numel(xv));
end




