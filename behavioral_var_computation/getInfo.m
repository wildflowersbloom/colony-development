function INFO = getInfo(arena,v,vs,params)

INFO={};
%[trx,a]=trx.get_tracklet(1);
INFO.fps=v.FrameRate;
INFO.cx=arena.cx;
INFO.cy=arena.cy;
INFO.radius=arena.radius;
INFO.x1=arena.x1;
INFO.x2=arena.x2;
INFO.y1=arena.y1;
INFO.y2=arena.y2;

% user input
INFO.nexpected=params.ants_counted;
INFO.diameter=params.arena_diameter_mm;
INFO.scalefactor=INFO.radius*2/INFO.diameter;
% foraging polygon
I=read(v,vs);
I=I(arena.y1:arena.y2,arena.x1:arena.x2,:);
str='y';
i=0;
while str=='y'
    i=i+1
    fprintf('Delimit foraging area \n');
    [P,Px,Py]=roipoly(I);
    INFO.foragpolyx{i} = Px;
    INFO.foragpolyy{i} = Py;
    INFO.areaMasks{i} = P;
    str = input('Another area of interest? y/n ', 's');
end

fprintf('Move elipse to whole dish, for scale factor computation \n');
newratio = correctInfo(arena,v,vs,90);
INFO.scalefactor = newratio;

