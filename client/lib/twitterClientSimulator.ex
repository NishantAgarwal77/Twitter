defmodule TwitterClientSimulator do
    
    def start_link(numClients,clientIp,serverIp) do
        currentNodeName= "twitterClientSim"
        GenServer.start_link(__MODULE__,[currentNodeName, numClients,clientIp,serverIp],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName, numClients,clientIp,serverIp]) do         
        IO.puts "Twitter Client Simulator created: "<> currentNodeName              
        clientIds = Enum.map(1..numClients, fn(_x) -> RandomGenerator.getClientId() end)         
        Enum.each(clientIds, fn(x) -> TwitterClient.start_link(x,clientIp,serverIp) end)             
        userMap = Enum.reduce clientIds, %{}, fn x, acc -> Map.put(acc, x, RandomGenerator.getPassword()) end        
        Enum.each userMap, fn {userName, password} -> GenServer.cast(:global.whereis_name(String.to_atom(userName)),{:register, userName, password})  end                             
        Enum.each userMap, fn {userName, password} -> TwitterClient.login_client(userName, password) end      
        spawn fn -> startSimulatingTweet(currentNodeName, clientIp, serverIp) end                   

        state = %{"clients" => userMap, "hashtags" => ["#twitter"], "inActiveClients" => []}        
        {:ok, state}
    end 

    def handle_call({:getClients}, _from, state) do          
        clients = Map.keys(Map.get(state, "clients"))
        {:reply, clients, state}
    end 

    def handle_call({:getsaveHashTags}, _from, state) do   
        hashTagsGenerated = TwitterClientSimulator.getRandomHashTag()       
        currentHashTags = Map.get(state, "hashtags")       
        cumulative = hashTagsGenerated ++ currentHashTags
        state = Map.put(state, "hashtags", cumulative)
        {:reply, hashTagsGenerated, state}
    end    

    def getRandomHashTag() do
        num = Enum.random(1..3)
        Enum.reduce(1..num, [],fn(_x,acc)->
            newHashTag = "#"<>RandomGenerator.getClientId(6)
            [newHashTag| acc]
        end)    
    end    

    def handle_call({:getHashTag}, _from, state) do          
        currentHashTags = Map.get(state, "hashtags")              
        {:reply, currentHashTags, state}
    end

    def handle_cast({:registerNewClient, clientIp,serverIp}, state) do           
        newClientId = RandomGenerator.getClientId()      
        TwitterClient.start_link(newClientId,clientIp,serverIp)
        password = RandomGenerator.getPassword()
        state = Map.put(state, newClientId, password)
        GenServer.cast(:global.whereis_name(String.to_atom(newClientId)),{:register, newClientId, password})
        TwitterClient.login_client(newClientId, password)
        {:noreply, state}
    end    

    def handle_cast({:logout, clientIp,serverIp}, state) do  
        IO.puts "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$" 
        clients = Map.keys(Map.get(state, "clients")) 
        clientToBeLoggedOut = Enum.random(clients)
        state = Map.put(state, "inActiveClients", [clientToBeLoggedOut | Map.get(state, "inActiveClients")])
        #TwitterClient.stop(clientToBeLoggedOut)
        IO.inspect state
        {:noreply, state}
    end     

    def handle_cast({:login}, state) do  
        IO.puts "************************************************"  
        clients = Map.get(state, "inActiveClients")
        state = case length(clients) > 0 do 
            :true ->clientToBeLoggedIn = Enum.random(clients)                    
                    TwitterClient.login_client(clientToBeLoggedIn, Kernel.get_in(state, ["clients", clientToBeLoggedIn]))
                    Map.put(state, "inActiveClients", List.delete(clients, clientToBeLoggedIn))
            :false -> IO.puts "No inactive client present"
                    state
        end
        
        {:noreply, state}
    end     

    def startSimulatingTweet(currentNodeName, clientIP, serverIP) do        
        taskNo = Enum.random(2..3)
        :global.sync()
        case taskNo do
            1 -> GenServer.cast(String.to_atom(currentNodeName),{:registerNewClient, clientIP, serverIP})                  
            2 -> GenServer.cast(String.to_atom(currentNodeName),{:logout, clientIP, serverIP})                  
            3 -> GenServer.cast(String.to_atom(currentNodeName),{:login})                  
            _ -> IO.puts "Invalid Input"
        end
        
        :timer.sleep(2000) 
        startSimulatingTweet(currentNodeName, clientIP, serverIP)
    end
end
