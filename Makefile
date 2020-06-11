all:
	rm -rf app_config catalog node_config  logfiles *_service include *~ */*~ */*/*~;
	rm -rf */*.beam;
	rm -rf *.beam erl_crash.dump */erl_crash.dump */*/erl_crash.dump;
	cp src/*.app ebin;
	erlc -I ../include -o ebin src/*.erl;
doc_gen:
	rm -rf  node_config logfiles doc/*;
	erlc ../doc_gen.erl;
	erl -s doc_gen start -sname doc
git:
	# start lib_service
	rm -rf *_service ../lib_service/ebin/* ../lib_service/test_ebin/* ../lib_service/erl_crash.dump catalog.info;
	cp catalog.info_git catalog.info
	cp ../lib_service/src/*app ../lib_service/ebin;
	erlc -I ../include -o ../lib_service/ebin ../lib_service/src/*.erl;
	rm -rf *.beam ebin/* test_ebin/* erl_crash.dump;
	cp src/*app ebin;
	erlc -I  ../include -D local -o ebin src/*.erl;
	erlc -I ../include -D local -D git -o test_ebin test_src/*.erl;
	erl -pa ../lib_service/ebin -pa ebin -pa test_ebin -s master_service_tests start -sname master_git_test
test:
	rm -rf  logfiles latest.log erl_crash.dump;
	rm -rf *.beam ebin/* test_ebin/* erl_crash.dump;
	cp src/*app ebin;
	erlc -o ebin src/*.erl;
	erlc -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin -s orchistrate_service_tests start -sname orchistrate_dir_test
