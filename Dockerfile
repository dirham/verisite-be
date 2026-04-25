FROM elixir:1.18-alpine

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .

EXPOSE 4000

CMD ["mix", "phx.server"]
