%% This Source Code Form is subject to the terms of
%% the Mozilla Public License, v. 2.0.
%% A copy of the MPL can be found in the LICENSE file or
%% you can obtain it at http://mozilla.org/MPL/2.0/.
%%
%% @author Brendan Hay
%% @copyright (c) 2012 Brendan Hay <brendan@soundcloud.com>
%% @doc
%%

-module(myxi).

-behaviour(application).

-include_lib("myxi_lib/include/myxi.hrl").

%% API
-export([start/0,
         stop/0]).

%% Callbacks
-export([start/2,
         stop/1]).

%%
%% API
%%

-spec start() -> ok.
%% @doc
start() -> myxi_boot:start(?MODULE).

-spec stop() -> ok.
%% @doc
stop() ->
    ok = application:stop(?MODULE),
    init:stop().

%%
%% Callbacks
%%

-spec start(normal, _) -> {ok, pid()} | {error, _}.
%% @hidden
start(normal, _Args) ->
    ok = start_listeners(),
    case myxi_sup:start_link() of
        ignore -> {error, sup_returned_ignore};
        Ret    -> Ret
    end.

-spec stop(_) -> ok.
%% @hidden
stop(_Args) -> ok.

%%
%% Setup
%%

-spec start_listeners() -> ok.
%% @private
start_listeners() -> lists:foreach(fun listener/1, myxi_util:config(frontends)).

-spec listener(frontend()) -> {ok, pid()}.
%% @private
listener(Config) ->
    Tcp = tcp_options(Config),
    lager:info("LISTEN ~s", [myxi_util:format_ip(Tcp)]),
    cowboy:start_listener(amqp_listener, myxi_util:option(max, Config),
                          cowboy_tcp_transport, Tcp,
                          myxi_connection, Config).

-spec tcp_options(frontend()) -> [proplists:property()].
%% @private
tcp_options(Config) ->
    [{ip, myxi_util:option(ip, Config)},
     {port, myxi_util:option(port, Config)}|myxi_util:config(tcp)].
