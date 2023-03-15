function [M,P] = modify_cmc_2017(M,P,model,factor)
%MODIFY_CMC_2017 Change synaptic gain in cmc_2017 model
% Modifies M.cmcj and P.G.
% Model 1-5 from Adams et al. (2022)
% Model 'all-excitatory' modulates all excitatory synapses
switch(model)
    case 1
        M.cmcj = [3 5 6 8 9 11 12 13];
        P.G = ones(1,8) * factor;
    case 2
        M.cmcj = [6 11];
        P.G = ones(1,2) * factor;
    case 3
        M.cmcj = 4;
        P.G = factor;
    case 4
        M.cmcj = 4;
        P.G = -factor;
    case 5
        M.cmcj = 7;
        P.G = -factor;
    case 'all-excitatory'
        M.cmcj = [5 6 8 11 13];
        P.G = ones(1,5) * factor;
    otherwise
        error('Model %d does not exists. Choose 1,2,3,4,5.', i_model) 
end
end

