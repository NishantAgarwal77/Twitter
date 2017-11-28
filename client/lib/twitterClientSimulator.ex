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
        weighted_followers=getZipfDist(numClients) |> IO.inspect
        for counter <- 0..numClients-1 do
            weight= round(Enum.at(weighted_followers, counter))
            clientId=Enum.at(clientIds, counter)
            randomClients=[]
            for x <- 1..weight do
                random_client=getRandomClient(randomClients,clientIds)
                randomClients=randomClients++[random_client]
                TwitterClient.setFollower(random_client,clientId)
                TwitterClient.postTweetWithHashTags(clientId, ["nishant", "moulik"])
            end
            #IO.puts "Random clients for : " <> to_string(clientId) <> " = " <> to_string(randomClients)
        end
        
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        # TwitterClient.setFollower(Enum.random(clientIds), Enum.random(clientIds))
        #TwitterClient.postTweetWithHashTags(Enum.random(clientIds), ["nishant", "moulik"])
        #TwitterClient.postTweetWithHashTags(Enum.random(clientIds), ["abc", "nishant", "tweet2", "tweet3"])        
        men1 = Enum.random(clientIds)
        #TwitterClient.postTweetWithMentions(Enum.random(clientIds), [men1])        
        #TwitterClient.postTweetWithMentions(men1, [Enum.random(clientIds)])
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
        #TwitterClient.retweetForUser(men2)
        TwitterClient.getTweetsForUser(men2)
        state = %{"clients" => userMap}        
        {:ok, state}
    end  

    def getRandomClient(list,clients) do
        random_client=Enum.random(clients)
        if(Enum.member?(list, random_client)) do
            random_client=getRandomClient(list,clients)
        end
        random_client
    end

    def getZipfDist(numberofClients) do
        distList=[]
        s=1
        c=getConstantValue(numberofClients,s)
        distList=Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s)) end)
        distList
    end

    def getConstantValue(numberofClients,s) do
        k=Enum.reduce(1..numberofClients,0,fn(x,acc)->:math.pow(1/x,s)+acc end )
        k=1/k
        k
    end

end
