defmodule TwitterClient do
    @server_name "twitterServer"
    @lineSeperator "------------------------------------------------------"
    def start_distributed(clientName) do
        IO.puts("Starting Distributed Node")
        unless Node.alive?() do     
            {:ok, _} = Node.start(clientName)
        end
        Node.set_cookie(:"twitter")
    end

    def start_link(clientId,clientIp,serverIp) do
        fqclientName = clientId <> "@" <> clientIp
        start_distributed(:"#{fqclientName}")
        IO.puts "Connecting to server"
        server = @server_name <> "@" <> serverIp                       
        case Node.connect(:"#{server}") do
            true -> :ok               
                IO.puts "Server connected"
            reason ->
             IO.puts "Could not connect to server, reason: #{reason}"
                System.halt(0)
        end  
        n = {:name, {:global, String.to_atom(clientId)}}        
        GenServer.start_link(__MODULE__, [clientId], [n])
        #IO.puts clientId      
        #currentNodeName= "client_"<>clientId
        #GenServer.start_link(__MODULE__,[clientId],name: String.to_atom(currentNodeName))
    end  

    def init([clientId]) do  
        Process.flag(:trap_exit, true)
        IO.puts "Twitter Client created: "<> clientId
        state = %{"nodeName" => clientId, "userDetails" => %{}}
        {:ok, state}
    end

    def handle_cast({:register, username, password}, state) do 
        #IO.puts username<>password
        :global.sync()
        {status, message} = GenServer.call(:global.whereis_name(:"twitterServer"),{:registerUser, username, password})  
        case status do
            :ok ->IO.puts "Registration Successful for "<>username
                  #login_client(username,password)               
            :failed -> IO.inspect message
        end

        state = Map.put(state, "password", password)
        {:noreply, state}
    end      

    def handle_cast({:login, username, password}, state) do 
        :global.sync()
        {status, message, userDetails} = GenServer.call(:global.whereis_name(:"twitterServer"),{:authenticateUser, username, password})  
        case status do
            :ok -> IO.puts "Login Successful"                        
                   getTweetsForUser(username)
                   spawn fn -> startTwitting(username) end                   
            :failed -> IO.inspect message
        end

        state = Map.put(state, "userDetails", userDetails) 
        {:noreply, state}
    end        

    def login_client(username,password) do  
        :global.sync()
        GenServer.cast(:global.whereis_name(String.to_atom(username)),{:login, username, password})          
    end

    def handle_cast({:setFollower, followedBy}, state) do 
        followedTo = Enum.random(GenServer.call(String.to_atom("twitterClientSim"),{:getClients}))
        :global.sync()        
        userDetails = GenServer.call(:global.whereis_name(:"twitterServer"), {:setFollowers, followedBy, followedTo})               
        state = Map.put(state, "userDetails", userDetails) 
        #IO.inspect state     
        {:noreply, state}
    end       

    def handle_cast({:postTweet, clientId}, state) do 
        :global.sync() 
        tweetContent = RandomGenerator.getRandomTweet()
        tweetId = RandomGenerator.getClientId(8) <> "_" <> clientId        
        userDetails = GenServer.call(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
        state = Map.put(state, "userDetails", userDetails) 
        {:noreply, state}
    end

    def handle_cast({:postTweetWithHashTags, clientId}, state) do 
        :global.sync()  
        hashtags = GenServer.call(String.to_atom("twitterClientSim"),{:getsaveHashTags})          
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(hashtags,"",fn(x,acc)->acc<>x<>" " end))       
        tweetId = RandomGenerator.getClientId(8) <> "_" <> clientId
        userDetails = GenServer.call(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
        state = Map.put(state, "userDetails", userDetails) 
        {:noreply, state}
    end     

    def handle_cast({:postTweetWithMentions, clientId}, state) do 
        :global.sync()      
        mentions = Enum.take_random(GenServer.call(String.to_atom("twitterClientSim"),{:getClients}), Enum.random(1..3))
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(mentions,"",fn(x,acc)->acc<>"@"<>x<>" " end))
        #IO.puts tweetContent
        tweetId = RandomGenerator.getClientId(8) <> "_" <> clientId
        userDetails = GenServer.call(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
        state = Map.put(state, "userDetails", userDetails) 
        {:noreply, state}
    end      

    def handle_cast({:postTweetWithMentionsAndTags, clientId}, state) do 
       :global.sync() 
        hashtags = GenServer.call(String.to_atom("twitterClientSim"),{:getsaveHashTags})                     
        mentions = Enum.take_random(GenServer.call(String.to_atom("twitterClientSim"),{:getClients}), Enum.random(1..3))      
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(mentions,"",fn(x,acc)->acc<>"@"<>x<>" " end)) <> String.trim(Enum.reduce(hashtags,"",fn(x,acc)->acc<>x<>" " end))
        tweetId = RandomGenerator.getClientId(8) <> "_" <> clientId
        userDetails = GenServer.call(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
        state = Map.put(state, "userDetails", userDetails) 
        {:noreply, state}
    end                  

    def handle_cast({:getTweetsForUser, clientId}, state) do 
        :global.sync() 
        result = GenServer.call(:global.whereis_name(:"twitterServer"), {:getPostsForUser, clientId})               
        IO.puts(["Post for user "<> clientId <> "\n" <> @lineSeperator <> "\n" , Enum.join(result, "\n"), "\n" <> @lineSeperator])
        {:noreply, state}
    end   

    def getTweetsForUser(clientId) do 
        GenServer.cast(String.to_atom(clientId),{:getTweetsForUser, clientId})
    end

    def handle_cast({:getTweetsForHashTag}, state) do 
        :global.sync() 
        hashtag = Enum.random(GenServer.call(String.to_atom("twitterClientSim"),{:getHashTag}))
        result = GenServer.call(:global.whereis_name(:"twitterServer"), {:getPostsForHashTag, hashtag})               
        if length(result) > 0  do
            IO.puts(["Posts with hashtag "<> hashtag <> "\n" <> @lineSeperator <> "\n" , Enum.join(result, "\n"), "\n" <> @lineSeperator])         
        else 
            IO.puts "No tweets found with hashtag "<> hashtag
        end
        {:noreply, state}
    end   

    def handle_cast({:getTweetsForMentions}, state) do 
        :global.sync()         
        mention = Enum.random(GenServer.call(String.to_atom("twitterClientSim"),{:getClients}))
        result = GenServer.call(:global.whereis_name(:"twitterServer"), {:getPostsForMention, mention})               
        if length(result) > 0 do
            IO.puts(["Post for mention @"<> mention <> "\n" <> @lineSeperator <> "\n", Enum.join(result, "\n"), "\n" <> @lineSeperator])            
        else 
            IO.puts "No mentions found for user "<> mention
        end        
        {:noreply, state}
    end 

    def handle_cast({:retweet, clientId}, state) do 
        :global.sync() 
        case length(Kernel.get_in(state, ["userDetails", "following"])) > 0 do
            :true ->  followingId = Enum.random(Kernel.get_in(state, ["userDetails", "following"]))
                    if followingId != nil or followingId != "" do            
                        GenServer.cast(:global.whereis_name(:"twitterServer"), {:retweet, clientId, followingId})                
                    end        
            :false -> IO.puts "User "<>clientId <> " is not followed by any other user"
        end
       
        {:noreply, state}
    end

    def stop(pid) do
        GenServer.call(:global.whereis_name(String.to_atom(pid)), {:stop, pid})
    end 

    def handle_call({:stop, clientId}, _from, status) do
        {:stop, :normal, status}
    end 

    def terminate(reason, status) do
        IO.puts "Logging out"
        :ok 
    end 

    def startTwitting(clientId) do        
        taskNo = Enum.random(1..9)
        :global.sync()
        case taskNo do
            1 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:setFollower, clientId}) 
            2 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:postTweet, clientId}) 
            3 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:postTweetWithHashTags, clientId}) 
            4 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:postTweetWithMentions, clientId}) 
            5 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:postTweetWithMentionsAndTags, clientId}) 
            6 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:getTweetsForUser, clientId}) 
            7 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:getTweetsForHashTag}) 
            8 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:getTweetsForMentions}) 
            9 -> GenServer.cast(:global.whereis_name(String.to_atom(clientId)),{:retweet, clientId}) 
            _ -> IO.puts "Invalid Input"
        end
        
        :timer.sleep(1000) 
        startTwitting(clientId)
    end     
end