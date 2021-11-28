#!/usr/bin/env bash
#shellcheck shell=bash
#shellcheck source=/dev/null
#shellcheck disable=SC2154

[[ -z $(command -v git) ]] && {
  echo "You need git installed. Please run 'sudo apt update && sudo apt install git' first."
  exit 1
}

[[ -z $(command -v curl) ]] && {
  echo "You need curl installed. Please run 'sudo apt update && sudo apt install curl' first."
  exit 1
}

export BashInfinity="${HOME}/.bashinfinity"

[[ -s "${BashInfinity}"/ ]] || {
  rm -rf "${BashInfinity}" 2>/dev/null
  git clone https://github.com/niieani/bash-oo-framework.git "${BashInfinity}" 1>/dev/null 2>&1
}

source "${BashInfinity}/lib/oo-bootstrap.sh"

ProjectRoot="$(pwd)"
export ProjectRoot="${ProjectRoot}"
export BuildDir="${ProjectRoot}/build"

export CC=gcc
export CXX=g++
export LD=ld

import util/log
#util/tryCatch util/exception

namespace build-and-run
#Log::AddOutput build-and-run DEBUG

function chdir()
{
  local path="${1}"
  cd "${path}" 1>/dev/null 2>&1 || e "cd: ${path}: No such file or directory" throw
}

function pushdir()
{
  local path="${1}"
  pushd "${path}" 1>/dev/null 2>&1 || e "pushd: ${path}: No such file or directory" throw
}

function popdir()
{
  popd 1>/dev/null 2>&1 || e "popd: directory stack empty" throw
}

function run()
{
  local args;

  local OIFC=${IFC}
  IFS=" " read -r -a args <<< "${1}"
  export IFC=${OIFC}
  #try
  #{
    {

      eval "${args[@]}"
      #eval "stdbuf -i0 -o0 -e0 ${args[@]}"
      #eval "stdbuf -oL -eL ${args[@]}"
      # eval "unbuffer  ${args[@]}"
    } #2>&1 1>/dev/null
    # 1> >(tee -a stdout.log ) 2> >(tee -a stderr.log >&2)
    # eval "( unbuffer ${args[@]} | tee stdout.log ) 3>&1 1>&2 2>&3 | tee stderr.log"
  #}
  #catch
  #{
  #  Exception::PrintException "${__EXCEPTION__[@]}"
  #  return 1
  #}
  return 0
}

function project-header()
{
  # now we can write with the DEBUG output set
  Logger::INFO "Fractional Division With Remainder: A CMake Project Template with Tests"
  local OIFC=${IFC}
  IFS="|" read -r -a cc_info <<< "$(${CC} --version 2>&1 | tr '\n' '|')"
  export IFC=${OIFC}
  Logger::INFO "$(UI.Color.Yellow)CC   : $(UI.Color.Default)${cc_info[0]}"
  Logger::INFO "$(UI.Color.Yellow)GIT  : $(UI.Color.Default)$(git --version)"
  Logger::INFO "$(UI.Color.Yellow)CMAKE: $(UI.Color.Default)$(cmake --version | tr '\n' ' ')"
}

function project-setup()
{
  Logger::INFO "Initialising git submodules..."
  run "git submodule init && git submodule update"
  Logger::INFO "Creating Build Folder..."
  run "mkdir -p build/"
}

function project-build()
{
  Logger::INFO "Building project..."
  pushdir "build/"
  run "cmake -DCODE_COVERAGE=ON -DCMAKE_BUILD_TYPE=Debug .."
  run "make -j$(nproc --all)"
#  run "cmake --build . --config Debug -- -j$(nproc --all)"
  run "make install | egrep -v 'gmock|gtest'"
  popdir
}

function project-tests()
{
  Logger::INFO "Running project test..."
  for tst in "./.local/test/"*
  do
    if run "${tst}" ; then
      Logger::INFO "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Test ${tst} $(UI.Color.Green)PASSED$(UI.Color.Default)"
    else
      Logger::ERROR "$(UI.Color.Red)$(UI.Powerline.Fail)$(UI.Color.Default) Test ${tst} $(UI.Color.Red)FAILED$(UI.Color.Default)"
      exit 1
    fi
  done
}

function project-clean()
{
  Logger::INFO "Cleaning output folders..."
  run "rm -rf build/* .local/bin/* .local/include/* .local/lib/* .local/test/*"
}

function main()
{
  local clean="${1:-0}"
  project-header
  if [[ "${clean}" -eq 1 ]]; then
     project-clean
  fi

  project-setup
  project-build
  project-tests
  # e="The hard disk is not connected properly!" throw
}

main "${@}"

