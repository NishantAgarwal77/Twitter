defmodule TwitterClient do
    @server_name "twitterServer"

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
        IO.puts "Twitter Client created: "<> clientId
        state = %{"nodeName" => clientId}
        {:ok, state}
    end

    def register_client(username,password) do
        :global.sync()
        {status, message} = GenServer.call(:global.whereis_name(:"twitterServer"),{:registerUser, username, password})  
        case status do
            :ok -> IO.puts "Registration Successful"
                #client = username
                #GenServer.cast(String.to_atom(client),{:saveServerProcess, message})
            :failed -> IO.inspect message
        end
    end

    def login_client(username,password) do  
        #IO.puts username<>" "<>password
        :global.sync()
        {status, message} = GenServer.call(:global.whereis_name(:"twitterServer"),{:authenticateUser, username, password})  
        case status do
            :ok -> IO.puts "Login Successful"
                #client = username
                #GenServer.cast(String.to_atom(username),{:saveServerProcess, message})
            :failed -> IO.inspect message
        end
    end
   
    def setFollower(followedBy, followedTo) do        
        :global.sync()        
        GenServer.cast(:global.whereis_name(:"twitterServer"), {:setFollowers, followedBy, followedTo})               
    end   

    def postTweet(clientId) do
        tweetContent = RandomGenerator.getRandomTweet()
        GenServer.cast(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetContent})               
    end

    def postTweetWithHashTags(clientId, hashtags) do        
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(hashtags,"",fn(x,acc)->acc<>"#"<>x<>" " end))       
        tweetId = Integer.to_string(:os.system_time(:millisecond))<> "_" <> clientId
        GenServer.cast(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
    end

    def postTweetWithMentions(clientId, mentions) do        
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(mentions,"",fn(x,acc)->acc<>"@"<>x<>" " end))
        IO.puts tweetContent
        tweetId = Integer.to_string(:os.system_time(:millisecond))<> "_" <> clientId
        GenServer.cast(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
    end

    def postTweetWithMentionsAndTags(clientId, mentions, hashtags) do        
        tweetContent = RandomGenerator.getRandomTweet()<> String.trim(Enum.reduce(mentions,"",fn(x,acc)->acc<>"@"<>x<>" " end)) <> String.trim(Enum.reduce(hashtags,"",fn(x,acc)->acc<>"#"<>x<>" " end))
        tweetId = Integer.to_string(:os.system_time(:millisecond))<> "_" <> clientId
        GenServer.cast(:global.whereis_name(:"twitterServer"), {:postTweet, clientId, tweetId, tweetContent})               
    end

end