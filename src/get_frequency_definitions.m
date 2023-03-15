function [frequency_definition] = get_frequency_definitions()
%GET_FREQUENCY_DEFINITIONS Summary of this function goes here
%   Detailed explanation goes here
frequency_definition = struct();
frequency_definition.delta = [1 4];
frequency_definition.theta = [4 8];
frequency_definition.alpha = [8 12];
frequency_definition.beta = [12 30];
frequency_definition.gamma1 = [30 50];
frequency_definition.gamma2 = [50 70];
frequency_definition.lowFreq = [1 12];
frequency_definition.hiFreq = [12 70];
frequency_definition.totalAbsPow = [1 70];
end

