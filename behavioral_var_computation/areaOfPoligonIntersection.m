function jaccard=areaOfPoligonIntersection(poly1,poly2)

x1 = double(poly1.x);
y1 = double(poly1.y);
x2 = double(poly2.x);
y2 = double(poly2.y);

minX1 = min(x1);
minY1 = min(y1);
width1 = max(x1) - minX1;
height1 = max(y1) - minY1;
vector1 = [minX1,minY1,width1,height1];

minX2 = min(x2);
minY2 = min(y2);
width2 = max(x2) - minX2;
height2 = max(y2) - minY2;
vector2 = [minX2,minY2,width2,height2];

areaRectangleIntersection = rectint(vector1,vector2);
areaRectangleUnion = (height1*width1+height2*width2) - areaRectangleIntersection;
jaccardRectangle = areaRectangleIntersection / areaRectangleUnion;
if jaccardRectangle > 0.9 || jaccardRectangle==0
    jaccard = jaccardRectangle;
    return
end

try   
    [K1,V1]=convhull(x1,y1);
    x1 = x1(K1);
    y1 = y1(K1);
    [K2,V2]=convhull(x2,y2);
    x2 = x2(K2);
    y2 = y2(K2);
    
    OneInTwo = inpolygon(x1,y1,x2,y2);
    TwoInOne = inpolygon(x2,y2,x1,y1);
    interPoligonX = [x1(OneInTwo) , x2(TwoInOne)];
    interPoligonY = [y1(OneInTwo) , y2(TwoInOne)];
    if numel(interPoligonX)<=0 || numel(interPoligonY)<=0
        jaccard=0;
        return
    end
    [X,Y] = simplify_pol(interPoligonX,interPoligonY); %otherwise we simplify contour
    interPoligonX = X;
    interPoligonY = Y;
    if numel(interPoligonX)<3
        jaccard=0;
        return
    end
    
    [~,VI] = convhull(interPoligonX,interPoligonY);
    areaConvHullUnion = V1+V2 - VI;
    areaConvHullIntersection = VI;
    jaccard = areaConvHullIntersection / areaConvHullUnion;
    
catch %Error computing convex hull. The points may be collinear.
    jaccard=0;
    return
end

end