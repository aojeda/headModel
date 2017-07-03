# Add your own inverse methods
New inverse methods can be easily added by implementing an interface between your method and the `headModel` object. We explain how this process works next.

1- Implement your interface function using the following prototype:
```matlab
function solver = solverName(hm)
%
% Your code goes here
%
end
```
where `solver` is an object that implements the method `update` with the following prototype:
```matlab
function x = update(obj, y)
%
% Implement the inverse mapping x = f(y) here.
%
end
```
and contains the following properties: `Nx` (number of sources) and `Ny` (number of sensors).
2- Save the function `solverName.m` in `headModel/plugins/`.

*Note that the `plugins/` folder should contain **only** interface functions, class definitions must be somewhere else as third-party classes may not be specific to EEG source estimation and could be part of large toolboxes.


### Example 1: Minimum Norm inverse solver
In this example, we write a plugin to compute the minimum norm (MN) source estimates using as prior source covariance the identity matrix. It is trivial to write this solver as it can be obtained from `loreta`, which is already implemented. Save the following function in `headModel/plugins/`:
```matlab
function solver = minimumNorm(hm)
    W = speye(size(hm.cortex.vertices,1));
    solver = loreta(hm, W);
end
```
Note that we do not need to implement the method `update` as it is already in the class `loreta`.

### Example 2: LASSO inverse solver
In this example, we implement source estimation subject to sparsity constraints using L1 regularization (see the [LASSO](https://statweb.stanford.edu/~tibs/lasso/lasso.pdf) paper). Fortunately, there is a `lasso` solver implemented in MATLAB since R2011b, which we can use. 

First, we write the following interface function:
```matlab
function solver = lassoSolver(hm)
    solver = inverseSolverLasso(hm);
end
```
and save it in `headModel/plugins/`.

Second, we implement the class `inverseSolverLasso` and save it in a folder that is on MATLAB's search path:
```matlab
classdef inverseSolverLasso < handle
    % Estimate EEG distributed sources using the LASSO method.
    properties
        Nx
        Ny
        H
    end
    methods
        function obj = inverseSolverLasso(hm)
            [obj.Ny, obj.Nx] = size(hm.K);
            
            % Save the lead field matrix in H
            obj.H = hm.K;
        end
        function x = update(obj, y)
            Nk = sie(y,2);
            x = zeros(obj.Nx,Nk);
            
            % For each data sample
            for k=1:Nk
                % Call MATLAB lasso solver
                [xtmp,stats] = lasso(obj.H, y(:,k));
                
                % Select model with lowest mean square error
                [~, opt_model] = stats.MSE;
                x(:,k) = xtmp(:,opt_model);
            end
        end
    end
end
```

MATLAB's [lassso](https://www.mathworks.com/help/stats/lasso.html) function has many options that can be incorporated into the wrapper class `inverseSolverLasso`, which could be of interest for EEG source estimation. 

*Note that the example above is for demonstration purpose only, as MATLAB's `lasso` could be too slow for most applications. A faster `solver` can be implemented using ADMM (see code [here](http://www.simonlucey.com/lasso-using-admm/)).

Feel free to reach out to me if you have any question.

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)