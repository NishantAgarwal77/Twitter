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
        {:reply , {status, message, Kernel.get_in(state, ["userDetails", userName])},state}
    end

    def handle_call({:setFollowers, followedBy, followedTo},_from, state) do        
        #followersList = Map.get(state, "followers")            
        followersList = Kernel.get_in(state, ["userDetails", followedTo, "followers"]) 
        state = case Enum.member?(followersList, followedBy) or (followedTo == followedBy) do
            :true -> IO.puts "Member Already present. Please choose another user to be followed"
                    state
            :false ->   state = Kernel.put_in(state, ["userDetails", followedTo, "followers"], [followedBy | followersList])
                        Kernel.put_in(state, ["userDetails", followedBy, "following"], [followedTo | Kernel.get_in(state, ["userDetails", followedBy, "following"]) ])
                        #GenServer.cast(String.to_atom("server_"<>followedBy), {:setFollowing, followedBy, followedTo})                                               
        end               
        {:reply, Kernel.get_in(state, ["userDetails", followedBy]), state}
    end   

    def handle_call({:postTweet, userName, tweetId, tweetMessage},_from,  state) do          
        hashTagList = TwitterServer.parseTweetsForHashTags(tweetMessage)      
        mentionsList = TwitterServer.parseTweetsForMentions(tweetMessage)               
        #IO.inspect mentionsList
        # add the hashtags if present in the hashtag table
        state = case length(hashTagList) > 0 do        
            :true -> 
            hashMap = Map.get(state, "hashtags")
            Enum.reduce(hashTagList, state,fn(x,state)->
                case Map.has_key?(hashMap, x) do
                    :true ->  Kernel.put_in(state, ["hashtags", x], [tweetId | Kernel.get_in(state, ["hashtags", x])])
                    :false -> Kernel.put_in(state, ["hashtags", x], [tweetId])
                end                   
            end)         
            :false -> state
        end

        # add the mentions if present in the userdetails table        
        state = case length(mentionsList) > 0 do        
            :true ->             
            state = Enum.reduce(mentionsList, state,fn(x, acc)->
                l = Kernel.get_in(state, ["userDetails", x,"mentions"])                                
                acc = Kernel.put_in(state, ["userDetails", x,"mentions"], [tweetId | l])        
            end) 
            state        
            :false -> state
        end

        #Adding to Tweet Table
        state = Kernel.put_in(state, ["tweets", tweetId], [tweetMessage, userName, 0])

        #Adding the tweet to the corresponding user who posted it
        state = Kernel.put_in(state, ["userDetails", userName, "tweets"], [tweetId | Kernel.get_in(state, ["userDetails", userName, "tweets"])])           

        #IO.inspect state 
        {:reply,Kernel.get_in(state, ["userDetails", userName]), state}
    end

    def parseTweetsForHashTags(tweetMessage) do
        Regex.scan(~r/#([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([hashtag, _]) -> hashtag end) |> Enum.filter(fn(x) -> x !="" end)
    end

    def parseTweetsForMentions(tweetMessage) do
        Regex.scan(~r/@([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([_, mentions]) -> mentions end) |> Enum.filter(fn(x) -> x !="" end)
    end

    def handle_call({:getPostsForUser, userName}, _from, state) do
        #IO.inspect state  
        userMap = Kernel.get_in(state, ["userDetails", userName])
        tweetIds = Map.get(userMap, "tweets")++Map.get(userMap, "mentions")

        tweetIdList = Enum.reduce(Map.get(userMap, "following"), tweetIds, fn(x, acc) ->
            Kernel.get_in(state, ["userDetails", x, "tweets"])++acc
        end)
        #IO.inspect tweetIdList
        result = Enum.reduce(tweetIdList, [], fn(x, acc)-> 
            [msg, user, status] = Kernel.get_in(state, ["tweets", x])
            #[acc | [msg <>" postedBy " <> user]]
            msg = case status == 0 do
                :true -> msg <>" postedBy " <> user
                :false -> msg <>" retweetedBy " <> user
            end
            [msg | acc]
        end)        
        {:reply, result, state}
    end

    def handle_call({:getPostsForHashTag, hashtag}, _from, state) do          
        tweetIdList = Kernel.get_in(state, ["hashtags", hashtag])               
        result = case tweetIdList != nil and length(tweetIdList) > 0 do
            :true ->
            Enum.reduce(tweetIdList, [], fn(x, acc)-> 
            [msg, user, status] = Kernel.get_in(state, ["tweets", x])
            msg = case status == 0 do
                :true -> msg <>" postedBy " <> user
                :false -> msg <>" retweetedBy " <> user
            end
            [msg | acc]
        end)        
            :false -> []
        end       
        #IO.inspect state  
        {:reply, result, state}
    end    

    def handle_call({:getPostsForMention, mention}, _from, state) do          
        tweetIdList = Kernel.get_in(state, ["userDetails", mention, "mentions"]) 
        result = case tweetIdList != nil and length(tweetIdList) > 0 do
            :true -> Enum.reduce(tweetIdList, [], fn(x, acc)-> 
                    [msg, user, status] = Kernel.get_in(state, ["tweets", x])
                    msg = case status == 0 do
                        :true -> msg <>" postedBy " <> user
                        :false -> msg <>" retweetedBy " <> user
                    end
                    [msg | acc]
        end)        
            :false -> []
        end            
        
        {:reply, result, state}
    end  

    def handle_cast({:retweet, userName, followId}, state) do          
        reTweetId = RandomGenerator.getClientId(8) <> "_" <> userName        
        state = case length(Kernel.get_in(state, ["userDetails", followId, "tweets"])) > 0 do
            :true -> tweetIdToBeRetweeted = Enum.random(Kernel.get_in(state, ["userDetails", followId, "tweets"]))                   
                    [msg, _user, _status] = Kernel.get_in(state, ["tweets", tweetIdToBeRetweeted])
                    state = Kernel.put_in(state, ["tweets", reTweetId], [msg, userName, 1])
                    Kernel.put_in(state, ["userDetails", userName,"tweets"], [reTweetId | Kernel.get_in(state, ["userDetails", userName,"tweets"])])         
            :false -> state
        end                                      
        #IO.inspect state
        {:noreply, state}
    end       
end