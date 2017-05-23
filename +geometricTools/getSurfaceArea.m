function [area,areas] = getSurfaceArea(vertices,faces)
x1= vertices(faces(:,1),1);
y1= vertices(faces(:,1),2);
z1= vertices(faces(:,1),3);
x2= vertices(faces(:,2),1);
y2= vertices(faces(:,2),2);
z2= vertices(faces(:,2),3);
x3= vertices(faces(:,3),1);
y3= vertices(faces(:,3),2);
z3= vertices(faces(:,3),3);
area = sqrt(((y2-y1).*(z3-z1)-(y3-y1).*(z2-z1)).^2+((z2-z1).*(x3-x1)-(z3-z1).*(x2-x1)).^2+...
    ((x2-x1).*(y3-y1)-(x3-x1).*(y2-y1)).^2)/2;
areas = area;
area = sum(area);
end
