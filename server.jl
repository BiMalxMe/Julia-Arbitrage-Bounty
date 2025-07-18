using HTTP
using Pkg
Pkg.activate(@__DIR__)

function hello(req)
    return HTTP.Response(200, "Hello, Julia backend is running!")
end

HTTP.serve(hello, "127.0.0.1", 8080)
