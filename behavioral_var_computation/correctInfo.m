function scalefactor = correctInfo(arena,v,vs,dish_diameter)
    % foraging polygon
    I=read(v,vs);
    %I=I(arena.y1+1:arena.y2,arena.x1+1:arena.x2,:);
    image(I);

    a=arena.cx;
    b=arena.cy;
    c=arena.radius;
    h = imellipse(gca,[a-c, b-c, 2*c, 2*c]);
    h.setFixedAspectRatioMode(true);
    disp('For aspect ratio:  Double click on ellipse to finish editing');
    w = wait(h);
    roi=h.getPosition;
    c=roi(4)/2;
    a=roi(1)+c;
    b=roi(2)+c;
    fprintf('new radius: %2.4f\n', c);

    radius = c;

    scalefactor=radius*2/dish_diameter;
