%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(services_test).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").



-ifdef(dir).
-define(CHECK_CATALOG,check_catalog_dir()).
-else.
-define(CHECK_CATALOG,check_catalog_git()).
-endif.


%% --------------------------------------------------------------------
-export([start/0]).
%-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================
-define(CATALOG,[{"adder_service",git,"https://github.com/joq62/"},
		      {"divi_service",git,"https://github.com/joq62/"},
		      {"dns_service",dir,"/home/pi/erlang/erl_infra/"},
		      {"log_service",dir,"/home/pi/erlang/erl_infra/"},
		      {"lib_service",dir,"/home/pi/erlang/erl_infra/"},
		      {"node_service",dir,"/home/pi/erlang/erl_infra/"}]).
-define(APP_SPEC1,[{"dns_service",'glurk@asus'},
		   {"dns_service",'node_dir_test@asus'},
		   {"lib_service",'node_dir_test@asus'},
		   {"log_service",'node_dir_test@asus'}]).

-define(APP_SPEC2,[{"dns_service",'glurk@asus'},
		   {"dns_service",'node_dir_test@asus'},
		   {"log_service",'node_dir_test@asus'}]).
		  
%% 
%% ----------------------------------------------- ---------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
start()->
    ?debugMsg("available"),
    ?assertEqual(ok,available()),
    ?debugMsg("missing"),
    ?assertEqual(ok,missing()),

    ?debugMsg("obsolite"),
    ?assertEqual(ok,obsolite()),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
available()->
    ?assertEqual([],services:available(?CATALOG)),
       ok=application:start(lib_service),
    ?assertEqual([{"lib_service",orchistrate_dir_test@asus}],services:available(?CATALOG)),
 
    ok=application:start(log_service),
    ?assertEqual([{"log_service",orchistrate_dir_test@asus},
		  {"lib_service",orchistrate_dir_test@asus}],services:available(?CATALOG)),
    ok=application:stop(lib_service),
    ?assertEqual([{"log_service",orchistrate_dir_test@asus}],services:available(?CATALOG)),
    ok.

missing()->
    ?assertEqual([{"dns_service",glurk@asus},
		  {"dns_service",node_dir_test@asus},
		  {"lib_service",node_dir_test@asus},
		  {"log_service",node_dir_test@asus}],services:missing(?CATALOG,?APP_SPEC1)),
    ok=application:start(lib_service),
    ?assertEqual([{"dns_service",glurk@asus},
		  {"dns_service",node_dir_test@asus},
		  {"lib_service",node_dir_test@asus},
		  {"log_service",node_dir_test@asus}],services:missing(?CATALOG,?APP_SPEC1)),
    ok.

obsolite()->
    ?assertEqual([{"lib_service",orchistrate_dir_test@asus},
		 {"log_service",orchistrate_dir_test@asus}],services:obsolite(?CATALOG,?APP_SPEC2)),
    ok=application:stop(lib_service),
    ?assertEqual([{"log_service",orchistrate_dir_test@asus}],services:obsolite(?CATALOG,?APP_SPEC2)),
    ok.
