defmodule TwitterClient do

    def start_link(clientId) do
        currentNodeName= "node_"<>Integer.to_string(clientId)
        GenServer.start_link(__MODULE__,[clientId],name: String.to_atom(currentNodeName))
    end  

    def init([clientId]) do  
        IO.puts "Twitter Client created: "<> Integer.to_string(clientId)
        state = %{}
        {:ok, state}
    end
end