-module(example_php).
-author('Max Lapshin <max@maxidoors.ru>').
-author('David Coallier <davidc@php.net>').

-export([start/1, start/2, stop/1]).

start(PhpPath) ->
  application:load(example_php),
  application:set_env(example_php, path, Path),
  application:start(cowboy),
  application:start(example_php).


start(_, _) ->
  {ok, Path} = application:get_env(example_php, path),
  Dispatch = [
		{'_', [
			{['...'], cowboy_php_handler, [{path, Path}]}
		]}
	],
	cowboy:start_listener(http, 1,
		cowboy_tcp_transport, [{port, 8080}],
		cowboy_http_protocol, [{dispatch, Dispatch}]
	).

stop(_) ->
  ok.
