defmodule TwitterClientSimulator do
    
    @simulator "twitterClientSim"
    def start_link() do
        currentNodeName= "twitterClientSim"
        GenServer.start_link(__MODULE__,[currentNodeName],name: String.to_atom(currentNodeName))
    end  

    def init([currentNodeName]) do         
        IO.puts "Twitter Client Simulator created: "<> currentNodeName                             
        state = %{"clients" => %{}, "hashtags" => ["#twitter"], "inActiveClients" => []}        
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
        TwitterClient.start_link(newClientId,clientIp,serverIp, Enum.random(1..10))
        password = RandomGenerator.getPassword()
        state = Map.put(state, newClientId, password)
        GenServer.cast(:global.whereis_name(String.to_atom(newClientId)),{:register, newClientId, password})
        TwitterClient.login_client(newClientId, password)
        {:noreply, state}
    end    

    def handle_cast({:logout, clientToBeLoggedOut}, state) do          
        #clients = Map.keys(Map.get(state, "clients")) 
        #clientToBeLoggedOut = Enum.random(clients)
        IO.puts "closing process " <> clientToBeLoggedOut
        inactiveClients = Map.get(state, "inActiveClients")
        state = case Enum.member?(inactiveClients, clientToBeLoggedOut) do
            :true -> state 
            :false ->#TwitterClient.stop(clientToBeLoggedOut) 
                    Map.put(state, "inActiveClients", [clientToBeLoggedOut | inactiveClients])                   
        end                
        #IO.inspect state
        {:noreply, state}
    end     

    def handle_cast({:login}, state) do   
        clients = Map.get(state, "inActiveClients")
        state = case length(clients) > 0 do 
            :true ->clientToBeLoggedIn = Enum.random(clients) 
                    IO.puts clientToBeLoggedIn<>" logged back into the system"                   
                    TwitterClient.login_client(clientToBeLoggedIn, Kernel.get_in(state, ["clients", clientToBeLoggedIn]))
                    Map.put(state, "inActiveClients", List.delete(clients, clientToBeLoggedIn))
            :false -> IO.puts "All users are logged on, no inactive client found"
                    state
        end
        
        {:noreply, state}
    end     

    def startSimulatingTweet(currentNodeName, clientIP, serverIP) do       
        #taskNo = Enum.random(1..2)       
        :global.sync()
        case 2 do
            #1 -> GenServer.cast(String.to_atom(currentNodeName),{:registerNewClient, clientIP, serverIP})                  
            1 -> GenServer.cast(String.to_atom(currentNodeName),{:logout, currentNodeName})                  
            2 -> GenServer.cast(String.to_atom(currentNodeName),{:login})                  
            _ -> IO.puts "Invalid Input"
        end
        
        :timer.sleep(5000) 
        startSimulatingTweet(currentNodeName, clientIP, serverIP)
    end

    def getRandomClient(list,clients) do
        random_client=Enum.random(clients)
        if(Enum.member?(list, random_client)) do
            random_client=getRandomClient(list,clients)
        end
        random_client
    end

    def getZipfDist(numberofClients) do
        s=1
        c=getConstantValue(numberofClients,s)
        Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s)) end)
    end

    def getConstantValue(numberofClients,s) do
        #IO.puts numberofClients
        k=Enum.reduce(1..numberofClients,0,fn(x,acc)->:math.pow(1/x,s)+acc end)    
        1 / k
    end

    def generateAndRegisterClients(numClients, clientIp, serverIp, weighted_followers) do
        receive do
        {sender} ->
            clientIds = Enum.map(1..numClients, fn(_x) -> RandomGenerator.getClientId() end)         
            #weighted_followers = getZipfDist(numClients)
            for counter <- 0..numClients-1 do
                weight= round(Enum.at(weighted_followers, counter))
                clientId=Enum.at(clientIds, counter)
                TwitterClient.start_link(clientId,clientIp,serverIp,weight)            
            end           
            userMap = Enum.reduce clientIds, %{}, fn x, acc -> Map.put(acc, x, RandomGenerator.getPassword()) end
            Enum.each userMap, fn {userName, password} -> GenServer.cast(:global.whereis_name(String.to_atom(userName)),{:register, userName, password})  end                             
            Enum.each userMap, fn {userName, password} -> TwitterClient.login_client(userName, password) end
            send sender, { :ok , userMap }  
            generateAndRegisterClients(numClients, clientIp, serverIp, weighted_followers)           
        end
    end

    def handle_cast({:createClients, numClients, clientIp, serverIp, weights}, state) do         
        pid = spawn fn -> generateAndRegisterClients(numClients, clientIp, serverIp, weights) end
        send pid, {self()} 
        receive do
            { :ok , userMap} ->
            state = Map.put(state, "clients", Map.merge(Map.get(state, "clients"), userMap))
        end

        {:noreply, state}
    end   

    def startSimulation(numClients,clientIp,serverIp) do 

        splitNumClients = case rem(numClients, 8) == 0 do
            :true ->  numClients / 8
            :false -> round(numClients / 7)
        end       
                
        weighted_followers = Enum.chunk_every(getZipfDist(numClients), splitNumClients)
        IO.inspect weighted_followers
        for x <- 0..6 do
            GenServer.cast(String.to_atom("twitterClientSim"),{:createClients, splitNumClients, clientIp, serverIp, Enum.at(weighted_followers, x)})
        end
        num =  numClients - (7 * splitNumClients)
        GenServer.cast(String.to_atom("twitterClientSim"),{:createClients, num, clientIp, serverIp, Enum.at(weighted_followers, 7)})
        spawn fn -> startSimulatingTweet(@simulator, clientIp, serverIp) end  
    end 
end
