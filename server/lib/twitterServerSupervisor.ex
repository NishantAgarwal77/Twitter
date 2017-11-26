defmodule TwitterServerSupervisor do
    use Supervisor

    def start_link(serverIP) do
        Supervisor.start_link(__MODULE__, [serverIP], name: __MODULE__)
    end

    def init([serverIP]) do
        IO.puts("Twitter Server Supervisor Started")        
        children = [worker(TwitterServer, [serverIP])]
        IO.puts "Twitter Server Actor created"          
        supervise(children, strategy: :one_for_one)          
    end   
end