defmodule Date.Temp do
  @moduledoc """
  These are some functions that were in Timex but only date functions were used.
  Timex brings in much more including the timezone database. Not needed for
  this.

  Elixir version 1.5 has some of the functionality needed. Look when it comes
  to see what can be removed from here.

  All date functions are in the reader module.
  """
  @doc """
  Replaces the Timex diff function with Elixir library NaiveDateTime. Returns
  the difference as the number of days.
  """
  def diff(date1,date2) do
    {:ok, naive1} = NaiveDateTime.new(date1.year,date1.month,date1.day,0,0,0)
    {:ok, naive2} = NaiveDateTime.new(date2.year,date2.month,date2.day,0,0,0)
    trunc(NaiveDateTime.diff(naive1,naive2) / 60 / 60 / 24)
  end

  def now do
    {{year, month, day}, _time} = :calendar.local_time()
    Date.new year, month, day
  end

  @doc """
  Parses the date string "{D}-{Mshort}-{YYYY}".
  """
  def parse date_string do
    with  [day_string, month_string, year_string] <- String.split(date_string, "-", parts: 3),
          {day, ""} <- Integer.parse(day_string),
          {year, ""} <- Integer.parse(year_string),
          {mindex, 3} <- :binary.match("JanFebMarAprMayJunJulAugSepOctNovDec", month_string),
          month <- trunc(mindex / 3 + 1)
    do    Date.new(year,month,day)
  else  _ -> {:error, "Could Not Parse Date"}
    end
  end

  def shift date, [days: days] do
    {:ok, naive} = NaiveDateTime.new(date.year,date.month,date.day,0,0,0)
    shift = days * 60 * 60 * 24
    naive = NaiveDateTime.add(naive,shift)
    {:ok, date} = Date.new(naive.year, naive.month, naive.day)
    date
  end
end
