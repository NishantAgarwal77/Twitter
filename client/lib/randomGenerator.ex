defmodule RandomGenerator do

    @randomStringLength 8

    def getPassword() do
        :crypto.strong_rand_bytes(12) |> Base.url_encode64 |> binary_part(0, 12)         
    end

    def getRandomTweet() do
        :crypto.strong_rand_bytes(40) |> Base.url_encode64 |> binary_part(0, 40)         
    end  

    def getRandomHashTag() do
        num = Enum.random(1..3)
        Enum.reduce(1..num, [],fn(_x,acc)->
            [acc | RandomGenerator.getClientId(6)]
        end)    
    end

    def getClientId(length \\@randomStringLength) do
        letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"       
        digitList = String.downcase(letters) |> String.split("", trim: true)
        getRandomString(digitList, length)
    end

    defp getRandomString(digitList, length) do
        1..length 
        |> Enum.reduce([], fn(_, acc) -> [Enum.random(digitList) | acc] end)
        |> Enum.join("")
    end
end