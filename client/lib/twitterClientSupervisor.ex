defmodule TwitterClientSupervisor do
    use Supervisor

    def start_link(numClients,clientIp,serverIp) do
        Supervisor.start_link(__MODULE__, [numClients,clientIp,serverIp], name: __MODULE__)
    end

    def init([numClients,clientIp,serverIp]) do
        IO.puts("Twitter Client Supervisor Started")        
        children = [worker(TwitterClientSimulator, [numClients,clientIp,serverIp], [restart: :temporary])]
        IO.puts "Twitter Clients created"          
        supervise(children, strategy: :one_for_one)          
    end   
end