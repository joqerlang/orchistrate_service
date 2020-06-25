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
	    M1=rpc:call(CatalogNode,catalog_service,missing,[]),
	    io:format("Missing ~p~n",[{?MODULE,?LINE,M1}]),
						% Missing [{ServiceId,Node}]
	    M2=create_start_list(M1,CatalogNode,[]),
	    
	    % {{ServiceId,Type,Source},Node}
	    io:format("M2 ~p~n",[{?MODULE,?LINE,M2}]),
	    R1=[rpc:call(Node,boot_service,start_service,[ServiceId,Type,Source])||{ServiceId,Type,Source,Node}<-M2],
	    io:format("Start services ~p~n",[{?MODULE,?LINE,R1}]),
	     Obsolite=rpc:call(CatalogNode,catalog_service,obsolite,[]),
	    io:format("Obsolite ~p~n",[{?MODULE,?LINE,Obsolite}]),
	    [rpc:call(Node,boot_service,stop_service,[ServiceId])||{ServiceId,Node}<-Obsolite];
	 Err ->
	     io:format("~p~n",[{?MODULE,?LINE,Err}])
    end,
    ok.
    
create_start_list([],_CatalogNode,Acc)->
    Acc;
    
create_start_list([{ServiceId,Node}|T],CatalogNode,Acc)->
    L=rpc:call(CatalogNode,catalog_service,get_service,[ServiceId]),
    R=[{ServiceId2,Type,Source,Node}||{ServiceId2,Type,Source}<-L],
    NewAcc=lists:append(Acc,R),
    create_start_list(T,CatalogNode,NewAcc).
