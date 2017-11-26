defmodule TwitterClientSimulator do
    
    def start_link(noClients) do
        currentNodeName= "twitterClientSim"
        GenServer.start_link(__MODULE__,[currentNodeName, noClients],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName, noClients]) do 
        IO.puts "Twitter Client Simulator created: "<> currentNodeName              
        clientIds = Enum.map(1..noClients, fn(_x) -> RandomGenerator.getClientId() end)        
        Enum.each(clientIds, fn(x) -> TwitterClient.start_link(x) end)              
        userMap = Enum.reduce clientIds, %{}, fn x, acc -> Map.put(acc, x, RandomGenerator.getPassword()) end        
        Enum.each userMap, fn {userName, password} -> TwitterClient.register_client(userName, password) end 
        Enum.each userMap, fn {userName, password} -> TwitterClient.login_client(userName, password) end        
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        state = %{"clients" => userMap}
        {:ok, state}
    end    
end
