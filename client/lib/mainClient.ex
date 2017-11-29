defmodule MainClient do

    def main(args \\ []) do
        {_,inputParsedVal,_} = OptionParser.parse(args, switches: [ help: :boolean ],aliases: [ h: :help ])

        numClients = String.to_integer Enum.at(inputParsedVal, 0)
        clientIp =  Enum.at(inputParsedVal, 1)
        serverIp =  Enum.at(inputParsedVal, 2) 
        TwitterClientSupervisor.start_link(numClients,clientIp,serverIp)  
        :timer.sleep(20000)                               
    end

end
