defmodule Farmbot.CeleryScript.ASTTest do
  @moduledoc "Tests ast nodes"
  use ExUnit.Case

  alias Farmbot.CeleryScript.AST

  test "parses a string key'd map" do
    ast =
      %{"kind" => "kind", "args" => %{}}
      |> AST.parse()

    assert ast.kind == "kind"
    assert ast.args == %{}
    assert ast.body == []
  end

  test "parses atom map" do
    ast = %{kind: "hello", args: %{}} |> AST.parse()

    assert ast.kind == "hello"
    assert ast.args == %{}
    assert ast.body == []
  end

  defmodule SomeUnion do
    @moduledoc "Wraps a celeryscript AST"
    defstruct [:kind, :args]
  end

  test "parses a struct" do
    ast = %SomeUnion{kind: "whooo", args: %{}} |> AST.parse()
    assert ast.kind == "whooo"
    assert ast.args == %{}
    assert ast.body == []
  end

  test "parses body nodes" do
    sub_ast_1 = %{"kind" => "sub1", "args" => %{}}
    sub_ast_2 = %{kind: "sub2", args: %{}}
    ast = %{kind: "hey", args: %{}, body: [sub_ast_1, sub_ast_2]} |> AST.parse()

    assert ast.kind == "hey"
    assert ast.args == %{}
    assert Enum.at(ast.body, 0).kind == "sub1"
    assert Enum.at(ast.body, 1).kind == "sub2"
  end

  test "changes args to atoms" do
    ast = %{kind: "124", args: %{"string_key" => :hello}} |> AST.parse()
    assert ast.kind == "124"
    assert ast.args.string_key == :hello
    assert ast.args == %{string_key: :hello}
  end

  test "parses sub nodes in the args" do
    ast = %{kind: "main", args: %{"node" => %{kind: "sub", args: %{}}}} |> AST.parse()
    assert ast.kind == "main"
    assert ast.args.node.kind == "sub"
  end
end
