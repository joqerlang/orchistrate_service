%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(orchistrate_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{app_info,available,missing,obsolite}).


%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(ORCHISTRATE_HEARTBEAT,20*1000).
-define(CATALOG_URL,"https://github.com/joqerlang/app_config.git/").
-define(CATALOG_DIR,"app_config").
-ifdef(infra_test).
-define(CATALOG_FILENAME,"app_infra_test.spec").
-else.
-define(CATALOG_FILENAME,"app.spec").
-endif.

-export([get_info/1,update_info/0,
	 get_service/1
	]).

-export([start/0,
	 stop/0,
	 ping/0,
	 heart_beat/1
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals



%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


ping()-> 
    gen_server:call(?MODULE, {ping},infinity).

%%-----------------------------------------------------------------------

%%
get_service(ServiceId)->
    gen_server:call(?MODULE, {get_service,ServiceId},infinity).
get_info(ServiceId)->
    gen_server:call(?MODULE, {get_info,ServiceId},infinity).
update_info()->
     gen_server:call(?MODULE, {update_info},infinity).

heart_beat(Interval)->
    gen_server:cast(?MODULE, {heart_beat,Interval}).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
    {ok,AppInfo}=orchistrate:update_info(?CATALOG_URL,?CATALOG_DIR,?CATALOG_FILENAME),
    spawn(fun()->h_beat(?ORCHISTRATE_HEARTBEAT) end),     
    
    {ok, #state{app_info=AppInfo}}.   
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------
handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({get_info,all}, _From, State) ->
    Reply=State#state.app_info,
    {reply, Reply,State};

handle_call({get_info,WantedServiceId}, _From, State) ->
    Reply=[{ServiceId,Node}||{ServiceId,Node}<-State#state.app_info,
				   ServiceId==WantedServiceId],
    {reply, Reply,State};
handle_call({update_info}, _From, State) ->
    Reply=case orchistrate:update_info(?CATALOG_URL,?CATALOG_DIR,?CATALOG_FILENAME) of
	      {ok,AppInfo}->
		  NewState=State#state{app_info=AppInfo},
		  ok;
	      {error,Err}->
		  NewState=State,
		  {error,Err}
	  end,
    {reply, Reply,NewState};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% -------------------------------------------------------------------
handle_cast({heart_beat,Interval}, State) ->
    NewState=case orchistrate:update_info(?CATALOG_URL,?CATALOG_DIR,?CATALOG_FILENAME) of
		 {ok,AppInfo}->
		     State#state{app_info=AppInfo};
		 Err->
		     io:format("error ~p~n",[{?MODULE,?LINE,Err}]),
		     State
	     end,
    spawn(fun()->h_beat(Interval) end),    
    {noreply, NewState};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
h_beat(Interval)->
    timer:sleep(Interval),
    case rpc:call(node(),orchistrate,simple_campaign,[],15*1000) of
	ok->
	    io:format("ok ~p~n",[{?MODULE,?LINE,ok}]),
	    ok;
	Err->
	     io:format("error ~p~n",[{?MODULE,?LINE,Err}]),
	    rpc:call(node(),lib_service,log_event,[?MODULE,?LINE,orchistrater,campaign,error,[Err]])
    end,
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
