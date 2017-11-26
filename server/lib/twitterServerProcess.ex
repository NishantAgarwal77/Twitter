defmodule TwitterServerProcess do

    def start_link(currentNodeName) do        
        GenServer.start_link(__MODULE__,[currentNodeName],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName]) do  
        IO.puts "Twitter Server process started for "<> currentNodeName             
        state = %{"tweets" => %{}, "following" => [], "followers" => [], "currentNode" => currentNodeName}
        {:ok, state}
    end 

    def handle_cast({:setFollowers, followedBy, followedTo}, state) do        
        followersList = Map.get(state, "followers") 
        case Enum.member?(followersList, followedBy) do
            :true -> IO.puts "Member Already present"
            :false ->   state = Map.put(state, "followers", [followedBy | followersList])
                        GenServer.cast(String.to_atom("server_"<>followedBy), {:setFollowing, followedBy, followedTo})                        
                        IO.inspect state
        end       
        {:noreply, state}
    end   

    def handle_cast({:setFollowing, _followedBy, followedTo}, state) do           
        state = Map.put(state, "following", [followedTo | Map.get(state, "following")])
        IO.inspect state
        {:noreply, state}
    end   
end