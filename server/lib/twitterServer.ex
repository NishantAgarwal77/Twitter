defmodule TwitterServer do

    def start_link() do
        currentNodeName= "twitterServer"
        GenServer.start_link(__MODULE__,[],name: String.to_atom(currentNodeName))
    end  

    def init([]) do  
        IO.puts "Twitter Server Started"             
        state = %{"userTable" => %{}, "serverProcess" => [], "activeUser" => []}
        IO.inspect state 
        {:ok, state}
    end   

    def handle_call({:set_active_user ,username},_from,state) do  
            user_state=Map.get(state,username)
            user_state=Map.put(user_state,"status","active")
            state=Map.put(state,username,user_state)
            {:reply,state,state}
    end 

    def authenticateClient(userName, password) do
       GenServer.call(String.to_atom("twitterServer"), {:authenticateUser, userName, password})       
    end

    def registerClient(userName, password) do
         GenServer.call(String.to_atom("twitterServer"), {:registerUser, userName, password})
    end

    def handle_call({:registerUser, userName, password},_from, state) do 
        {status , message } = case Map.has_key?(Kernel.get_in(state, ["userTable"]), userName) do  
            :true -> {:failed, "UserName Already Present"}
            :false ->  state = Kernel.put_in(state, ["userTable", userName], password)  
                    serverNode = "server_"<>userName      
                    TwitterServerProcess.start_link(serverNode)
                    {:ok, serverNode}
            end
        {:reply , {status , message } ,state}
    end
       
    def handle_call({:authenticateUser, userName, password}, _from, state) do       
        {status, message} = case Map.has_key?(Kernel.get_in(state, ["userTable"]), userName) do
            :true -> 
                case Kernel.get_in(state, ["userTable", userName]) == password do
                    :true -> serverProcess = "server_"<>userName
                    {:ok, serverProcess}
                    :false -> {:failed, "Password Incorrect"}
                end
            :false -> {:failed, "UserName does not exist"}
        end
        {:reply , {status, message},state}
    end

    def isUserRegistered(userName) do
        GenServer.call(String.to_atom("twitterServer"), {:isUserRegistered, userName})               
    end

    def handle_call({:isUserRegistered, userName}, _from, state) do  
        #IO.puts userName
        result = Map.has_key?(Kernel.get_in(state, ["userTable"]), userName)
        {:reply, result, state}
    end























    def getNextTweetId() do
        nextTweetId = GenServer.call(String.to_atom("twitterServer"), {:getNextTweetId})
        nextTweetId = String.to_integer(nextTweetId) + 1
        GenServer.cast(String.to_atom("twitterServer"), {:saveNextTweetId, nextTweetId})
        IO.puts nextTweetId
        nextTweetId
    end

    def getUserMap(password) do
        %{
            "tweets" => [],
            "password" => password,
            "following" => [],
            "mentions" => []
        }
    end

    def handle_call({:getNextTweetId},_from,state) do       
        tweetId =  Map.get(state,"currentTweetId") 
        {:reply ,tweetId ,state}
    end

    def handle_cast({:saveNextTweetId, nextTweetId},state) do       
        state = Map.put(state,"currentTweetId", nextTweetId)
        {:noreply , state}
    end

    def postOwnTweet(userName, tweetMessage) do
         GenServer.cast(String.to_atom("twitterServer"), {:postOwnTweet, userName, tweetMessage})
    end

     def handle_cast({:postOwnTweet, userName, tweetMessage},state) do               
        nextTweetId = TwitterServer.getNextTweetId()
        put_in(state, ["tweetsTable"], Kernel.get_in(state, ["tweetsTable"]) |> Map.put(nextTweetId, tweetMessage))
        hashTagList = TwitterServer.parseTweetsForHashTags(tweetMessage)
        hashTagTable = Kernel.get_in(state, ["hashtagsTable"]) 
        #Enum.each(has, fun)
        #case Map.has_key?(hashTagTable, key)
        {:noreply , state}
    end


    def parseTweetsForHashTags(tweetMessage) do
        Regex.scan(~r/#([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([hashtag, _]) -> hashtag end)
    end

     def parseTweetsForMentions(tweetMessage) do
        Regex.scan(~r/@([a-zA-Z0-9]*)/, tweetMessage) |> Enum.map(fn([hashtag, _]) -> hashtag end)
    end
end