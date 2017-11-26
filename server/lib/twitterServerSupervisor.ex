defmodule TwitterServerSupervisor do
    use Supervisor

    def start_link() do
        Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
        IO.puts("Twitter Server Supervisor Started")        
        children = [worker(TwitterServer, [])]
        IO.puts "Twitter Server Actor created"          
        supervise(children, strategy: :one_for_one)          
    end   
end