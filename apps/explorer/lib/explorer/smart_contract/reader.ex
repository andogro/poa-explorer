defmodule Explorer.SmartContract.Reader do
  @moduledoc """
  Reads Smart Contract functions from the blockchain.

  For information on smart contract's Application Binary Interface (ABI), visit the
  [wiki](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI).
  """

  alias Explorer.Chain.Hash

  @typedoc """
  Data type expected for the output of a smart contract function.
  """
  @type result_type :: :integer | :string | :address

  @typedoc """
  Data type of the output of calling a smart contract function.
  """
  @type decoded_result :: :integer | String.t()

  defguardp is_result_type(result_type) when result_type in ~w(address integer string)a

  @doc """
  Queries a contract function on the blockchain and returns the call result.

  ## Examples

     Explorer.SmartContract.Reader.query_contract(
       "0x62eb5ed811d02e774a53066646e2281ce337a3d9",
       "multiply(uint256)",
       [10],
       :integer
     )
     # => {:ok, 1024}
  """
  @spec query_contract(String.t(), String.t(), [term()], result_type()) :: {:ok, decoded_result()} | {:error, :invalid_setup | any()}
  def query_contract(address_hash, function_name, args \\ [], result_type) when is_result_type(result_type) do
    data = setup_call_data(function_name, args)

    address_hash
    |> EthereumJSONRPC.execute_contract_function(data)
    |> decode_result(result_type)
  end

  defp setup_call_data(function_name, args) do
    function_hash = Hash.binary_to_keccak(function_name)
    encoded_arguments = encode_arguments(args)

    "0x" <> function_hash <> encoded_arguments
  end

  defp encode_arguments([]), do: ""

  defp encode_arguments(args) do
    args
    |> Enum.map(&encode_argument/1)
    |> Enum.join()
  end

  defp encode_argument(int) when is_integer(int) do
    int
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(64, "0")
  end

  defp encode_argument(str) when is_binary(str) do
    str
    |> Base.encode16(case: :lower)
    |> String.pad_leading(64, "0")
  end

  defp decode_result({:ok, "0x"}, _) do
    {:error, :invalid_setup}
  end

  defp decode_result({:ok, "0x" <> _ = address}, :address), do
    {:ok, address}
  end

  defp decode_result({:ok, "0x" <> result}, type) do
    binary_data = Base.decode16!(result, case: :mixed)
    decode(binary_data, type)
  end

  @bits_per_32_bytes 32 * 8

  @doc false
  def decode(binary_data, :integer) do
    <<integer :: integer-size(@bits_per_32_bytes)>> = binary_data

    {:ok, integer}
  end

  @doc false
  def decode(binary_data, :string) do
    # String results should always start at byte index 32
    <<32 :: integer-size(@bits_per_32_bytes), remaining_data :: binary>> = binary_data

    # Next 32 bytes contains the number of bytes in the string data
    <<string_length_in_bytes :: integer-size(@bits_per_32_bytes), string_data :: binary>> = remaining_data

    # Grab the strings bytes from the remaining data
    <<string :: bytes-size(string_length_in_bytes), _rest :: binary>> = string_data

    {:ok, string}
  end
end
