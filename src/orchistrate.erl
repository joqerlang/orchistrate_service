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
	     case rpc:call(CatalogNode,_service,available,[])
	    ListOfNodes=rpc:call(CatalogNode,_service,available,[]),
	    [rpc:cast(Node,boot_service,dns_update,[DnsInfo])||{_,Node}<-ListOfNodes];
	Err->
	    {ok,Catalog}=catalog:update(?CATALOG_URL,?CATALOG_DIR,?CATALOG_FILENAME),
	    {ok,NewDnsInfo}=dns:update(Catalog),
	    spawn(fun()->catalog_service:dns_update() end),
	    io:format("Err = ~p~n",[{?MODULE,?LINE,Err}]),
	    io:format("Catalog = ~p~n",[{?MODULE,?LINE,Catalog}]),
	    io:format("NewDnsInfo = ~p~n",[{?MODULE,?LINE,NewDnsInfo}])
	    
	    
    end,
    spawn(fun()->catalog_service:app_spec_update() end),
    timer:sleep(Interval),
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

    ok.
    
    
