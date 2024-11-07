classdef Taxi
    properties
        id int64
        x double
        y double
        operation_remained double = 0
        utility double = 0
        incentived_u double = 0
        incentive double
    end
end