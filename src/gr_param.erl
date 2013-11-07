%% Copyright (c) 2013, Pedram Nimreezi <deadzen@deadzen.com>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(gr_param).

-behaviour(gen_server).

%% API
-export([start_link/1, 
         list/1, size/1, insert/2, 
         lookup/2, lookup_element/2,
         info/1, update/2, transform/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {init=true, table_id}).

%%%===================================================================
%%% API
%%%===================================================================
list(Server) ->
    gen_server:call(Server, list).

size(Server) ->
    gen_server:call(Server, size).

insert(Server, Data) ->
    gen_server:call(Server, {insert, Data}).

lookup(Server, Term) ->
    gen_server:call(Server, {lookup, Term}).

lookup_element(Server, Term) ->
    gen_server:call(Server, {lookup_element, Term}).

info(Server) ->
    gen_server:call(Server, info).

update(Counter, Value) ->
    gen_server:cast(?MODULE, {update, Counter, Value}).

%% @doc Transform Term -> Key to Key -> Term
transform(Server) ->
    gen_server:call(Server, transform).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(list, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:tab2list(TableId), State};
handle_call(size, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:info(TableId, size), State};
handle_call({insert, Data}, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:insert(TableId, Data), State};
handle_call({lookup, Term}, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:lookup(TableId, Term), State};
handle_call({lookup_element, Term}, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:lookup_element(TableId, Term, 2), State};
handle_call(info, _From, State) ->
    TableId = State#state.table_id,
    {reply, ets:info(TableId), State};
handle_call(transform, _From, State) ->
    TableId = State#state.table_id,
    ParamsList = [{K, V} || {V, K} <- ets:tab2list(TableId)],
    ets:delete_all_objects(TableId),
    ets:insert(TableId, ParamsList),
    {reply, ok, State};
handle_call(_Request, _From, State) ->
    Reply = {error, unhandled_message},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast({update, Counter, Value}, State) ->
    TableId = State#state.table_id,
    ets:update_counter(TableId, Counter, Value),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({'ETS-TRANSFER', TableId, _Pid, _Data}, State) ->
    {noreply, State#state{table_id=TableId}};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


