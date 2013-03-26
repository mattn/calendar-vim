all : calendar-vim.zip

remove-zip:
	-rm doc/tags
	-rm calendar-vim.zip

calendar-vim.zip: remove-zip
	zip -r calendar-vim.zip autoload plugin doc

release: calendar-vim.zip
	vimup update-script calendar.vim
