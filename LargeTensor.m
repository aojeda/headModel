classdef LargeTensor < handle
    properties(SetAccess=protected)
        mmf
    end
    properties(Hidden,SetAccess=protected)
        file
    end
    methods
        function self = LargeTensor(dims, filename)
            if nargin < 1, error('Tensor size is the first argument! Example:  a = LargeTensor([2,3,4]);');end
            if nargin < 2, 
                filename = tempname;
                create_file = true;
            else
                create_file = false;
            end
            self.file = filename;
            if create_file
                if strfind(lower(computer),'glnx')>0
                    rt = system(['fallocate -l ' num2str(prod(dims)*8) ' ' self.file]);
                elseif strfind(lower(computer),'pcwin')>0
                    rt = system(['fsutil file createnew ' self.file ' length ' num2str(prod(dims)*8)]);
                end
                if rt ~=0, error('Cannot create a memory mapped file. Try increasing disk space on /tmp.');end
            end
            self.mmf = memmapfile(self.file,'Format',{'double' dims 'x'},'Writable',true);
        end
        function delete(self)
            if exist(self.file,'file')
                delete(self.file);
                [p,n] = fileparts(self.file);
                hdr = fullfile(p,[n '.hdr']);
                bin = fullfile(p,[n '.bin']);
                if exist(hdr,'file'), delete(hdr);end
                if exist(bin,'file'), delete(bin);end
            end
        end
        function slice = subsref(self,s)
            if length(s)==1
                slice = subsref(self.mmf.Data.x,s);
            else
                slice = self.mmf.Data.x(s(end).subs{1},s(end).subs{2});
            end
        end
        function slice = subsasgn(self,s,value) 
            ind = s(end).subs{2};
            for k=1:length(ind)
                self.mmf.Data.x(:,ind(k)) = value(:,k);
            end
            slice = self;
            % slice = subsasgn(self.mmf.Data.x,s,value);
        end
        function saveToFile(self,filename)
            [p,n] = fileparts(filename);
            dims = size(self);
            hdr = fullfile(p,[n '.hdr']);
            fid = fopen(hdr,'w');
            fprintf(fid,'[%s]',num2str(dims));
            fclose(fid);
            bin = fullfile(p,[n '.bin']);
            copyfile(self.mmf.Filename,bin);
        end
        %%
        function dims = size(self,d)
            if nargin <2, d = [];end
            dims = self.mmf.Format{2};
            if ~isempty(d), dims = dims(d);end
        end
        function self = reshape(self,dims)
            self.mmf.Format{2} = dims;
        end
        function self = minus(self,value)
            self.mmf.Data.x = self.mmf.Data.x - value.mmf.Data.x;
        end
        function self = plus(self,value)
            self.mmf.Data.x = self.mmf.Data.x + value.mmf.Data.x;
        end
        function self = times(self,value)
            self.mmf.Data.x = self.mmf.Data.x.*value.mmf.Data.x;
        end
        function self = power(self,value)
            self.mmf.Data.x = self.mmf.Data.x.^value;
        end
        function self = sqrt(self)
            self.mmf.Data.x = sqrt(self.mmf.Data.x);
        end
        function self = mtimes(self,value)
            % Handle the multiplication by a matrix on the left
            if isa(value,'LargeTensor') && ~isa(self,'LargeTensor')
                tmp = self;
                self = value;
                value = tmp;
                clear tmp;
                self = value*self.mmf.Data.x;
                return
            end
            if ~isa(value,class(self))
                self.mmf.Data.x = self.mmf.Data.x*value;
            else
                self.mmf.Data.x = self.mmf.Data.x.*value.mmf.Data.x;
            end
        end
        function self = mrdivide(self,value)
            if ~isa(value,class(self))
                self.mmf.Data.x = self.mmf.Data.x/value;
            else
                self.mmf.Data.x = self.mmf.Data.x/value.mmf.Data.x;
            end
        end
    end
    methods(Static)
        function self = loadFromFile(filename)
            [p,n] = fileparts(filename);
            hdr = fullfile(p,[n '.hdr']);
            bin = fullfile(p,[n '.bin']);
            fid = fopen(hdr,'r');
            dims = eval(fgets(fid));
            self = LargeTensor(dims,bin);
        end
    end
end
