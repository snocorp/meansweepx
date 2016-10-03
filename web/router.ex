defmodule Meansweepx.Router do
  use Meansweepx.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Meansweepx do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", Meansweepx do
    pipe_through :api

    resources "/fields", FieldController, only: [:show, :create]
    get "/fields/flag/:field_id/:x/:y", FieldController, :flag
    get "/fields/sweep/:field_id/:x/:y", FieldController, :sweep
  end
end
