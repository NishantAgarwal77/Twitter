defmodule TwitterClient do

    def start_link(clientId) do  
        IO.puts clientId      
        currentNodeName= "client_"<>clientId
        GenServer.start_link(__MODULE__,[clientId],name: String.to_atom(currentNodeName))
    end  

    def init([clientId]) do  
        IO.puts "Twitter Client created: "<> clientId
        state = %{"serverProcess" => ""}
        {:ok, state}
    end

    def register_client(username,password) do
        {status, message} = GenServer.call(String.to_atom("twitterServer"),{:registerUser, username, password})  
        case status do
            :ok -> IO.puts "Registration Successful"
                client = "client_"<>username
                GenServer.cast(String.to_atom(client),{:saveServerProcess, message})
            :failed -> IO.inspect message
        end
    end

    def login_client(username,password) do  
        #IO.puts username<>" "<>password
        {status, message} = GenServer.call(String.to_atom("twitterServer"),{:authenticateUser, username, password})  
        case status do
            :ok -> IO.puts "Login Successful"
                client = "client_"<>username
                GenServer.cast(String.to_atom(client),{:saveServerProcess, message})
            :failed -> IO.inspect message
        end
    end

    def handle_cast({:saveServerProcess, serverProcess}, state) do             
        state = Map.put(state, "serverProcess", serverProcess)
        IO.inspect state
        {:noreply, state}
    end

    def setFollower(followedBy, followedTo) do
        client = "client_"<>followedTo
        GenServer.cast(String.to_atom(client), {:saveFollowers, followedBy, followedTo})               
    end

    def handle_cast({:saveFollowers, followedBy, followedTo}, state) do
        serverProcess = Map.get(state, "serverProcess")
        GenServer.cast(String.to_atom(serverProcess), {:setFollowers, followedBy, followedTo})               
        {:noreply, state}
    end
end