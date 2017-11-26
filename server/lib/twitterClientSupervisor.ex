defmodule TwitterClientSupervisor do
    use Supervisor

    def start_link(noClients) do
        Supervisor.start_link(__MODULE__, [noClients], name: __MODULE__)
    end

    def init([noClients]) do
        IO.puts("Twitter Client Supervisor Started")        
        children = [worker(TwitterClientSimulator, [noClients])]
        IO.puts "Twitter Clients created"          
        supervise(children, strategy: :one_for_one)          
    end   
end