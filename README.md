
# catkin-vim

A Vim plugin for managing and compiling ROS Catkin workspaces with vim-dispatch integration for asynchronous execution.
This plugin allows you to easily configure, clean, and build packages in your Catkin workspace directly from Vim.

## Features
- **Package Selection**: Interactive package selection for building only what you need.
- **Catkin Management**: Run common `catkin` commands like `catkin {init, clean, build}`
- **Asynchronous Execution**: Utilize `vim-dispatch` to run Catkin commands asynchronously.

## Commands
- `CatkinBuild` sets `:Make` to `catkin build`  and runs `:Make` using dispatch
- `CatkinInit` checks that you are in a catking workspaces, runs `catkin init` and sets `:Make` to `catkin build`
- `CatkinCCMake`: runs ccmake for the given package
- `CatkinSelectPackages`: Select the packages to build

## Installation
Use your preferred plugin manager:

```vim
Plug 'yourusername/vim-catkin-manager'
