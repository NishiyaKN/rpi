" Disable compatibility with vi which can cause unexpected issues.
  set nocompatible

" Enable type file detection. Vim will be able to try to detect the type of file in use.
 filetype on

" Enable plugins and load plugin for the detected file type.
"  filetype plugin on

" Makes it better to view number
 set relativenumber

" Load an indent file for the detected file type.
"  filetype indent on

" Turn syntax highlighting on.
  syntax on

" Add numbers to each line on the left-hand side.
  set number

  au BufNewFile,BufRead * if &syntax == '' | set syntax=dosini | endif

" Highlight the search term
  set incsearch

  " Automatically switch search to case-sensitive when search contains an uppercase letter
  set smartcase
  set ignorecase

" Menu for commands tab completion
  set wildmenu

" Avoids updating the screen before commands are completed
set lazyredraw

" No auto commenting
set formatoptions-=cro

" Allows to copy and paste to clipboard
set clipboard=unnamedplus

" Persistent undo between opening and closing file
"set undofile

" Directory to put the .un files ^^^^^
"set undodir /home/yori/.config/vim/

" Sets vim to paste more than a few lines
set viminfo='100,<10000000,s1000000,h

" Make vim work with the 'crontab -e' command
set backupskip+=/var/spool/cron/*

" Smart Indentation
" set smartindent

" Convert tabs to spaces
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Highlight the line where the cursor is
"set cursorline
"hi CursorLine   cterm=NONE ctermbg=black ctermfg=white
" Set undo history
set history=1000

" Remap navigation commands to center view on cursor using zz
nnoremap <C-U> 11kzz
nnoremap <C-D> 11jzz
nnoremap j jzz
nnoremap k kzz
nnoremap # #zz
nnoremap * *zz
nnoremap n nzz
nnoremap N Nzz
nnoremap <Up> <Up>zz
nnoremap <Down> <Down>zz
" esc in insert & visual mode
inoremap df <esc>
vnoremap df <esc>
" Copy and Paste to system clipboard
vnoremap <C-y> "+y
map <C-p> "+p
" esc in command mode
cnoremap df <C-C>
" Spell check
map <F6> :setlocal spell! spelllang=en_us<CR>
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" --- OSC 52 Clipboard Integration (Fixed for RPi) ---

function! Osc52Copy(text)
  " 1. Convert text to base64 (remove newlines from the base64 output)
  let text_b64 = system('base64 | tr -d "\n"', a:text)

  " 2. Construct the OSC 52 escape sequence
  "    We use the shell's printf to avoid Vim internal channel errors.
  "    \033 is Escape, \007 is Bell (terminator).
  call system('printf "\033]52;c;%s\007" ' . text_b64 . ' > /dev/tty')
endfunction

" Autocommand: Watch for ANY yank ('y') and copy it
augroup Osc52Yank
  autocmd!
  " Trigger whenever text is yanked into the default register
  autocmd TextYankPost * if v:event.operator ==# 'y' && v:event.regname ==# '' | call Osc52Copy(@") | endif
augroup END

" Map Leader+c to force copy just in case
vnoremap <leader>c y:call Osc52Copy(@")<CR>
