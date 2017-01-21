defmodule Shen.Tokenizer do
  # @symbol_chars ~r/[-=*\/+_?$!\@~><&%'#`;:{}a-zA-Z0-9.]/
  # require IEx

  def next(io_device) do
    drain_whitespace(io_device)
    c = readc(io_device)
    unless c == :eof do
      case c do
        "(" -> "["
        ")" -> "]"
        "\"" -> consume_string(io_device, [])
        _  -> c
      end
    end
  end

  defp readc(io_device) do
    IO.read(io_device, 1)
  end

  defp consume_string(io_device, list_of_chars) do
    c = readc(io_device)
    case c do
      :eof -> raise "unterminated string"
      "\"" -> Enum.join(list_of_chars)
      _ -> consume_string(io_device, list_of_chars ++ [c])
    end
  end

  defp drain_whitespace(io_device) do
    c = readc(io_device)
    unless c == :eof do
      if Regex.match?(~r/\s/, c) do
        drain_whitespace(io_device)
      else
        next(io_device)
      end
    end
  end
end
