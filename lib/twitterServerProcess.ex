defmodule TwitterServerProcess do

    def start_link(currentNodeName) do        
        GenServer.start_link(__MODULE__,[currentNodeName],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName]) do  
        IO.puts "Twitter Server process started for "<> currentNodeName             
        state = %{"tweets" => %{}, "following" => [], "followers" => []}
        {:ok, state}
    end      
end