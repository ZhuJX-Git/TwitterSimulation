defmodule Proj5Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :proj5

  socket "/socket", Proj5Web.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :proj5, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_proj5_key",
    signing_salt: "I6M/jVKo"

  plug Proj5Web.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    :ets.new(:socketMap, [:set, :public, :named_table])
    :ets.new(:cnt, [:set, :public, :named_table])
    :ets.new(:tweetIDMap, [:set, :public, :named_table])
    :ets.new(:userMap, [:set, :public, :named_table])
    :ets.new(:userLoginMap, [:set, :public, :named_table])
    :ets.new(:userTweetMap, [:set, :public, :named_table])
    :ets.new(:userSubscribeMap, [:set, :public, :named_table])
    :ets.new(:tagMap, [:set, :public, :named_table])
    :ets.new(:mentionMap, [:set, :public, :named_table])
    :ets.insert(:cnt, {:count, 0})


    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
