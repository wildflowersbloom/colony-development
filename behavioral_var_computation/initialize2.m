% Intitialize modified to output whether user did (1)left click or (3)right click

function [obj clicked side] = initialize2 (obj,f,v,listAlive,video_start,windowTitle,arena,varargin)

if length(varargin)>0
    correct_counter=1;
else
    correct_counter=0;
end
% load frame and draw countour, blob countour
I=read(v,f+video_start);
I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);
%intI=(I(:,:,2)); % green channel intensity image, contrast is best
%thrI=intI<30; %logical
imshow(I);
title(windowTitle)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
axis square
hold on;
text(20,20,num2str(f),'Color', 'red','FontSize',20);
linecolors = {'b','g','r','y','w'};
lcount = 0;
if iscell(listAlive)
    aliveNow=listAlive{f};
else
    aliveNow=listAlive;
end
for i=1:length (aliveNow)
    a=aliveNow(i);
    [obj,this_tracklet]=obj.get_tracklet(a);
   
    lf=f+this_tracklet.off;
    plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1); %(region idx 0, image idx 1)
    text(this_tracklet.x(lf)+2,this_tracklet.y(lf),num2str(this_tracklet.counter(lf)), 'Color','white');
    %text(double(this_tracklet.contour{lf}.x(1)+2),double(this_tracklet.contour{lf}.y(1)),num2str(this_tracklet.counter(lf)), 'Color','white');
    %text(double(this_tracklet.contour{lf}.x(1)+11),double(this_tracklet.contour{lf}.y(1)+9),num2str(this_tracklet.true_area(lf)), 'Color','red');
    %text(this_tracklet.x(lf)+2,this_tracklet.y(lf)+12,num2str(obj.types(a)),'Color','red');
    %text(this_tracklet.x(lf)+2,this_tracklet.y(lf)+12,num2str(a),'Color','red');
    %text(this_tracklet.x(lf)+2,this_tracklet.y(lf)+12,num2str(this_tracklet.counter(lf)+this_tracklet.underestimate(lf)-this_tracklet.overestimate(lf)), 'Color','red');
    hold on 
%     if obj.types(a) == 2 %plot queen trajectory
%         lcount = lcount +1;
%         allxq=int32(this_tracklet.x);
%         allyq=int32(this_tracklet.y);
%         style = strcat(linecolors{mod(lcount,numel(linecolors))+1},'o-');
%         plot(allxq,allyq,style)
%         text(this_tracklet.x(lf)+12,this_tracklet.y(lf)+10,num2str(a), 'Color','red');
%     end
end
hold off

clicked=[];
side=[];
%ask for usr input and store count estimates (left adds, right subtracts)
[ux,uy,bu]=ginput();

for q=1:length(ux)
    xq=ux(q);
    yq=uy(q);
    bq=bu(q);
    minDist=Inf;
    besta=0;
    for j=1:length(aliveNow)
        clear in xv yv
        a=aliveNow(j);
        [obj,this_tracklet]=obj.get_tracklet(a);
        lf=f+this_tracklet.off;
        xv=double([this_tracklet.contour{lf}.x this_tracklet.contour{lf}.x(1)]);
        yv=double([this_tracklet.contour{lf}.y this_tracklet.contour{lf}.y(1)]);
        [in,~] = inpolygon(xq,yq,xv,yv); %this requires xv to be closed!!
        dist=min(pdist2([xq,yq],[xv',yv']));
        if dist< minDist
            minDist=dist;
            besta=a;
        end
        if in
            besta=a;
            minDist=0;
        end
    end
    if in > 0 | minDist<20 % allow user to click 20 pixels to closest polygon
        [obj,this_tracklet]=obj.get_tracklet(besta);
        lf=f+this_tracklet.off;
        clicked = [clicked besta];
        side= [side bq];
        if correct_counter==1
            %find queen to also adjust counter
            vstatus = obj.types(aliveNow);
            queenie=find(vstatus==2);
            if numel(queenie)>0
                queenie=aliveNow(queenie(1));
                [obj,this_queenie]=obj.get_tracklet(queenie);
                lfq=f+this_queenie.off;
                if bq==1
                    obj=obj.modify_property(besta,'underestimate',f,this_tracklet.underestimate(lf)+1);
                    obj=obj.modify_property(queenie,'overestimate',f,this_queenie.overestimate(lfq)+1);
                end
                if bq==3
                    obj=obj.modify_property(besta,'overestimate',f,this_tracklet.overestimate(lf)+1);
                    obj=obj.modify_property(queenie,'underestimate',f,this_queenie.underestimate(lfq)+1);
                end
            else
                if bq==1
                    obj=obj.modify_property(besta,'underestimate',f,this_tracklet.underestimate(lf)+1);
                    
                end
                if bq==3
                    obj=obj.modify_property(besta,'overestimate',f,this_tracklet.overestimate(lf)+1);
                end
                
            end
        end
    end
end


%update image
I=read(v,f+video_start);
I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);
image(I);
set(gcf,'units','normalized','outerposition',[0 0 1 1])
axis square
hold on;
for i=1:length (aliveNow)
    a=aliveNow(i);
    [obj,this_tracklet]=obj.get_tracklet(a);
    lf=f+this_tracklet.off;
    plot(this_tracklet.contour{lf}.x+1, this_tracklet.contour{lf}.y+1);
    text(this_tracklet.x(lf),this_tracklet.y(lf),num2str(this_tracklet.counter(lf)+this_tracklet.underestimate(lf)-this_tracklet.overestimate(lf)), 'Color','white');
    hold on
end
text(20,20,num2str(f),'Color', 'yellow','FontSize',20);
hold off

end
