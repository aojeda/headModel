classdef BSBL2S < handle
    properties
        lambda
        gamma_F
        gamma
        options = BSBL2S.initOptions;
        Sx
        logE = -inf;
        history = struct('loss_F',0,'loss',0,'lambda',0,'gamma_F',0,'gamma',0,'itime',0,'itime_F',0);
        stateName = '';
        Csq = 1;
        callback = [];
        userData = [];
    end
    properties(SetAccess=private)
        H
        Ny
        Nx
    end
    properties(SetAccess=private, GetAccess=protected)
        PriorCov
        U
        s
        V
    end
    properties(SetAccess=private, Hidden)
        Hi
        HiHit
        sqrtPriorCov
        Ng
        blocks
        initGamma
        initLoss
    end
    methods
        function obj = BSBL2S(H, PriorCov,sqrtPriorCov,blocks, options)
            if nargin < 1, error('No enough input arguments.');end
            if nargin < 4
                error('Use the function hm2cc to generate the input arguments to BSBL2S.');
            end
            if nargin < 5
                options = ParametricEmpiricalBayes.initOptions();
            end
            obj.PriorCov = PriorCov;
            obj.sqrtPriorCov = sqrtPriorCov;
            obj.blocks = blocks;
            obj.options = options;
            obj.Ng = length(obj.PriorCov);
            C = obj.PriorCov{1};
            for k=2:obj.Ng, C = C + obj.PriorCov{k};end
            dc = diag(C);
            dc(dc==0) = median(dc(dc~=0));
            C = C - diag(diag(C)) + diag(dc);
            obj.Csq = chol(C);
            obj.H = H;
            [obj.Ny, obj.Nx] = size(H);
            [obj.U,obj.s,obj.V] = svd(obj.H*obj.Csq,'econ');
            obj.V = obj.Csq*obj.V;
            obj.s = diag(obj.s);
            
            obj.PriorCov = reshape(cell2mat(obj.PriorCov(:)'),[obj.Nx^2,obj.Ng]);
            for k=1:obj.Ng
                obj.sqrtPriorCov{k} = full(obj.sqrtPriorCov{k}(obj.blocks(:,k),obj.blocks(:,k)));
            end
            obj.gamma = zeros(obj.Ng,1);
            obj.history.lambda = zeros(obj.options.stage1.maxIter,1);
            obj.history.gamma_F = zeros(obj.options.stage1.maxIter,1);
            obj.history.loss_F = zeros(obj.options.stage1.maxIter,1);
            obj.initGamma = ones(obj.Ng,1);
            obj.initLoss = nan(obj.options.stage2.maxIter,1);
            % Precompute fields needed for speeding up the algorithm.
            obj.computeHi();
        end
        function set.lambda(obj, value)
            value(value<obj.options.stage1.minLambda) = obj.options.stage1.minLambda;
            obj.lambda = value;
        end
        function set.gamma_F(obj, value)
            value(value<obj.options.stage2.minGamma) = obj.options.stage2.minGamma;
            obj.gamma_F = value;
        end
        function [x,logE] = update(obj, y)
            if nargin < 3, doUpdate = true;end
            
            % Optimization of the full model
            obj.optimizeFullModel(y);
            
            % Compute empirical data covariance
            Nt = size(y,2);
            Cy = y*y'/Nt;
            
            if obj.options.stage2.update
                loss = obj.initLoss;
                [Sy, iSy] = obj.getSy();
                for k=1:obj.options.stage2.maxIter
                    log_det = BSBL2S.logDet(Sy);
                    loss(k) = trace(Cy*iSy)+log_det;
                    if obj.options.stage2.verbose
                        if k==1
                            fprintf('%i => dLoss: %.4g   Loss: %.5g   Sum Gamma: %.4g\n',k,abs(loss(k)-obj.history.loss_F(end)),loss(k),sum(obj.gamma));
                        else
                            fprintf('%i => dLoss: %.4g   Loss: %.5g   Sum Gamma: %.4g\n',k,abs(diff(fliplr(loss(k-1:k)))),loss(k),mean(obj.gamma));
                        end
                    end
                    if strcmp(obj.options.profile,'on')
                        t0 = clock;
                    end
                    obj.sbl(y);
                    if strcmp(obj.options.profile,'on')
                        obj.history.itime(k) = etime(clock, t0);
                    end
                    [Sy, iSy] = obj.getSy();
                    if k>1 && abs(diff(fliplr(loss(k-1:k))))<obj.options.stage2.maxTol ||...
                            max(obj.gamma) < obj.options.stage2.minGamma, break;end
                end
                obj.history.loss = loss(1:k);
            end
            
            % Compute the log-Evidence
            logE = obj.compute_logE(y);
           
            % Compute the state
            x = obj.T(y);
        end
        function x = T(obj,y, iSy)
            if nargin < 3
                [~, iSy] = obj.getSy();
            end
            obj.Sx = obj.getSx();
            x = obj.Sx*obj.H'*iSy*y;
        end
        function y = h(obj,x)
            y = obj.H*x;
        end
        function sbl(obj,Y)
            [~, iSy] = obj.getSy();
            Nt = size(Y,2);
            HiCell = obj.Hi;
            num = obj.gamma;
            den = num;
            for i=1:obj.Ng
                Hi_iSy = HiCell{i}'*iSy;
                num(i) = norm(Hi_iSy*Y,'fro');  
                den(i) = sqrt(abs(sum(sum((Hi_iSy)'.*HiCell{i}))));
            end
            obj.gamma = (obj.gamma/sqrt(Nt)).*num./(den+eps);
        end
        function optimizeFullModel(obj,Y)
            UtY = obj.U'*Y;
            y2 = UtY.^2;
            s2 = obj.s.^2;
            
            % LS initialization
            S = [s2 s2*0+1];
            phi = mean((S'*S)\S'*UtY.^2,2);
            obj.gamma_F = phi(1);
            obj.lambda = phi(2);
            
            obj.history.lambda(1) = obj.lambda;
            obj.history.gamma_F(1) = obj.gamma_F;
            if strcmp(obj.options.profile,'on'), t0 = clock;end
            obj.history.loss_F(1) = -2*obj.compute_logE(Y);
            if strcmp(obj.options.profile,'on'), obj.history.itime_F(1) = etime(clock, t0);end
            for k=2:obj.options.stage1.maxIter
                if strcmp(obj.options.profile,'on'), t0 = clock;end
                psi = obj.gamma_F*s2+obj.lambda;
                psi2 = psi.^2;
                
                obj.lambda = obj.lambda*sum(mean(bsxfun(@times,y2, 1./psi2),2))/(eps+sum(1./psi));
                obj.gamma_F =   obj.gamma_F*sum(mean(bsxfun(@times,y2,s2./psi2),2))/(eps+sum(s2./psi));

                obj.gamma(:) = obj.gamma_F;
                obj.history.loss_F(k) = -2*obj.compute_logE(Y);

                if obj.options.stage1.verbose && k>1
                    fprintf('%i => dLoss: %.4g   Loss: %.5g   Lambda: %.4g   Gamma: %.4g\n',k,abs(diff(fliplr(obj.history.loss_F(k-1:k)))),...
                        obj.history.loss_F(k),obj.lambda,obj.gamma_F);
                end
                if strcmp(obj.options.profile,'on'), obj.history.itime_F(k) = etime(clock, t0);end
                if ~isempty(obj.callback)
                    obj.callback(obj, Y);
                end
                
                % Check convergence and exit condition
                if abs(diff(fliplr(obj.history.loss_F(k-1:k))))<obj.options.stage1.maxTol, break;end
            end
            obj.history.loss_F = obj.history.loss_F(1:k);
        end
        function logE = compute_logE(obj,y,indices)
            if nargin < 3, indices = 1:obj.Ng;end
            if isempty(indices), indices = 1:obj.Ng;end
            n = size(y,2);
            Cy = y*y'/n;
            [Sy,iSy] = obj.getSy(indices);
            logE = (-1/2)*(trace(Cy*iSy)+obj.logDet(Sy));
        end
        function logE = compute_logE_full(obj, UtY, d)
            if nargin < 3, d = obj.gamma_F*obj.s.^2+obj.lambda;end
            logE = sum(log(d))+mean(sum(bsxfun(@times,sqrt(1./d),UtY).^2));
        end
        function delete(obj)
            obj.Hi = [];
            obj.HiHit = [];
            obj.PriorCov = [];
            obj.sqrtPriorCov = [];
        end
    end
    methods(Hidden)
        function Sx = getSx(obj)
            g = obj.gamma(:);
            Sx = obj.PriorCov*g;
            Sx = sparse(reshape(Sx,obj.Nx,obj.Nx));
        end
        function [Sy, iSy] = getSy(obj, indices)
            if nargin < 2, indices = 1:obj.Ng;end
            if isempty(indices), indices = 1:obj.Ng;end
            gHHt = sum(bsxfun(@times, obj.HiHit(:,:,indices),permute(obj.gamma(indices),[3 2 1])),3);
            if length(obj.lambda) == 1
                Se = eye(obj.Ny)*obj.lambda;
            else
                Se = diag(obj.lambda);
            end
            Sy = Se+gHHt;
            try
                iSy = invChol_mex(double(Sy));
            catch ME
                if obj.options.stage2.verbose
                    warning(ME.message)
                    if strcmp(ME.identifier,'MATLAB:invChol_mex:dpotrf:notposdef')
                        warning('Possibly the data is rank deficient!')
                    end
                end
                [Utmp,S,Vtmp] = svd(Sy);
                stmp = real(diag(S));
                invS = 1./stmp;
                invS(isinf(invS)) = 0;
                iSy = Utmp*diag(invS)*Vtmp';
            end
        end
        function computeHi(obj)
            if isempty(obj.H), return;end
            if isempty(obj.Hi) || isempty(obj.HiHit)
                obj.Hi = cell(1,obj.Ng);
                obj.HiHit = zeros([obj.Ny, obj.Ny, obj.Ng]);
            end
            if size(obj.HiHit,1) ~= obj.Ny
                obj.HiHit = zeros([obj.Ny, obj.Ny, obj.Ng]);
            end
            if ~isempty(obj.blocks)
                for k=1:obj.Ng
                    obj.Hi{k} = obj.H(:,obj.blocks(:,k))*obj.sqrtPriorCov{k};
                    obj.HiHit(:,:,k) = obj.Hi{k}*obj.Hi{k}';
                end
            else
                for k=1:obj.Ng    
                    obj.Hi{k} = obj.H*obj.sqrtPriorCov{k};
                    obj.HiHit(:,:,k) = obj.Hi{k}*obj.Hi{k}';
                end
            end
        end
    end
    methods(Static)
        function options = initOptions()
            options.stage1 = struct('maxTol',1e-3,'maxIter',200,'verbose',true,'minLambda',1e-6);
            options.stage2 = struct('maxTol',1e-3,'maxIter',200,'verbose',true,'update',true,'minGamma',1e-6,'maxGamma',1e9);
            options.profile = 'off';
        end
        function log_det = logDet(S)
            try
                log_det = log(det(S));
                if isinf(log_det)
                    e = eig(S);
                    e(e<0) = eps;
                    log_det = sum(real(log(e)));
                end
            catch
                e = eig(S);
                e(e<0) = eps;
                log_det = sum(real(log(e)));
            end
        end
        function [PriorCov,sqrtPriorCov,blocks] = hm2cc(hm,noroi)
            if nargin < 2, noroi = [];end
            Nx = size(hm.K,2);
            blocks = hm.indices4Structure(hm.atlas.label);
            if ~isempty(noroi)
                rmind = 0;
                for k=1:length(noroi)
                    rmind = rmind | ~cellfun(@isempty,strfind(hm.atlas.label,noroi{k}));
                end
                blocks(:,rmind) = false;
            end
            blocks(:,~any(blocks,1)) = [];
            Nroi = size(blocks,2);
            PriorCov = cell(1,Nroi);
            sqrtPriorCov = cell(1,Nroi);
            Zero = sparse(Nx,Nx);
            for k=1:Nroi
                W = hm.L(blocks(:,k),blocks(:,k));
                W = W*W';
                sqrtPriorCov{k} = Zero;
                sqrtPriorCov{k}(blocks(:,k),blocks(:,k)) = W;
                PriorCov{k} = sqrtPriorCov{k}*sqrtPriorCov{k}';
            end
        end
    end
end
