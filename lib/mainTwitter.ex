defmodule MainTwitter do
    
    def main(args \\ []) do
        {_,inputParsedVal,_} = OptionParser.parse(args, switches: [ help: :boolean ],aliases: [ h: :help ])

        numClients = String.to_integer Enum.at(inputParsedVal, 0)

        pidServer = spawn(MainTwitter, :startTwitterServer , [self()])
        pidClientSimulator = spawn(MainTwitter, :startTwitterClientSimulator , [self()])
        send pidServer, {:startServer}
        send pidClientSimulator, {:startClientSimulator, numClients}
        receive do
            { :serverTerminate } ->
            IO.puts "Twitter is getting shutdown"
            { :clientTerminate } ->
            IO.puts "Twitter is getting shutdown"
        end                             
    end

    def startTwitterServer(sender) do        
        receive do
            {:startServer} -> TwitterServerSupervisor.start_link()                       
                startTwitterServer(sender)
            {:terminateServer} -> send sender, {:serverTerminate}                                     
        end    
    end

    def startTwitterClientSimulator(sender) do        
        receive do
            {:startClientSimulator,  noClients} -> TwitterClientSupervisor.start_link(noClients)                       
                startTwitterClientSimulator(sender)
            {:terminateClient} -> send sender, {:clientTerminate}
        end    
    end
end