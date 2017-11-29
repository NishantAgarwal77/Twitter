defmodule TwitterClientSupervisor do
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
        IO.puts("Twitter Client Supervisor Started")        
        children = [worker(TwitterClientSimulator, [])]
        IO.puts "Twitter Clients created"          
        supervise(children, strategy: :one_for_one)          
    end   
end