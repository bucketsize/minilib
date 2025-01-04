# minilib

## dependencies
- lua >= 5.1
- liblua >= 5.1
- luarocks
- build-essential

### debian
`apt install lua5.3 liblua5.3-dev luarocks build-essential`


## install
Clone this repo, and from toplevel:

`luarocks make --local` #installs to ~/.luarocks

## uninstall
`luarocks remove minilib --local` #removes from ~/.luarocks

## todo 
- undep build-essential liblua-dev luarocks
- bundle lua runtime < 200kb
