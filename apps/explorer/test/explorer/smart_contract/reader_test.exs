defmodule Explorer.SmartContract.ReaderTest do
  use ExUnit.Case, async: true
  use Explorer.DataCase

  doctest Explorer.SmartContract.Reader

  alias Explorer.SmartContract.Reader
  alias Plug.Conn
  alias Explorer.Chain.Hash

  @ethereum_jsonrpc_original Application.get_env(:ethereum_jsonrpc, :url)

  describe "query_contract/3" do
    setup do
      bypass = Bypass.open()

      Application.put_env(:ethereum_jsonrpc, :url, "http://localhost:#{bypass.port}")
      on_exit(fn ->
        Application.put_env(:ethereum_jsonrpc, :url, @ethereum_jsonrpc_original)
      end)

      {:ok, bypass: bypass}
    end

    test "correctly returns the result of a smart contract function that does not receive arguments", %{bypass: bypass} do
      blockchain_resp = "[{\"jsonrpc\":\"2.0\",\"result\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"id\":\"0\"}]\n"
      Bypass.expect(bypass, fn conn -> Conn.resp(conn, 200, blockchain_resp) end)
      hash =
        :smart_contract
        |> insert()
        |> Map.get(:address_hash)
        |> Hash.to_string()

      assert Reader.query_contract(hash, "get") == [0]
    end
  end

  describe "get_abi_function/2" do
    test "return the selector of the desired function" do
      abi = [
        %ABI.FunctionSelector{
          function: "fn1",
          returns: {:uint, 256},
          types: [uint: 256]
        },
        %ABI.FunctionSelector{
          function: "fn2",
          returns: {:uint, 256},
          types: [uint: 256]
        }
      ]
      fn1 = %ABI.FunctionSelector{
        function: "fn1",
        returns: {:uint, 256},
        types: [uint: 256]
      }

      assert Reader.get_abi_function(abi, "fn1") == fn1
    end
  end

  describe "setup_call_payload/3" do
    test "returns the expected payload" do
      function_selector = %ABI.FunctionSelector{
        function: "get",
        returns: {:uint, 256},
        types: []
      }
      contract_address = "0x123789abc"

      assert Reader.setup_call_payload(
        function_selector,
        contract_address,
        []
      ) == [{"0x123789abc", "0x6d4ce63c"}]
    end
  end

  describe "encode_function_call/2" do
    test "generates the correct encoding with no arguments" do
      function_selector = %ABI.FunctionSelector{
        function: "get",
        returns: {:uint, 256},
        types: []
      }

      assert Reader.encode_function_call(
        function_selector,
        []
      ) == "6d4ce63c"
    end

    test "generates the correct encoding with arguments" do
      function_selector = %ABI.FunctionSelector{
        function: "get",
        returns: {:uint, 256},
        types: [{:uint, 256}]
      }

      assert Reader.encode_function_call(
        function_selector,
        [10]
      ) == "9507d39a000000000000000000000000000000000000000000000000000000000000000a"
    end
  end

  describe "decode_result/2" do
    test "correclty decodes the blockchain result" do
      result = {:ok,
        [
          %{
            "id" => "0x7e50612682b8ee2a8bb94774d50d6c2955726526",
            "jsonrpc" => "2.0",
            "result" => "0x000000000000000000000000000000000000000000000000000000000000002a"
          }
        ]}
      function_selector = %ABI.FunctionSelector{
        function: "get",
        returns: {:uint, 256},
        types: [{:uint, 256}]
      }

      assert Reader.decode_result(result, function_selector) == [42]
    end
  end
end
