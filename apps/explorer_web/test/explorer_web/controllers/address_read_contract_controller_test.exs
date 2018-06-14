defmodule ExplorerWeb.AddressReadContractControllerTest do
  use ExplorerWeb.ConnCase

  describe "GET show/3" do
    test "only responds to ajax requests", %{conn: conn} do
      address = insert(:address)

      path =
        address_read_contract_path(
          ExplorerWeb.Endpoint,
          :show,
          :en,
          address,
          address.hash,
          function_name: "totalSuply()",
          parameters: []
        )

      conn = get(conn, path)

      assert conn.status == 404
    end

    test "renders partial with function response", %{conn: conn} do
      address = insert(:address)

      path =
        address_read_contract_path(
          ExplorerWeb.Endpoint,
          :show,
          :en,
          address,
          address.hash,
          function_name: "totalSuply()",
          parameters: []
        )

      conn =
        conn
        |> put_req_header("x-requested-with", "xmlhttprequest")
        |> get(path)

      assert html_response(conn, 200) =~ "[ totalSuply() method Response ]"
    end
  end
end
