-module(php).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-export([find_worker/1, start_php/1, start_php/2]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    php_sup:start_link().

stop(_State) ->
    ok.


find_worker(Path) ->
  start_php(Path),
  Pids = [Pid || {_, Pid, _, _} <- supervisor:which_children(worker_id(Path))],
  N = random:uniform(length(Pids)),
  {ok, lists:nth(N, Pids)}.
  

start_php(Path) ->
  case erlang:whereis(php_sup) of
    undefined -> application:start(php);
    _ -> ok
  end,
  case erlang:whereis(worker_id(Path)) of
    undefined ->
      start_php(Path, [{workers, 4}]);
    Pid ->
      {ok, Pid}
  end.  

worker_id(Path) ->
  list_to_atom(lists:flatten(io_lib:format("php_worker_~s", [Path]))).

worker_id(Path, N) ->
  list_to_atom(lists:flatten(io_lib:format("php_worker_~s_~p", [Path, N]))).

start_php(Path, Options) ->
  Id = worker_id(Path),
  Workers = proplists:get_value(workers, Options, 1),
  supervisor:start_child(php_sup, {
    Id,
    {supervisor, start_link, [{local, Id}, php_sup, [php_worker_pool_sup]]},
    permanent,
    infinity,
    supervisor,
    []
  }),
  lists:foreach(fun(N) ->
    SubId = worker_id(Path, N),
    supervisor:start_child(Id, {
      SubId,
      {php_worker, start_link, [[{path,Path}]]},
      permanent,
      1000,
      worker,
      [php_worker]
    })
  end, lists:seq(1,Workers)).
