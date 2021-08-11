using Genie, Genie.Router, Genie.Requests
import Genie.Renderer.Json: json
using JuMP #,uIpopt # Gurobi, CSV, DataFrames, 
using GLPK
using Gadfly


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
        (:echo => (message["consumption"]) |> json
        #PB = message["consumption"]
      
        #json(Dict("PB" => PB))
    
    end
    
    Genie.AppServer.startup()
end

launchServer(parse(Int, ARGS[1]))

