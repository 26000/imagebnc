# imagebnc
A WeeChat plugin to open images conveniently.

## Installation
### WeeChat plugin
Just put the image\_bnc.rb file into your `.weechat/ruby/autoload/` directory. Set all settings and use `/i <number>` to open image #<number> counting from the bottom in feh.

If you are not going to use a proxy, just leave that setting blank.

### Server-side bouncer
Set up Golang compiler and $GOPATH (read more about it [here](https://github.com/golang/go/wiki/GOPATH)), then just do `go get github.com/26000/imagebnc/imagebnc-server` and run `imagebnc-server`. It will create a sample config file in the current directory, edit it and run `imagebnc-server` once more. All done!

## Why a server part?
When you open an image in IRC, you download it. That means you reveal your IP address to the server which hosts that image.
