% This is the overarching simulation grid class. 
% This class inherits from the grid settings class, and copies settings
% upon instantiation. 
classdef gridClass < gridSettingsClass
    properties
        tick = 1; 
        riskFactor; 
        riskFactor_0; 
        riskFactorAmplitudes; 
        gridHealth; 

        % Subclasses: 
        fires fireClass; 
    end
    methods
        % Class constructor. 
        function obj = gridClass(gridSettings)
            % Restrict input type for coding convenience. 
            arguments
                gridSettings gridSettingsClass; 
            end

            % Copy sim and grid settings. 
            gridSettingsProperties = properties(gridSettings); 
            for i = 1: length(gridSettingsProperties)
                obj.(gridSettingsProperties{i}) = ...
                    gridSettings.(gridSettingsProperties{i}); 
            end

            % Initialize grid health. 
            obj.gridHealth = ones(obj.gridSize); 

            % Generate initial risk factor matrix via seeded gaussian RNG. 
            % Risk factor ranges from minimum of 0 to maximum of 1. 
            obj.riskFactor_0 = zeros(obj.gridSize(1), obj.gridSize(2)); 
            rng(117); 
            obj.riskFactor_0 = min(max( ...
                normrnd(-0.5, 0.4, obj.gridSize(1), obj.gridSize(2)), ...
                0), 1); 
            rng("default"); 

            % Generate risk factor oscillation amplitudes. 
            obj.riskFactorAmplitudes = zeros( ...
                obj.gridSize(1), obj.gridSize(2)); 
            rng(54); 
            obj.riskFactorAmplitudes = min(max( ...
                normrnd(0.2, 0.1, obj.gridSize(1), obj.gridSize(2)), ...
                0), 1); 
            rng("default"); 

            % Instantiate fire simulations class. 
            obj.fires = fireClass(obj); 
        end

        % Update risk factor method, simulating periodic seasonal changes. 
        % Risk factors constrained to minimum of 0 and maximum of 1. 
        function obj  = updateRiskFactor(obj)
            obj.riskFactor = obj.riskFactor_0 + ...
                obj.riskFactorAmplitudes*sin(obj.tick * ...
                2*pi/obj.ticksPerYear); 
            obj.riskFactor = min(max(obj.riskFactor, 0), 1); 
        end

        % Restore grid block health method. 
        function obj = restoreGridHealth(obj)
            % Locate grid blocks without fire. 
            noFireGrids = ~obj.fires.intensity; 

            % Calculate amount of health to restore. 
            % Considers grid blocks close to full health. 
            restoreAmount = ...
                min(1 - obj.gridHealth, obj.restoreGridHealthRate); 
            restoreAmount(~noFireGrids) = 0; 
            
            % Restore grid blocks without fire. 
            obj.gridHealth = obj.gridHealth + restoreAmount; 

            % Calculate restoration costs. 
            costs = sum( ...
                restoreAmount/obj.restoreGridHealthRate * ...
                obj.restoreGridHealthCost, "all"); 
        end

        % Update tick method. 
        function obj = updateTick(obj)
            % obj.tick = mod(obj.tick+1, obj.ticksPerYear); 
            obj.tick = obj.tick + 1; 
        end

        % Simulation grid update method. 
        function obj = updateGrid(obj)
            obj.updateRiskFactor(); 
            obj.restoreGridHealth(); 
            obj.fires.generateFires(); 
            obj.fires.updateIntensity(); 

            % Update tick at the end of the grid update method. 
            obj.updateTick(); 
        end
    end
end



