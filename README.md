searchtags.vim
==============

Fork of sneak.vim that hooks the label mode into vim's native search.

Usage
-----

Just search something with `/`, and if there are multiple matches visible in your windows,
labels will appear that allow you to jump directly to any of the matches.

This is essentially a light-weight re-implementation of
[incsearch-easymotion.vim](https://github.com/haya14busa/incsearch-easymotion.vim)
and [easymotion](https://github.com/easymotion/vim-easymotion)'s n-character search motion.
One shortcoming with those is that they don't have regex support.
As this plugin only hooks in at the end of vim's native search, you get vim's full power.

Install
-------

- [vim-plug](https://github.com/junegunn/vim-plug)
  - `Plug 'thomkeh/vim-searchtags'`
- [Pathogen](https://github.com/tpope/vim-pathogen)
  - `git clone git://github.com/thomkeh/vim-searchtags.git ~/.vim/bundle/vim-sneak`
- Manual installation:
  - Copy the files to your `.vim` directory.

FAQ
---

### Why not use Sneak?

First, I find two characters often too limited in narrowing down my search.
Second, I don't see the point of using `s`/`S` when I already use `/`/`?` a lot.

Related
-------

* [Sneak](http://github.com/justinmk/vim-sneak)
* [Seek](https://github.com/goldfeld/vim-seek)
* [EasyMotion](https://github.com/Lokaltog/vim-easymotion)
* [smalls](https://github.com/t9md/vim-smalls)
* [improvedft](https://github.com/chrisbra/improvedft)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [vim-extended-ft](https://github.com/svermeulen/vim-extended-ft)
* [Fanf,ingTastic;](https://github.com/dahu/vim-fanfingtastic)

License
-------

Distributed under the MIT license.
