using GLPK
using Gadfly

function launchServer(port)

    Genie.config.run_as_server = true
    Genie.config.server_host = "0.0.0.0"
    Genie.config.server_port = port
	@@ -18,7 +119,9 @@ function launchServer(port)
    route("/echo", method = POST) do
        message = jsonpayload()
        #(:echo => (message["message"] * " ") ^ message["repeat"]) |> json
        json(message)
    end

    Genie.AppServer.startup()
	
end
launchServer(parse(Int, ARGS[1]))
