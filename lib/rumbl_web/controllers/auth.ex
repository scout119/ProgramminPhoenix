defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Pbkdf2, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller

  alias RumblWeb.Router.Helpers, as: Routes

  alias Rumbl.Accounts

  # def init(opts) do
  #   Keyword.fetch!(opts, :repo)
  # end

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user(user_id)
    assign(conn, :current_user, user)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def login_by_email_and_pass(conn, email, given_pass) do
    case Accounts.authenticate_by_email_and_pass(email, given_pass) do
      { :ok, user } -> {:ok, login(conn, user)}
      { :error, :unauthorized } -> { :error, :unauthorized, conn }
      { :error, :not_found } -> { :error, :not_found, conn }
    end
  end

  def login_by_username_and_pass( conn, username, given_pass) do
    #repo = Keyword.fetch!(opts, :repo)
    user = Accounts.get_user_by( %{ username: username } )

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end  
end