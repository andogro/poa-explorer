defmodule Explorer.SmartContract.Reader do
  @moduledoc """
  Reads Smart Contract functions from the blockchain.

  For information on smart contract's Application Binary Interface (ABI), visit the
  [wiki](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI).
  """

  alias Explorer.Chain
  alias ABI.TypeDecoder

  @typedoc """
  Data type of the output of calling a smart contract function.
  """
  @type decoded_result :: :integer | String.t()

  @doc """
  Queries a contract function on the blockchain and returns the call result.

  ## Examples

  Note that for this example to work the database must be up to date with the
  information available in the blockchain.

  Explorer.SmartContract.Reader.query_contract(
    "0x7e50612682b8ee2a8bb94774d50d6c2955726526",
    "sum",
    [20, 22]
  )
  # => {:ok, 42}
  """
  @spec query_contract(String.t(), String.t(), [term()]) :: {:ok, decoded_result()} | {:error, :invalid_setup | any()}
  def query_contract(contract_address_hash, function_name, args \\ []) do
    function_selector =
      contract_address_hash
      |> Chain.find_smart_contract()
      |> Map.get(:abi)
      |> ABI.parse_specification()
      |> get_contract_function(function_name)

    function_selector
    |> setup_call_payload(contract_address_hash, args)
    |> EthereumJSONRPC.execute_contract_functions()
    |> decode_result(function_selector)
  end

  defp get_contract_function(abi, function_name) do
    Enum.find(abi, fn selector -> selector.function == function_name end)
  end

  defp setup_call_payload(function_selector, contract_address_hash, args) do
    [
      {
        contract_address_hash,
        "0x" <> encode_function_call(function_selector, args)
      }
    ]
  end

  defp encode_function_call(function_selector, args) do
    function_selector
    |> ABI.encode(args)
    |> Base.encode16(case: :lower)
  end

  defp decode_result({:ok, result}, function_selector) do
    result
    |> List.first()
    |> Map.get("result")
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw(List.wrap(function_selector.returns))
  end
end
