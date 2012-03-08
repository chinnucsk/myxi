%% This Source Code Form is subject to the terms of
%% the Mozilla Public License, v. 2.0.
%% A copy of the MPL can be found in the LICENSE file or
%% you can obtain it at http://mozilla.org/MPL/2.0/.
%%
%% @author Brendan Hay
%% @copyright (c) 2012 Brendan Hay <brendan@soundcloud.com>
%% @doc
%%

-module(totochtin_ha_policy).

-behaviour(totochtin_policy).

-include("include/totochtin.hrl").

%% Callbacks
-export([modify/3]).

-define(KEY, <<"x-ha-policy">>).

%%
%% Callbacks
%%

-spec modify(atom(), pid(), method()) -> totochtin_policy:return().
%% @doc
modify(_Current, _Topology, Method = #'queue.declare'{arguments = Args}) ->
    NewArgs = lists:keystore(?KEY, 1, Args, {?KEY, longstr, <<"all">>}),
    {modified, Method#'queue.declare'{arguments = NewArgs}};
modify(_Current, _Topology, Method) ->
    {unmodified, Method}.
