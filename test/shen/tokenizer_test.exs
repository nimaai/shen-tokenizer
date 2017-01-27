defmodule Shen.TokenizerTest do
  use ExUnit.Case
  alias Shen.Tokenizer

  test "drain whitespace" do
    {:ok, io_string} = StringIO.open("  \n\r (\"foo\"   \"bar\"\t) \n")
    {:ok, buffer} = Agent.start_link(fn -> [] end)
    assert Tokenizer.next(io_string, buffer) == "["
    assert Tokenizer.next(io_string, buffer) == "foo"
    assert Tokenizer.next(io_string, buffer) == "bar"
    assert Tokenizer.next(io_string, buffer) == "]"
    Agent.stop(buffer)
  end
end
