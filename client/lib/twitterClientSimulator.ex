defmodule TwitterClientSimulator do
    
    def start_link(numClients,clientIp,serverIp) do
        currentNodeName= "twitterClientSim"
        GenServer.start_link(__MODULE__,[currentNodeName, numClients,clientIp,serverIp],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName, numClients,clientIp,serverIp]) do 
        IO.puts "Twitter Client Simulator created: "<> currentNodeName              
        clientIds = Enum.map(1..numClients, fn(_x) -> RandomGenerator.getClientId() end)   
        IO.inspect clientIds
        Enum.each(clientIds, fn(x) -> TwitterClient.start_link(x,clientIp,serverIp) end)              
        
        userMap = Enum.reduce clientIds, %{}, fn x, acc -> Map.put(acc, x, RandomGenerator.getPassword()) end        
        Enum.each userMap, fn {userName, password} -> TwitterClient.register_client(userName, password) end 
        Enum.each userMap, fn {userName, password} -> TwitterClient.login_client(userName, password) end      
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        TwitterClient.postTweetWithHashTags(Enum.random(clientIds), ["nishant", "moulik"])
        TwitterClient.postTweetWithHashTags(Enum.random(clientIds), ["abc", "nishant", "tweet2", "tweet3"])        
        men1 = Enum.random(clientIds)
        TwitterClient.postTweetWithMentions(Enum.random(clientIds), [men1])        
        TwitterClient.postTweetWithMentions(men1, [Enum.random(clientIds)])
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForUser(Enum.random(clientIds))
        TwitterClient.getTweetsForHashTag("#nishant")          
        TwitterClient.getTweetsForMentions(men1)
        TwitterClient.getTweetsForMentions(Enum.random(clientIds))
        TwitterClient.getTweetsForMentions(Enum.random(clientIds))
        TwitterClient.getTweetsForMentions(Enum.random(clientIds))
        men2 = Enum.random(clientIds)
        TwitterClient.retweetForUser(men2)
        TwitterClient.getTweetsForUser(men2)
        state = %{"clients" => userMap}        
        {:ok, state}
    end    
end
