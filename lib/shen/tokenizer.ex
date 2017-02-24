defmodule Shen.Tokenizer do
   @symbol_chars ~r/[-=*\/+_?$!\@~><&%'#`;:{}a-zA-Z0-9.]/
  # require IEx

  def next(io_device, buffer) do
    Process.register(buffer, :buffer)
    Agent.start_link(fn -> io_device end, name: :io_device)
    drain_whitespace()
    c = getc()
    token = unless eof?(c) do
      case c do
        "(" -> "["
        ")" -> "]"
        "\"" -> consume_string()
        _  -> c
      end
    end
    Process.unregister(:buffer)
    Agent.stop(:io_device)
    token
  end

  defp pop(buffer) do
    {List.first(buffer), Enum.drop(buffer, 1)}
  end

  defp empty?(buffer) do
    Enum.empty?(buffer)
  end

  defp eof?(c) do
    Agent.get(:buffer, &empty?/1) && c == :eof
  end

  defp getc() do
    if c = Agent.get_and_update(:buffer, &pop/1) do
      c
    else
      Agent.get(:io_device, fn io_device -> IO.read(io_device, 1) end)
    end
  end

  defp ungetc(c) do
    Agent.update(:buffer, fn buffer -> [c | buffer] end)
  end

  defp consume_string(list_of_chars \\ []) do
    c = getc()
    if eof?(c), do: raise "unterminated string"
    case c do
      "\"" -> Enum.join(list_of_chars)
      _ -> consume_string(list_of_chars ++ [c])
    end
  end

  defp drain_whitespace() do
    c = getc()
    unless eof?(c) do
      if Regex.match?(~r/\s/, c) do
        drain_whitespace()
      else
        ungetc(c)
      end
    end
  end

  defp unget_chars(list_of_chars) do
    Enum.reverse(list_of_chars) |> Enum.each(fn c -> ungetc(c) end)
  end

  defp consume_number_or_symbol(io_device) do
    # First drain optional leading signs
    # Then drain optional decimal point
    # If there is another character and it is a digit, then it
    # is a number. Otherwise it is a symbol.

    chars = drain_leading_signs(io_device, [])
    c = getc(io_device)
    if eof?(c) do
      unget_chars(chars)
      consume_symbol
    else
      chars = chars ++ [c]
      if c == "." do
        c = getc(io_device)
        if eof?(c) do
          unget_chars(chars)
          consume_symbol
        else
          chars = chars ++ [c]
          unget_chars(chars)
          if Regex.match?(~r/\d/, c) do
            consume_number(io_device)
          else
            consume_symbol(io_device)
          end
        end
      else
        unget_chars(chars)
        if Regex.match?(~r/\d/, c) do
          consume_number(io_device)
        else
          consume_symbol(io_device)
        end
      end
    end
  end

  defp consume_symbol(io_device) do
    chars = get_symbol_chars(io_device, [])
    str = Enum.join(chars)
    case str do
      "true" -> true
      "false" -> false
      _ -> String.to_atom(str)
    end
  end

  defp get_symbol_chars(io_device, list_of_chars) do
    c = getc(io_device)
    cond do
      eof?(c) ->
        list_of_chars
      not Regex.match?(@symbol_chars, c) ->
        unget(c)
        list_of_chars
      true ->
        get_symbol_chars(io_device, list_of_chars ++ [c])
    end
  end

  defp drain_leading_signs(io_device, list_of_chars) do
    c = getc(io_device)
    cond do
      eof?(c) ->
        list_of_chars
      not Regex.match?(~r/[-+]/, c) ->
        ungetc(c)
        list_of_chars
      true ->
        drain_leading_signs(io_device, list_of_chars ++ [c])
    end
  end
end
