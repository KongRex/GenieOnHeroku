using Genie, Genie.Router, Genie.Requests
import Genie.Renderer.Json: json
using JuMP #,uIpopt # Gurobi, CSV, DataFrames, 
using GLPK
using Gadfly


function run_optimizer(Yearly_consumption, Annual_production)    
	#Prices
	P_RP = [0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.17,0.17,0.29,0.29,0.29,0.29,0.17,0.17,0.29,0.29,0.29,0.29,0.29,0.29,0.17,0.17]
	P_FI = [0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08]*-1

	#**********************************************************************************************

	#Day and evening consumption - hourly consumption
	C = [0.02,0.02,0.02,0.02,0.02,0.02,0.05,0.06,0.06,0.03,0.03,0.03,0.03,0.03,0.03,0.03,0.04,0.08,0.10,0.10,0.08,0.05,0.03,0.02] * Yearly_consumption/365

	#**********************************************************************************************
	#Solar yields versus yearly average
	SY_Spring = 0.98
	SY_Summer = 1.75
	SY_Fall = 0.98
	SY_Winter = 0.29


	#Battery stats
	netyield = 0.9747 #Battery
	battery_capacity = 8.82
	max_effect_battery = 5


	#**********************************************************************************************

	#Production per hour
	P_Spring = [0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.02,0.05,0.08,0.11,0.12,0.13,0.13,0.12,0.11,0.08,0.05,0.02,0.00,0.00,0.00,0.00,0.00]*Annual_production/365*SY_Spring
	P_Summer = [0.00,0.00,0.00,0.00,0.00,0.00,0.01,0.01,0.03,0.05,0.07,0.09,0.10,0.11,0.12,0.12,0.10,0.08,0.06,0.03,0.01,0.01,0.00,0.00]*Annual_production/365*SY_Summer
	P_Fall = [0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.02,0.05,0.08,0.11,0.12,0.13,0.13,0.12,0.11,0.08,0.05,0.02,0.00,0.00,0.00,0.00,0.00]*Annual_production/365*SY_Fall
	P_Winter = [0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.03,0.07,0.11,0.13,0.17,0.17,0.13,0.11,0.07,0.03,0.00,0.00,0.00,0.00,0.00,0.00] *Annual_production/365*SY_Winter

	total_old_bill = [sum(P_RP[i]*C[i] for i=1:24)*365/4,sum(P_RP[i]*C[i] for i=1:24)*365/4,sum(P_RP[i]*C[i] for i=1:24)*365/4,sum(P_RP[i]*C[i] for i=1:24)*365/4]
	total_new_bill = []

	for season_idx=1:4
		#**********************************************************************************************
		#Production
		P = [P_Spring, P_Summer, P_Fall, P_Winter][season_idx]
		
		#Start modelling
		model = Model(GLPK.Optimizer) #Slightly faster

		#Feed-in variable
		@variable(model, 0 <= FI[1:24])
		#Battery model
		@variable(model, 0 <= B[1:24] <= battery_capacity)
		#Grid electricity
		@variable(model, 0 <= GE[1:24])

		#Battery consumption
		@variable(model, 0 <= BC[1:24] <= max_effect_battery)
		#Battery storing energy

		@variable(model, 0 <= BS[1:24] <= max_effect_battery)

		#Set Objective Function
		@objective(model, Min, sum(GE[i] * P_RP[i] + FI[i] * P_FI[i] for i=1:24))

		#Ensure supply & demand of energy matches
		@constraint(model, C[1] + FI[1] + BS[1]  == P[1] + GE[1]) #Meet consumption period 1
		for i=2:24 
			@constraint(model, C[i] + FI[i] + BS[i] == P[i] + GE[i] + BC[i] * netyield)
		end
		#Battery load
		@constraint(model, B[1] == 0 + BS[1] * netyield - 0)
		for i=2:24 
			@constraint(model, B[i]  == B[i-1] + BS[i] * netyield - BC[i])
		end

		#print(model)
		optimize!(model)
		append!(total_new_bill, JuMP.objective_value(model) * 365/4)
		
	end

	#Payback time
	savings = sum(total_old_bill) - sum(total_new_bill)
	PB = 8490/savings
	return PB
end 

function launchServer(port)
    Genie.config.run_as_server = true
    Genie.config.server_host = "0.0.0.0"
    Genie.config.server_port = port

    println("port set to $(port)")

    route("/") do
        "Hi there!"
    end

    route("/echo", method = POST) do
        message = jsonpayload()
        #(:echo => (message["message"] * " ") ^ message["repeat"]) |> json
        PB = run_optimizer(message["consumption"],message["production"]) 
      
        json(Dict("PB" => PB))
    
    end
    
    Genie.AppServer.startup()
end

launchServer(parse(Int, ARGS[1]))

