%%% -------------------------------------------------------------------
%%% @author : joqerlang
%%% @doc : ets dbase for master service to manage app info , catalog  
%%%
%%% -------------------------------------------------------------------
-module(orchistrate).
 


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%-compile(export_all).
-export([simple_campaign/0,
	 update_info/3]).




%% ====================================================================
%% External functions
%% ====================================================================

%% @doc: update_catalog(GitUrl,Dir,FileName)->{ok,Config}|{error,Err} retreives the latets  config spec from git

-spec(update_info(GitUrl::string(),Dir::string(),FileName::string())->{ok,Config::[tuple()]}|{error,Err::string()}).
update_info(GitUrl,Dir,FileName)->
    os:cmd("rm -rf "++Dir),
    os:cmd("git clone "++GitUrl),
    {R,Info}=file:consult(filename:join(Dir,FileName)),
    {R,Info}.

%% --------------------------------------------------------------------
%% 
%%
%% --------------------------------------------------------------------
%% 1 Check missing services - try to start them
simple_campaign()->
    case boot_service:dns_get("catalog_service") of
	 [{_,CatalogNode}|_]->
	    Missing=rpc:call(CatalogNode,catalog_service,missing,[]),
	    io:format("Missing ~p~n",[{?MODULE,?LINE,Missing}]),
						% Missing [{ServiceId,Node}]
	    R1=create_start_services(Missing,CatalogNode,[]),
	    
	    % {{ServiceId,Type,Source},Node}
	    io:format("Start services ~p~n",[{?MODULE,?LINE,R1}]),
	     Obsolite=rpc:call(CatalogNode,catalog_service,obsolite,[]),
	    io:format("Obsolite ~p~n",[{?MODULE,?LINE,Obsolite}]),
	    [rpc:call(Node,boot_service,stop_service,[ServiceId])||{ServiceId,Node}<-Obsolite];
	 Err ->
	     io:format("~p~n",[{?MODULE,?LINE,Err}])
    end,
    ok.
    
create_start_services([],_CatalogNode,Acc)->
    Acc;
    
create_start_services([{ServiceId,Node}|T],CatalogNode,Acc)->
    L=rpc:call(CatalogNode,catalog_service,get_service,[ServiceId]),
    X=[{ServiceId2,Type,Source,Node}||{ServiceId2,Type,Source}<-L],
    R=start_services(X,CatalogNode,[]),
    NewAcc=lists:append(Acc,R),
    create_start_services(T,CatalogNode,NewAcc).

start_services([],_CatalogNode,StartResult)->
    StartResult;
start_services([{ServiceId,Type,Source,Node}|T],CatalogNode,Acc)->
    R=case rpc:call(Node,boot_service,start_service,[ServiceId,Type,Source]) of
	  {ok,ServiceId}->
	      rpc:call(CatalogNode,catallog_service,dns_add,[ServiceId,Node]),
	      {ok,ServiceId};
	  Err ->
	      rpc:call(CatalogNode,catallog_service,dns_delete,[ServiceId,Node]),
	      {error,Err}
      end,
    start_services(T,CatalogNode,[R|Acc]).
