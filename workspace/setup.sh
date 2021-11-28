#!/usr/bin/env bash

export LANG=C.UTF-8

function link-configs()
{
 ln -sf ${HOME}/workspace/.config/bash_aliases ${HOME}/.bash_aliases
 ln -sf ${HOME}/workspace/.config/SpaceVim.d  ${HOME}/.SpaceVim.d
}

link-configs

exec "$@"
