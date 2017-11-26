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
                :timer.sleep(50000)
                send sender, {:serverTerminate} 
            {:terminateServer} -> send sender, {:serverTerminate}                                     
        end    
    end

    def startTwitterClientSimulator(sender) do        
        receive do
            {:startClientSimulator,  noClients} -> TwitterClientSupervisor.start_link(noClients)   
                :timer.sleep(10000)                    
                startTwitterClientSimulator(sender)
            {:terminateClient} -> send sender, {:clientTerminate}
        end    
    end
end