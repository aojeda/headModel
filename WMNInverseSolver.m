classdef WMNInverseSolver < handle
    % Estimate EEG distributed sourses using a weighted minimum norm
    % solver.
    properties
        Nx
        Ny
    end
    properties(Hidden)
        Ut
        V
        s2
        srcind
        X0
        hm
    end
    methods
        function obj = WMNInverseSolver(hm, W)
            if nargin < 2, W = hm.L;end
            [obj.Ny, obj.Nx] = size(hm.K);
            % Remove from the source space the indiced that are not in the
            % gray matter, i.e. corpus callosum
            obj.srcind = hm.atlas.colorTable~=0;
            % Compute the average reference operator
            R = eye(obj.Ny)-ones(obj.Ny)/obj.Ny;
            % Standardize lead field to compensate for depth bias
            H = obj.stdLeadField(R*hm.K,5);
            [U,S,V] = svd(H(:,obj.srcind)/W(obj.srcind,obj.srcind),'econ');
            obj.Ut = U';
            obj.V = W(obj.srcind,obj.srcind)\V;
            s = diag(S);
            obj.s2 = s.^2;
            obj.hm = hm;
        end
        function X = update(obj, Y, numLambdas, plotGCV)
            if nargin < 3, numLambdas = 100;end
            if nargin < 4, plotGCV = false;end
            X = zeros(obj.Nx, size(Y,2));
            X(obj.srcind,:) = ridgeSVD(Y, obj.Ut, obj.s2, obj.V, numLambdas, plotGCV);
        end
    end
    methods(Static)
        function K = stdLeadField(K, alpha)
             if nargin < 3
                indz = [];
             else
                % Remove outliers due to numerical errors
                indz = std(K)< prctile(std(K),alpha);
            end
            K = bsxfun(@rdivide,K,eps+sqrt(sum(K.^2,1)));
            K(:,indz) = 0;
        end
    end
end