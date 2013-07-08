calendar.vim
============

`calendar.vim` creates a calendar window you can use within vim.  It is useful
in its own right as a calendar-inside-vim.  It also provides hooks to customise
its behaviour, making it a good basis for writing new plugins which require
calendar functionality (see `:help calendar-hooks` for more information).

Installation
------------

You can install `calendar.vim` in the usual way, by copying the contents of the
`plugin`, `autoload` and `doc` directories into the equivalent directories
inside `.vim`.

Alternatively, if you manage your plugins using [pathogen.vim][1], you can
simply clone into the `bundle` directory:

    cd ~/.vim/bundle
    git clone git://github.com/mattn/calendar-vim

Or, using submodules:

    cd ~/.vim
    git submodule add git://github.com/mattn/calendar-vim bundle/calendar-vim

Usage
-----

Bring up a calendar based on today's date in a vertically split window:

    :Calendar

Bring up a calendar showing November, 1991 (The month Vim was first released):

    :Calendar 1991 11

The above calendars can alternatively be displayed in a horizontally split
window:

    :CalendarH

Bring up a full-screen:

    :CalendarT

Fast mappings are provided:

* <kbd>&lt;LocalLeader&gt;cal</kbd>: Vertically-split calendar
* <kbd>&lt;LocalLeader&gt;caL</kbd>: Horizontally-split calendar

For full documentation, install the plugin and run `:help calendar` from within
Vim.

[1]: https://github.com/tpope/vim-pathogen
