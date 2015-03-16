" Vim plugin for loading dynamic configurations
" Version:     1.0
" Last Change: 2015-03-16
" Author:      Niels Bo Andersen <niels@niboan.dk>
" License:     This file is placed in the public domain.

if exists("g:loaded_plugconf")
  finish
endif
let g:loaded_plugconf = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:plugconf_menu')
  let g:plugconf_menu = 1
endif

if !exists('g:plugconf_path')
  let g:plugconf_path = 'plugconf'
endif


if !exists(":PlugConf")
  command PlugConf call plugconf#load()
endif

if !exists(":PlugConfList")
  command PlugConfList call s:listConfigurations()
endif

if !exists(":PlugConfEdit")
  command -nargs=1 -complete=custom,s:pluginComplete PlugConfEdit call s:editConfiguration('<args>')
endif


function! s:normalizePathSeparator(str)
  return substitute(a:str, '\\', '/', 'g')
endfunction


function! s:getRtpEntries()
  return split(s:normalizePathSeparator(&rtp), ',')
endfunction


let s:pluginList = []
let s:loaded = {}
let s:rtpBase = s:getRtpEntries()[0]
let s:confDir = s:rtpBase . '/' . g:plugconf_path

if !isdirectory(s:confDir)
  call mkdir(s:confDir, "p")
endif


" Extract the plugin name from the rintime path entry.
function! s:getPluginName(pluginPaths, rtpEntry)
  for pluginPath in a:pluginPaths
    let matches = matchlist(a:rtpEntry, '^' . pluginPath . '\([^/]\+\)/\?')
    if !empty(get(matches, 1))
      return get(matches, 1)
    endif
  endfor
endfunction


" Add a path to a list, if it points to a valid directory.
function! s:addPathIfExists(paths, path)
  if isdirectory(a:path)
    call add(a:paths, a:path)
  endif
endfunction


" Get a list of paths to search for plugins
function! s:getPluginPaths(rtpEntries)
  let paths = []

  call s:addPathIfExists(paths, s:rtpBase . '/plugged/')
  call s:addPathIfExists(paths, s:rtpBase . '/bundle/')

  return paths
endfunction


" Get the location of the config file for a given plugin.
" If the plugin name itself ends with '.vim' (e.g. 'xxx.vim'), only append '.vim' to the
" filename if the configuration file ('xxx.vim.vim') already exists.
function! s:getConfigFileName(plugin)
  let fileBase = s:confDir . '/' . a:plugin
  let fileName = fileBase . '.vim'
  if filereadable(fileName)
    return fileName
  endif
  if a:plugin =~ "\.vim$"
    let fileName = fileBase
  endif
  return fileName
endfunction


" Populate the global variable s:pluginList with a list of installed plugins.
function! s:getPlugins()
  let rtpEntries = s:getRtpEntries()

  for rtpEntry in rtpEntries
    let pluginName = s:getPluginName(s:getPluginPaths(rtpEntries), rtpEntry)
    if !empty(pluginName) && index(s:pluginList, pluginName) < 0
      call add(s:pluginList, pluginName)
    endif
  endfor

  call sort(s:pluginList, 1)
endfunction


" Command line complete function for installed plugins
function! s:pluginComplete(ArgLead, CmdLine, CursorPos)
  return join(s:pluginList, "\n") . "\n"
endfunction


" Load configurations for installed plugins.
function! s:loadConfigurations()
  call s:getPlugins()

  for plugin in s:pluginList
    let confFile = s:getConfigFileName(plugin)
    if filereadable(confFile)
      execute 'source ' . confFile
      let s:loaded[plugin] = confFile
    endif
  endfor
endfunction


" Create the gui menu for editing plugin configurations.
function! s:createMenu()
  for plugin in s:pluginList
    let menutext = 'Plugin.Configure.' . substitute(plugin, '\.', '\\.', 'g')
    if has_key(s:loaded, plugin)
      let menutext .= '\ (*)'
    endif
    execute 'amenu ' . menutext . ' :PlugConfEdit ' . plugin . ''
  endfor
endfunction


" Print a list of loaded configurations.
function! s:listConfigurations()
  for plugin in keys(s:loaded)
    echo plugin . ': ' . s:loaded[plugin]
  endfor
endfunction


function! s:editConfiguration(plugin)
  execute 'edit ' . s:getConfigFileName(a:plugin)
endfunction


function! plugconf#load()
  call s:loadConfigurations()

  if g:plugconf_menu
    call s:createMenu()
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
