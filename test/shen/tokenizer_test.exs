defmodule Shen.TokenizerTest do
  use ExUnit.Case
  alias Shen.Tokenizer

  test "tokenizer" do
    {:ok, io_string} = StringIO.open("(\"foo\"   \"bar\")")
    assert Tokenizer.next(io_string) == "["
    assert Tokenizer.next(io_string) == "foo"
    assert Tokenizer.next(io_string) == "bar"
    assert Tokenizer.next(io_string) == "]"
  end
end
