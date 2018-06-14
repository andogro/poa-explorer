defmodule ExplorerWeb.AddressReadContractController do
  use ExplorerWeb, :controller

  alias Explorer.{Chain, Market}
  alias Explorer.ExchangeRates.Token
  alias Explorer.SmartContract.Reader

  import ExplorerWeb.AddressController, only: [transaction_count: 1]

  def index(conn, %{"address_id" => address_hash_string}) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string),
         {:ok, address} <- Chain.find_contract_address(address_hash) do
      read_only_functions = Reader.read_only_functions(address_hash_string)

      render(
        conn,
        "index.html",
        read_only_functions: read_only_functions,
        address: address,
        exchange_rate: Market.get_exchange_rate(Explorer.coin()) || Token.null(),
        transaction_count: transaction_count(address)
      )
    else
      :error ->
        not_found(conn)

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def show(conn, params) do
    # TODO: Alter response accordingly with Reader.query_contract/3 response after it is finished.
    with true <- ajax?(conn) do
      conn
      |> put_status(200)
      |> put_layout(false)
      |> render(
        "_function_response.html",
        function_response: %{
          function_name: params["function_name"],
          type: "uint256",
          value: "0"
        }
      )
    else
      _ ->
        not_found(conn)
    end
  end

  defp ajax?(conn) do
    case get_req_header(conn, "x-requested-with") do
      [value] -> value in ["XMLHttpRequest", "xmlhttprequest"]
      [] -> false
    end
  end
end
