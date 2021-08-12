using Genie, Genie.Router, Genie.Requests
using Genie.Renderer.Json
using JuMP 
using GLPK

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
      (:echo => (message["message"] * " ") ^ message["repeat"]) |> json
    end
    
    Genie.AppServer.startup()
end

launchServer(parse(Int, ARGS[1]))
