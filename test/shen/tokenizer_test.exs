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

  describe "booleans" do
    test "reads true as boolean true", context do
      io_string = open_io_string("true")
      bool = Tokenizer.next(io_string, context[:buffer])
      assert bool == true
      assert is_boolean(bool)
    end

    test "reads false as boolean false", context do
      io_string = open_io_string("false")
      bool = Tokenizer.next(io_string, context[:buffer])
      assert bool == false
      assert is_boolean(bool)
    end
  end

  describe "numbers" do
    # test "reads integers as Fixnums", context do
    #   io_string = open_io_string("37")
    #   assert Tokenizer.next(io_string, context[:buffer]) == 37
    # end

    # test "reads floating points as Floats" do
    #   num = lexer("37.42").next
    #   expect(num).to be_kind_of(Float)
    #   expect(num).to eq(37.42)
    # end

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
