calendar.vim
============

[![Test](https://github.com/mattn/calendar-vim/actions/workflows/test.yml/badge.svg)](https://github.com/mattn/calendar-vim/actions/workflows/test.yml)

`calendar.vim` creates a calendar window you can use within vim.  It is useful
in its own right as a calendar-inside-vim.  It also provides hooks to customise
its behaviour, making it a good basis for writing new plugins which require
calendar functionality (see `:help calendar-hooks` for more information).

Installation
------------

Using [vim-plug](https://github.com/junegunn/vim-plug), add the following to your `.vimrc`:

```vim
Plug 'mattn/calendar-vim'
```

Then run `:PlugInstall`.

Usage
-----

Bring up a calendar based on today's date in a vertically split window:

    :Calendar

Bring up a calendar showing November, 1991 (The month Vim was first released):

    :Calendar 1991 11

The above calendars can alternatively be displayed in a horizontally split
window:

    :CalendarH

Bring up a full-screen calendar:

    :CalendarT

Fast mappings are provided:

* <kbd>&lt;LocalLeader&gt;cal</kbd>: Vertically-split calendar
* <kbd>&lt;LocalLeader&gt;caL</kbd>: Horizontally-split calendar

For full documentation, install the plugin and run `:help calendar` from within
Vim.

License
-------

MIT

Author
------

Yasuhiro Matsumoto (a.k.a. mattn)
