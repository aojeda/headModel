function [label,x,y,z,theta,phi] = readBiosemiLocations(xlsfile)
[d,label] = xlsread(xlsfile);
theta = d(:,1)*pi/180;
phi = d(:,2)*pi/180;
r = 1;
x = -r*sin(theta).*sin(phi);
y =  r*sin(theta).*cos(phi);
z =  r*cos(theta);
for k=1:length(label), loc = find(label{k}==' ');label{k}(loc:end) = [];end