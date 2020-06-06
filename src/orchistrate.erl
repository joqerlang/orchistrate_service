%%% -------------------------------------------------------------------
%%% @author : joqerlang
%%% @doc : ets dbase for master service to manage app info , catalog  
%%%
%%% -------------------------------------------------------------------
-module(orchistrate).
 


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


-include("common_macros.hrl").

%-compile(export_all).
-export([update_info/3]).




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