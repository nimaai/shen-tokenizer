defmodule Shen.TokenizerTest do
  use ExUnit.Case
  use ExUnit.Callbacks
  alias Shen.Tokenizer
  require IEx

  setup do
    {:ok, buffer} = Agent.start_link(fn -> [] end)
    [buffer: buffer]
  end

  describe "whitespace" do
    test "is ignored between tokens", context do
      io_string = open_io_string("  \n\r (\"foo\"   \"bar\"\t) \n")
      assert Tokenizer.next(io_string, context[:buffer]) == "["
      assert Tokenizer.next(io_string, context[:buffer]) == "foo"
      assert Tokenizer.next(io_string, context[:buffer]) == "bar"
      assert Tokenizer.next(io_string, context[:buffer]) == "]"
    end

    test "is kept intact inside of strings", context do
      io_string = open_io_string("     \"one two\"   ")
      assert Tokenizer.next(io_string, context[:buffer]) == "one two"
    end
  end

  describe "symbols" do
    test "reads sign characters not followed by digits as symbols", context do
      io_string = open_io_string("-")
      assert Tokenizer.next(io_string, context[:buffer]) == :-
      io_string = open_io_string("+")
      assert Tokenizer.next(io_string, context[:buffer]) == :+
      io_string = open_io_string("--+-")
      assert Tokenizer.next(io_string, context[:buffer]) == :"--+-"
    end

    test "reads double decimal points followed by digits as symbols", context do
      io_string = open_io_string("..77")
      assert Tokenizer.next(io_string, context[:buffer]) == :"..77"
    end

    test "accepts =-*/+_?$!@~><&%'#`;:{} in symbols", context do
      all_punctuation = "=-*/+_?$!@~><&%'#`;:{}"
      atom = Tokenizer.next(open_io_string(all_punctuation), context[:buffer])
      assert is_atom(atom) == true
      assert to_string(atom) == all_punctuation
    end
  end

  describe "strings" do
    test "unterminated", context do
      io_string = open_io_string("\"foo\" \"bar  baz")
      assert Tokenizer.next(io_string, context[:buffer]) == "foo"
      assert_raise RuntimeError, "unterminated string", fn ->
        Tokenizer.next(io_string, context[:buffer])
      end
    end
  end

  defp open_io_string(string) do
    {:ok, io_string} = StringIO.open(string)
    io_string
  end
end
