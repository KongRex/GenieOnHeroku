using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using HTTP

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
      json(message["message"])
    end
    
    Genie.AppServer.startup()
end

launchServer(parse(Int, ARGS[1]))

