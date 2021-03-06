defmodule Shen.Tokenizer do
  @symbol_chars ~r/[-=*\/+_?$!\@~><&%'#`;:{}a-zA-Z0-9.]/
  require IEx
  require Logger

  def next(io_device) do
    drain_whitespace(io_device)
    c = getc(io_device)
    token = unless eof?(c) do
      cond do
        c == "(" -> "["
        c == ")" -> "]"
        c == "\"" -> consume_string(io_device)
        Regex.match?(@symbol_chars, c) ->
          ungetc(c)
          consume_number_or_symbol(io_device)
        true -> c
      end
    end
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

  defp getc(io_device) do
    if c = Agent.get_and_update(:buffer, &pop/1) do
      c
    else
      IO.read(io_device, 1)
    end
  end

  defp ungetc(c) do
    Agent.update(:buffer, fn buffer -> [c | buffer] end)
  end

  defp consume_string(io_device, list_of_chars \\ []) do
    c = getc(io_device)
    if eof?(c), do: raise "unterminated string"
    case c do
      "\"" -> Enum.join(list_of_chars)
      _ -> consume_string(io_device, list_of_chars ++ [c])
    end
  end

  defp drain_whitespace(io_device) do
    c = getc(io_device)
    unless eof?(c) do
      if Regex.match?(~r/\s/, c) do
        drain_whitespace(io_device)
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
      consume_symbol(io_device)
    else
      chars = chars ++ [c]
      if c == "." do
        c = getc(io_device)
        if eof?(c) do
          unget_chars(chars)
          consume_symbol(io_device)
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

  defp get_number_chars(io_device, list_of_chars, bools) do
    c = getc(io_device)
    cond do
      eof?(c) ->
        {list_of_chars, bools}
      Regex.match?(~r/\d/, c) ->
        get_number_chars(io_device,
                         list_of_chars ++ [c],
                         %{bools | past_sign: true})
      c == "." and not bools.decimal_seen ->
        get_number_chars(io_device,
                         list_of_chars ++ [c],
                         %{bools | past_sign: true, decimal_seen: true})
      c == "-" and not bools.past_sign ->
        get_number_chars(io_device,
                         list_of_chars,
                         %{bools | negative: !bools.negative})
      c == "+" ->
        get_number_chars(io_device, list_of_chars, bools)
      true ->
        ungetc(c)
        {list_of_chars, bools}
    end
  end

  defp consume_number(io_device) do
    {chars, bools} = get_number_chars(io_device,
                                      [],
                                      %{decimal_seen: false,
                                        negative: false,
                                        past_sign: false})
    chars = if bools.negative do
      ["-"] ++ chars
    else
      chars
    end

    {last_decimal_seen, chars} = \
      if List.last(chars) == "." do
        {c, cs} = List.pop_at(chars, -1)
        ungetc(c)
        {true, cs}
      else
        {false, chars}
      end

    str = Enum.join(chars)
    if bools.decimal_seen and not last_decimal_seen do
      String.to_float(sanitize_float(str))
    else
      String.to_integer(str)
    end
  end

  defp sanitize_float(str) do
    cond do
      String.starts_with?(str, ".") ->
        Enum.join(["0", str])
      String.starts_with?(str, "-.") ->
        Enum.join(["-0.", String.trim_leading(str, "-.")])
      true -> str
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
        ungetc(c)
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
