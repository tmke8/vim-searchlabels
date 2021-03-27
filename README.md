searchtags.vim
==============

Fork of [sneak.vim](http://github.com/justinmk/vim-sneak)
that hooks sneak's label mode into vim's native search.

It's is essentially a light-weight re-implementation of
[incsearch-easymotion.vim](https://github.com/haya14busa/incsearch-easymotion.vim)
or [easymotion](https://github.com/easymotion/vim-easymotion)'s n-character search motion.
One shortcoming with those is that they don't have regex support.
As this plugin only hooks in at the end of vim's native search, you get vim's full power.

Usage
-----

Just search something with `/`, and if there are multiple matches visible in your window,
labels will appear that allow you to jump directly to any of the matches.

Install
-------

- [vim-plug](https://github.com/junegunn/vim-plug)
  - `Plug 'thomkeh/vim-searchtags', { 'branch': 'main' }`
- [Pathogen](https://github.com/tpope/vim-pathogen)
  - `git clone git://github.com/thomkeh/vim-searchtags.git ~/.vim/bundle/vim-sneak`
- Manual installation:
  - Copy the files to your `.vim` directory.

FAQ
---

### Why not use Sneak?

First, I find two characters often too limited for narrowing down my search.
Second, I don't see the point of using `s`/`S` when I already use `/`/`?` a lot.
Third, if you are in an environment where you don't have your plugins,
then using `/`/`?` fails gracefully (you would just get normal search).

Related
-------

* [Sneak](http://github.com/justinmk/vim-sneak)
* [Seek](https://github.com/goldfeld/vim-seek)
* [EasyMotion](https://github.com/Lokaltog/vim-easymotion)
* [incsearch-easymotion](https://github.com/haya14busa/incsearch-easymotion.vim)
* [smalls](https://github.com/t9md/vim-smalls)
* [improvedft](https://github.com/chrisbra/improvedft)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [vim-extended-ft](https://github.com/svermeulen/vim-extended-ft)
* [Fanf,ingTastic;](https://github.com/dahu/vim-fanfingtastic)

License
-------

Distributed under the MIT license.
