# SYNOPSIS

A runner script for downloading a target file, running a target tool, and handling the result in a flexible manner. This is done as a shell script so that it can be run in pretty much any environment, in particular almost any type of Docker container.

One example includes:
- [androguard-manifest](https://github.com/dweinstein/dockerfile-androguard-manifest)

# USAGE

## required env TOOL or $1

The analysis tool to run (with some specific required parameters) and pass the input file to for processing.

## Option i

`-i <val>` specifies where to get the input, `val` can be a path to a file or a URL.

## Optional o

`-o <val>` specifies what to do with the result. If not supplied, the output will just go to stdout/stderr. If a URL is supplied the output will be POST'd to that URL on successful analysis.

## CONTENT_TYPE

The content-type for HTTP POST

## Rest

Arguments after `--` in the parameters are passed along to the analysis tool when it runs. This is mostly useful for the docker container use case.
