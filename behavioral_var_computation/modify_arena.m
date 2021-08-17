%function to check and modify arena paramters
function arena=modify_arena(arena,trx,v,video_start,ff)
a=arena.cx;
b=arena.cy;
c=arena.radius;
modify_a='y';
while(strcmp(modify_a,'y'))
    % Print frame ff
    I=read(v,ff+video_start);
    I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);
    imshow(I); hold on;
    % Print detections
    firstAlive=trx.listAlivePerFrame{ff};
    for al=1:numel(firstAlive)
        [trx,this_tracklet]=trx.get_tracklet(firstAlive(al));        
        lf=ff+this_tracklet.off;
        fprintf('\n frame:%d tracklet %d s first%d off%d -> localframe%d', ff, firstAlive(al), this_tracklet.firstframe, this_tracklet.off, lf);
        plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1)
    end
    % Print frame with arena, as a check
    margin=0;
    r=rectangle('Position', [a-c,b-c,c*2,c*2], 'Curvature', [1 1]);
    set(r,'edgecolor','r')
    
    
    % Allow user to modify
    modify_a=input('Visual check of arena, type  y to modify or ENTER to continue \n','s');
    if strcmp(modify_a,'y')
        fprintf('current values: center %2.4f, %2.4f, radius: %2.4f\n', a,b,c);
        h = imellipse(gca,[a-c, b-c, 2*c, 2*c]);
        h.setFixedAspectRatioMode(true);
        disp('Double click on ellipse to finish editing');
        w = wait(h);
        roi=h.getPosition;
        c=roi(4)/2;
        a=roi(1)+c;
        b=roi(2)+c;
        fprintf('new values: center %2.4f, %2.4f, radius: %2.4f\n', a,b,c);
    end
end
arena.cx=a;
arena.cy=b;
arena.radius=c;
end
