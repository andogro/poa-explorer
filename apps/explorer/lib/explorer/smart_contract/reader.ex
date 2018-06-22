defmodule Explorer.SmartContract.Reader do
  @moduledoc """
  Reads Smart Contract functions from the blockchain.

  For information on smart contract's Application Binary Interface (ABI), visit the
  [wiki](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI).
  """

  alias Explorer.Chain
  alias ABI.TypeDecoder

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
  @spec query_contract(String.t(), String.t(), [term()]) :: [term()]
  def query_contract(contract_address_hash, function_name, args \\ []) do
    function_selector =
      contract_address_hash
      |> Chain.find_smart_contract()
      |> Map.get(:abi)
      |> ABI.parse_specification()
      |> get_abi_function(function_name)

    function_selector
    |> setup_call_payload(contract_address_hash, args)
    |> EthereumJSONRPC.execute_contract_functions()
    |> decode_result(function_selector)
  end

  @doc """
  Given a list of function selectors from the ABI lib, and a function name, get the selector for that function.

  This list should usually be a Smart Contract abi parsed by the ABI lib.
  """
  @spec get_abi_function([%ABI.FunctionSelector{}], String.t()) :: %ABI.FunctionSelector{}
  def get_abi_function(abi, function_name) do
    Enum.find(abi, fn selector -> selector.function == function_name end)
  end

  @doc """
  Given a function selector, a contract address hash and a (possibly empty) list of arguments, return what EthereumJSONRPC expects.
  """
  @spec setup_call_payload(%ABI.FunctionSelector{}, String.t(), [term()]) :: [{String.t(), String.t()}]
  def setup_call_payload(function_selector, contract_address_hash, args) do
    [
      {
        contract_address_hash,
        "0x" <> encode_function_call(function_selector, args)
      }
    ]
  end

  @doc """
  Given a function selector and a list of arguments, return
  their econded versions.

  This is what is expected on the Json RPC data parameter.
  """
  @spec encode_function_call(%ABI.FunctionSelector{}, [term()]) :: String.t()
  def encode_function_call(function_selector, args) do
    function_selector
    |> ABI.encode(args)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Given a result from the blockchain, and the function selector, returns the result decoded.
  """
  def decode_result({:ok, result}, function_selector) do
    result
    |> List.first()
    |> Map.get("result")
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw(List.wrap(function_selector.returns))
  end
end
