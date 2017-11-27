defmodule RandomGenerator do

    def getClientId() do
        :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)        
    end

    def getPassword() do
        :crypto.strong_rand_bytes(12) |> Base.url_encode64 |> binary_part(0, 12)         
    end

    def getRandomTweet() do
        :crypto.strong_rand_bytes(40) |> Base.url_encode64 |> binary_part(0, 40)         
    end
end