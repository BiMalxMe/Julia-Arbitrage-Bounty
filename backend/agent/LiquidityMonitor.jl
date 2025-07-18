module LiquidityMonitor

using JuliaOS, HTTP, JSON

function fetch_pool_data()
    url = "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd"
    response = HTTP.get(url)
    data = JSON.parse(String(response.body))
    println("💧 Current SOL Price: \$$(data["solana"]["usd"])")
    return data
end

function run()
    println("📡 LiquidityMonitor Agent Running...")
    while true
        fetch_pool_data()
        sleep(30)  # Wait 30 seconds between checks
    end
end

end # module
