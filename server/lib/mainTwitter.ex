defmodule MainTwitter do
    
    def main(args \\ []) do
        {_,inputParsedVal,_} = OptionParser.parse(args, switches: [ help: :boolean ],aliases: [ h: :help ])

        serverIP = Enum.at(inputParsedVal, 0)

        pidServer = spawn(MainTwitter, :startTwitterServer , [self(), serverIP])
        #pidClientSimulator = spawn(MainTwitter, :startTwitterClientSimulator , [self()])
        send pidServer, {:startServer}
        #send pidClientSimulator, {:startClientSimulator, numClients}
        receive do
            { :serverTerminate } ->
            IO.puts "Twitter is getting shutdown"
            { :clientTerminate } ->
            IO.puts "Twitter is getting shutdown"
        end                                   
    end

    def startTwitterServer(sender, serverIP) do        
        receive do
            {:startServer} -> TwitterServerSupervisor.start_link(serverIP)                       
                #startTwitterServer(sender)                
                IO.gets("")
                send sender, {:serverTerminate} 
            {:terminateServer} -> send sender, {:serverTerminate}                                     
        end    
    end    
end