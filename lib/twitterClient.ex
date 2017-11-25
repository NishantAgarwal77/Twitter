defmodule TwitterClient do

    def start_link(clientId) do
        currentNodeName= "node_"<>Integer.to_string(clientId)
        GenServer.start_link(__MODULE__,[clientId],name: String.to_atom(currentNodeName))
    end  

    def init([clientId]) do  
        IO.puts "Twitter Client created: "<> Integer.to_string(clientId)
        state = %{}
        {:ok, state}
    end

    def register_client(username,password) do
        server_state = GenServer.call(String.to_atom("twitterServer"),{:get_state, "twitterServer"})
        user_state = Map.get(server_state,username)
        if(Map.get(user_state,username) == nil) do
            GenServer.call(String.to_atom("twitterServer"),{:register_user, {username,password}}) 
            IO.puts "Successfully registered user"
        else
            IO.puts "Username already exists"
        end 
    end

    def login_client(username,password) do
        server_state = GenServer.call(String.to_atom("twitterServer"),{:get_state, "twitterServer"})
        user_state = Map.get(server_state,"users")
        if(user_state == nil) do
            IO.puts "User Not found .. Registering user"
            register_client(username,password)
        else
            if(Map.get(user_state,"password")==password) do
                #GenServer.start_link(__MODULE__, {user_name,pass_word,{}}, name: String.to_atom(user_name))
                GenServer.call(String.to_atom("twitterServer"),{:set_active_user,username})
                IO.puts "Login Successful"
            else
                IO.puts "Sorry Wrong Password !!"
            end
        end
    end
end