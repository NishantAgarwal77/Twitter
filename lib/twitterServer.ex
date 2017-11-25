defmodule TwitterServer do

    def start_link() do
        currentNodeName= "twitterServer"
        GenServer.start_link(__MODULE__,[],name: String.to_atom(currentNodeName))
    end  

    def init([]) do  
        IO.puts "Twitter Server Actor Started"
        state = %{}
        {:ok, state}
    end

    def handle_call({:register ,user_contact},_from,state) do 
        username = elem(user_contact,0)
        password = elem(user_contact,1)
        user_state=Map.get(state,username)
        registered_user = %{"username" => username, "password" => password, "tweets" => [], "following"=>[],"status" => "active"}}
        state = Map.put(state,username,registered_user)
        {:reply,state,state}
   end

   def handle_call({:set_active_user ,username},_from,state) do  
        user_state=Map.get(state,username)
        user_state=Map.put(user_state,"status","active")
        state=Map.put(state,username,user_state)
        {:reply,state,state}
   end 

   def handle_call({:get_state ,new_message},_from,state) do  
       {:reply,state,state}
   end
end