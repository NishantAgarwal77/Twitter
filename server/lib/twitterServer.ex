defmodule TwitterServer do

    def start_distributed(serverName) do
        IO.puts "Starting Distributed Server Node"
        unless Node.alive?() do     
        {:ok, _} = Node.start(serverName)
        end
        Node.set_cookie(:"twitter")
    end

    def start_link(serverIP) do
        currentNodeName= "twitterServer"
        fqserverName = currentNodeName <> "@" <> serverIP
        start_distributed(:"#{fqserverName}")        
        n = {:name, {:global, String.to_atom(currentNodeName)}}        
        GenServer.start_link(__MODULE__,[], [n])
    end    

    def init([]) do  
        IO.puts "Twitter Server Started"             
        state = %{"userTable" => %{}, "hashtags" => %{}, "tweets" => %{}, "userDetails" => %{}}        
        {:ok, state}
    end   

    def handle_call({:registerUser, userName, password},_from, state) do 
        {status , message } = case Map.has_key?(Kernel.get_in(state, ["userTable"]), userName) do  
            :true -> {:failed, "UserName Already Present"}
            :false ->  state = Kernel.put_in(state, ["userTable", userName], password) 
                        state = Kernel.put_in(state, ["userDetails", userName], getInitialUserMap())                                         
                    {:ok, "Registered Successfully"}                   
            end
        {:reply , {status , message } ,state}
    end

    def getInitialUserMap() do
        %{ "tweets" => [], "followers" => [], "following" => [], "mentions" => []}
    end
       
    def handle_call({:authenticateUser, userName, password}, _from, state) do       
        {status, message} = case Map.has_key?(Kernel.get_in(state, ["userTable"]), userName) do
            :true -> 
                case Kernel.get_in(state, ["userTable", userName]) == password do
                    :true -> 
                    {:ok, "Authentication Completed"}
                    :false -> {:failed, "Password Incorrect"}
                end
            :false -> {:failed, "UserName does not exist"}
        end
        {:reply , {status, message},state}
    end


    def handle_cast({:setFollowers, followedBy, followedTo}, state) do        
        #followersList = Map.get(state, "followers")        
        followersList = Kernel.get_in(state, ["userDetails", followedTo, "followers"]) 
        state = case Enum.member?(followersList, followedBy) or (followedTo == followedBy) do
            :true -> IO.puts "Member Already present"
                    state
            :false ->   state = Kernel.put_in(state, ["userDetails", followedTo, "followers"], [followedBy | followersList])
                        Kernel.put_in(state, ["userDetails", followedBy, "following"], [followedTo | Kernel.get_in(state, ["userDetails", followedBy, "following"]) ])
                        #GenServer.cast(String.to_atom("server_"<>followedBy), {:setFollowing, followedBy, followedTo})                                               
        end               
        {:noreply, state}
    end   

    def handle_cast({:postTweet, userName, tweetId, tweetMessage}, state) do          
        hashTagList = TwitterServer.parseTweetsForHashTags(tweetMessage)      
        mentionsList = TwitterServer.parseTweetsForMentions(tweetMessage)               
        IO.inspect mentionsList
        # add the hashtags if present in the hashtag table
        state = case length(hashTagList) > 0 do        
            :true -> 
            hashMap = Map.get(state, "hashtags")
            Enum.reduce(hashTagList, state,fn(x,state)->
            case Map.has_key?(hashMap, x) do
                    :true ->  state = Kernel.put_in(state, ["hashtags", x], [tweetId | Kernel.get_in(state, ["hashtags", x])])
                    :false -> state = Kernel.put_in(state, ["hashtags", x], [tweetId])
                end                   
            end)         
            :false -> state
        end

        # add the mentions if present in the userdetails table
        state = case length(mentionsList) > 0 do        
            :true -> 
            Enum.reduce(mentionsList, state,fn(x,state)->
                state = Kernel.put_in(state, ["userDetails", x,"mentions"], [tweetId | Kernel.get_in(state, ["userDetails", x,"mentions"])])        
            end)         
            :false -> state
        end

        #Adding to Tweet Table
        state = Kernel.put_in(state, ["tweets", tweetId], tweetMessage)

        #Adding the tweet to the corresponding user who posted it
        state = Kernel.put_in(state, ["userDetails", userName, "tweets"], [tweetId | Kernel.get_in(state, ["userDetails", userName, "tweets"])])   

        IO.inspect state
        {:noreply , state}
    end

    def parseTweetsForHashTags(tweetMessage) do
        Regex.scan(~r/#([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([hashtag, _]) -> hashtag end)
    end

    def parseTweetsForMentions(tweetMessage) do
        Regex.scan(~r/@([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([_, mentions]) -> mentions end)
    end

    def isUserRegistered(userName) do
        GenServer.call(String.to_atom("twitterServer"), {:isUserRegistered, userName})               
    end

    def handle_call({:isUserRegistered, userName}, _from, state) do  
        #IO.puts userName
        result = Map.has_key?(Kernel.get_in(state, ["userTable"]), userName)
        {:reply, result, state}
    end
end