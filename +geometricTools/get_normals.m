function normals = get_normals(vertices,faces)
if exist('triangulation','class')
    T = triangulation(faces,vertices);
    normals = T.vertexNormal();
else
    h = figure('visible','off');
    h2 = patch('vertices',vertices,'faces',fliplr(faces));
    normals = get(h2,'vertexnormals');close(h);
    if isempty(normals)
        normals = vertices;
        normals = normals./(sqrt(sum(normals.^2,2))*[1 1 1]);
    end
end
end