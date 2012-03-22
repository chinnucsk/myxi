%% This Source Code Form is subject to the terms of
%% the Mozilla Public License, v. 2.0.
%% A copy of the MPL can be found in the LICENSE file or
%% you can obtain it at http://mozilla.org/MPL/2.0/.
%%
%% @author Brendan Hay
%% @copyright (c) 2012 Brendan Hay <brendan@soundcloud.com>
%% @doc
%%

-module(myxi_proxy_sup).

-behaviour(supervisor).

-include("include/myxi_proxy.hrl").

%% API
-export([start_link/0]).

%% Callbacks
-export([init/1]).

-define(BALANCER_DELAY, 8000).

%%
%% API
%%

-spec start_link() -> {ok, pid()} | ignore | {error, _}.
%% @doc
start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%
%% Callbacks
%%

-spec init([]) -> {ok, {{one_for_all, 3, 20}, [supervisor:child_spec()]}}.
%% @hidden
init([]) ->
    %% Used to ensure balancer check starts are delayed
    random:seed(erlang:now()),
    Topology = {topology, {myxi_topology, start_link, []},
                permanent, 2000, worker, [myxi_topology]},
    Balancers = [balancer_spec(B) || B <- myxi_config:env(backends, myxi_proxy)],
    {ok, {{one_for_one, 3, 20}, [Topology|Balancers]}}.

%%
%% Balancers
%%

balancer_spec({Name, Config}) ->
    Mod = myxi_config:option(balancer, Config),
    Args = [Name,
            Mod,
            endpoints(Name, Config),
            myxi_config:option(middleware, Config),
            random:uniform(?BALANCER_DELAY)],
    {Name, {myxi_balancer, start_link, Args},
     permanent, 2000, worker, [myxi_balancer]}.

endpoints(Name, Config) ->
    [endpoint(Name, N) || N <- myxi_config:option(nodes, Config)].

endpoint(Name, Options) ->
    Node = myxi_config:option(node, Options),
    Addr = {myxi_net:hostname(Node), myxi_config:option(port, Options)},
    #endpoint{node    = Node,
              backend = Name,
              address = Addr}.