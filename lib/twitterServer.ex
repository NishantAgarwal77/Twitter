defmodule TwitterServer do

    def start_link() do
        currentNodeName= "twitterServer"
        GenServer.start_link(__MODULE__,[],name: String.to_atom(currentNodeName))
    end  

    def init([]) do  
        IO.puts "Twitter Server Actor Started"
        state = %{}
        {:ok, state}
    end
end