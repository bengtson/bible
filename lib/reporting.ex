defmodule Bible.Reporting do
@moduledoc """
Defines some useful reporting from the bible database.
"""

  @doc """
  Returns the following results:
  { % To Target Last 7 days,
    % To Target Last 30 days,
    % To Target Last 365 days,
    [ Last 5 readings ] }
  """
  def read_metrics(pid) do
    end_date = Timex.now
    days_list = [1,7,30,365]
    target_attainment = days_list
      |> Enum.map(&(to_date_range(&1,end_date)))
      |> Enum.map(&(Bible.ReadServer.get_readings(pid,&1)))
      |> Enum.map(&(Bible.ReadServer.reading_metrics(pid, &1, "Genesis - Revelation")))
      |> Enum.map(fn {total, read} -> read/total end)
      |> Enum.zip(days_list)
      |> Enum.map(fn {percent, days} -> {days, percent * 365 / days} end)

      latest = for(<< _days :: unsigned-integer-size(16),
          start_book_number :: unsigned-integer-size(8),
          start_chap :: unsigned-integer-size(8),
          start_vers :: unsigned-integer-size(8),
          end_book_number :: unsigned-integer-size(8),
          end_chap :: unsigned-integer-size(8),
          end_vers :: unsigned-integer-size(8) <- Bible.ReadServer.get_readings(pid) >>, do:
            { Bible.Server.get_book_name(start_book_number), start_chap, start_vers,
              Bible.Server.get_book_name(end_book_number), end_chap, end_vers })
        |> Enum.take(-5)
        |> Enum.map(&(Bible.References.reduce_reference(&1)))
        |> Enum.reverse
      { target_attainment, latest }
  end

  defp to_date_range(days,end_date) do
    {Timex.shift(end_date, days: -days+1),end_date}
  end

  @doc """
  This generates an svg file showing what parts of the bible have been read.

  How would this work ...

  Using a state machine, initialize state as follows:
  cursor x =>
  cursor y =>
  book_map => %{ Genesis => %{ text_pos, << chapter grid pos binary >>}}


  """
  def read_map do
#    book_number_map = Bible.Server.get
  end
end
