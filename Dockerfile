FROM julia:1.10

RUN julia -e 'using Pkg; Pkg.add("JuliaOS"); Pkg.instantiate()'

WORKDIR /app
COPY . /app
CMD ["julia", "main.jl"]
