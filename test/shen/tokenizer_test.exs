defmodule Shen.TokenizerTest do
  use ExUnit.Case
  use ExUnit.Callbacks
  alias Shen.Tokenizer
  require IEx
  require Logger

  setup do
    {state, _} = Agent.start_link(fn -> [] end, name: :buffer)
    state
  end

  describe "whitespace" do
    test "is ignored between tokens" do
      io_string = open_io_string("  \n\r (\"foo\"   \"bar\"\t) \n")
      assert Tokenizer.next(io_string) == "["
      assert Tokenizer.next(io_string) == "foo"
      assert Tokenizer.next(io_string) == "bar"
      assert Tokenizer.next(io_string) == "]"
    end

    test "is kept intact inside of strings" do
      io_string = open_io_string("     \"one two\"   ")
      assert Tokenizer.next(io_string) == "one two"
    end
  end

  describe "symbols" do
    test "reads sign characters not followed by digits as symbols" do
      io_string = open_io_string("-")
      assert Tokenizer.next(io_string) == :-
      io_string = open_io_string("+")
      assert Tokenizer.next(io_string) == :+
      io_string = open_io_string("--+-")
      assert Tokenizer.next(io_string) == :"--+-"
    end

    test "reads double decimal points followed by digits as symbols" do
      io_string = open_io_string("..77")
      assert Tokenizer.next(io_string) == :"..77"
    end

    test "accepts =-*/+_?$!@~><&%'#`;:{} in symbols" do
      all_punctuation = "=-*/+_?$!@~><&%'#`;:{}"
      atom = Tokenizer.next(open_io_string(all_punctuation))
      assert is_atom(atom) == true
      assert to_string(atom) == all_punctuation
    end
  end

  describe "strings" do
    test "unterminated" do
      io_string = open_io_string("\"foo\" \"bar  baz")
      assert Tokenizer.next(io_string) == "foo"
      assert_raise RuntimeError, "unterminated string", fn ->
        Tokenizer.next(io_string)
      end
    end
  end

  describe "booleans" do
    test "reads true as boolean true" do
      io_string = open_io_string("true")
      bool = Tokenizer.next(io_string)
      assert bool == true
      assert is_boolean(bool)
    end

    test "reads false as boolean false" do
      io_string = open_io_string("false")
      bool = Tokenizer.next(io_string)
      assert bool == false
      assert is_boolean(bool)
    end
  end

  describe "numbers" do
    test "reads integers as Fixnums" do
      io_string = open_io_string("37")
      num = Tokenizer.next(io_string)
      assert is_integer(num)
      assert num == 37
    end

    test "reads floating points as Floats" do
      io_string = open_io_string("37.42")
      num = Tokenizer.next(io_string)
      assert is_float(num)
      assert num == 37.42
    end

    # test "with an odd number of leading minuses are negative" do
    #   expect(lexer('-1').next).to eq(-1)
    #   expect(lexer('---1').next).to eq(-1)
    # end

    # test "with an even number of leading minuses are positive" do
    #   expect(lexer('--1').next).to eq(1)
    #   expect(lexer('----1').next).to eq(1)
    # end

    # test "with leading + does not change sign" do
    #   expect(lexer('+-1').next).to eq(-1)
    #   expect(lexer('-+--1').next).to eq(-1)
    #   expect(lexer('-+-+1').next).to eq(1)
    #   expect(lexer('+-+-+-+-+1').next).to eq(1)
    # end

    # test "allows leading decimal points" do
    #   expect(lexer('.9').next).to eq(0.9)
    #   expect(lexer('-.9').next).to eq(-0.9)
    # end

    # test "treats a trailing decimal followed by EOF as a symbol" do
    #   l = lexer('7.')
    #   num = l.next
    #   expect(num).to be_kind_of(Fixnum)
    #   expect(num).to eq(7)

    #   sym = l.next
    #   expect(sym).to be_kind_of(Symbol)
    #   expect(sym.to_s).to eq('.')
    # end

    # test "treats a trailing decimal followed by non-digit as a symbol" do
    #   l = lexer('7.a')
    #   num = l.next
    #   expect(num).to be_kind_of(Fixnum)
    #   expect(num).to eq(7)

    #   sym = l.next
    #   expect(sym).to be_kind_of(Symbol)
    #   expect(sym.to_s).to eq('.a')
    # end

    # test "handles multiple decimal points like shen does" do
    #   l = lexer('7.8.9')
    #   expect(l.next).to eq(7.8)
    #   expect(l.next).to eq(0.9)
    # end
  end

  defp open_io_string(string) do
    {:ok, io_string} = StringIO.open(string)
    io_string
  end
end
