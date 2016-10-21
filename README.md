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
  Allow multiple Bible Servers which can be referenced by the version name.
  Fix reference expansion to proper list John 3:5, John 3:7 as John 3:5,7. To do this, the reference needs to be generated as a bitmap and then expansion done. This will give the references in the correct order as well. Maybe this is called 'normalization' and is a special call.

  Thinking space here: Can John 3:5,7 be expanded to John 3:5; John 3:7 prior to generating the references. When a comma is found, collect from start of the reference to comma, less one level and place that at start of what's after the comma. Should change the expansion machine to handle lists of references. Need to add an accumulator list, then absorb the ',' and the ';' into the machine.

- Fix references for "," and ";". Missed this.
- Add reference validation,
- Add reference equality
- Add reference negation
- Make all exp references work with multiple citations, or just 1.
- Update testing with valid asserts
- Add calls that accept list of reference structures where appropriate.

## Done - Git Comments Here
ReadServer is no longer a GenServer but simply a module.
Added the MIT license.

## Road Map
Integrate Bible reading tracking into a website for users. Users ID is provided by the system and is the only information requested from the user except for what they read. No reason for saving confidential information. Unused accounts can be deleted after xx days. Codes could be like apple-wood-home. Users could select a code by pressing next to get a new one.

## Bible Reading Plans
https://en.m.wikipedia.org/wiki/Bible_citation
http://www.biblica.com/en-us/bible/reading-plans/
http://www.alextran.org/23-bible-reading-plans-that-will-satisfy-anyone/
http://www.challies.com/sites/all/files/attachments/professor-grant-horners-bible-reading-system.pdf
https://www.backtothebible.org/one-year-reading-plans
