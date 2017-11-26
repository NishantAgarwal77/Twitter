defmodule RandomGenerator do

    def getClientId() do
        clientid = :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)     
        clientid
    end

    def getPassword() do
        :crypto.strong_rand_bytes(12) |> Base.url_encode64 |> binary_part(0, 12)         
    end
end