## Overview

The Bible Metrics (bible_metrics) application provides functions related to the layout and access to the scriptures in a Bible. The following are examples of how the application might be used:

* Query how many chapters are in a book of the Bible.
* Query how many verses are in a book of the Bible.
* Query how many verses are in a Bible citation.
* Determine how much of the Bible has been read given a reading list.
* Determine what parts of the Bible have not been read given a reading list.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `bible_metrics` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:bible_metrics, "~> 0.1.0"}]
    end
    ```

  2. Ensure `bible_metrics` is started before your application:

    ```elixir
    def application do
      [applications: [:bible_metrics]]
    end
    ```
## Usage

  ```elixir
  iex> Bible.chapters_in_book("Matthew")
  28
  iex> Bible.verses_in_citation("Exodus 3-5")
  74
  ```

## Bible Metadata

The information about the books in the bible are held in a map. Each book has
it's own entry with the key being the name of the book. The value of each entry
is the info about the book in a binary as follows:

    byte 1 : "N" or "O" for new or old testament.
    byte 2 : Order of book in their respective testaments.
    byte 3 : Order of book in the Bible.
    byte 4 : Number of chapters in the book.
    byte 5..n : Number of verses starting with chapter 1. Each is a byte.

## To Do
  Put bible into git.
  Add reference validation,
  Add reference equality
  Add reference negation
  Make all exp references work with multiple citations, or just 1.
  Change Read List to be 03-Oct-2015 : John 1-4, Matthew 5-6
  Add function to clear the ReadServer.
  Add function to add a reading to the ReadServer (no file).
  Update testing with valid asserts
  Add calls that accept list of reference structures where appropriate.
- ...

## How Timex, Elixir Date work
Timex.now returns
#<DateTime(2016-10-04T16:03:05.793161Z Etc/UTC)>
This is a DateTime map with types such as hour
a = Timex.now
%{:hour => hour } = a
hour
returns the hour of the day.

Strange that
Calendar.minute(Timex.now)
Timex.now.day
Returns the day.
