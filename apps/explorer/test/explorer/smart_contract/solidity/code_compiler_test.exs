defmodule Explorer.SmartContract.Solidity.CodeCompilerTest do
  use ExUnit.Case, async: true

  doctest Explorer.SmartContract.Solidity.CodeCompiler

  alias Explorer.SmartContract.Solidity.CodeCompiler
  alias Explorer.Factory

  describe "run/2" do
    setup do
      {:ok, contract_code_info: Factory.contract_code_info()}
    end

    test "compiles the latest solidity version", %{contract_code_info: contract_code_info} do
      response =
        CodeCompiler.run(
          contract_code_info.name,
          contract_code_info.version,
          contract_code_info.source_code,
          contract_code_info.optimized
        )

      assert {:ok,
              %{
                "abi" => _,
                "bytecode" => _,
                "name" => _,
                "opcodes" => _
              }} = response
    end

    test "compiles a optimized smart contract", %{contract_code_info: contract_code_info} do
      optimize = true

      response =
        CodeCompiler.run(
          contract_code_info.name,
          contract_code_info.version,
          contract_code_info.source_code,
          optimize
        )

      assert {:ok,
              %{
                "abi" => _,
                "bytecode" => _,
                "name" => _,
                "opcodes" => _
              }} = response
    end

    test "compile in an older solidity version" do
      optimize = false
      name = "SimpleStorage"

      code = """
      contract SimpleStorage {
          uint storedData;

          function set(uint x) public {
              storedData = x;
          }

          function get() public constant returns (uint) {
              return storedData;
          }
      }
      """

      version = "v0.1.3-nightly.2015.9.25+commit.4457170"

      response = CodeCompiler.run(name, version, code, optimize)

      assert {:ok,
              %{
                "abi" => _,
                "bytecode" => _,
                "name" => _,
                "opcodes" => _
              }} = response
    end

    test "returns a list of errors the compilation isn't possible", %{contract_code_info: contract_code_info} do
      wrong_code = "pragma solidity ^0.4.24; cont SimpleStorage { "

      response =
        CodeCompiler.run(
          contract_code_info.name,
          contract_code_info.version,
          wrong_code,
          contract_code_info.optimized
        )

      assert {:error, [_ | _]} = response
    end
  end
end
