function [xv,yv]=getSpuriousContours(trx,clicked,varargin)
if numel(varargin)~=2
    xv={};
    yv={};
else
    xv = varargin{1};
    yv = varargin{2};
end
for c=1:size(clicked,2)
    [trx,ac]=trx.get_tracklet(clicked(c));
    xv{end+1}=[ac.contour{1}.x ac.contour{1}.x(1)];
    yv{end+1}=[ac.contour{1}.y ac.contour{1}.y(1)];    
end