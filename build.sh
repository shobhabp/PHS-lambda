#!/bin/bash

x=$1

function buildFunc {
  
  echo "\n BUILDING LAMBDA APPLICATION ${1} ------------------------------------------\n"
  (
    runFolder=${PWD}
    cd ${1} &&
    curFolder=${PWD##*/}
    export loglevel="INFO"

    go test -v -cover &&
    GOOS=linux GOARCH=amd64 go build -a -o ../bin/${curFolder} &&


	if [ "${curFolder}" != "nozip" ]; then
    cd ../bin/
		zip ${curFolder}.zip ${curFolder}
    cd ${runFolder}
	else
		echo "NO ZIP PROCESS"
	fi

  ) || (echo "FAILED TO BUILD ${curFolder}"; exit 10)
}

cd ../../.. || exit 10

cd - || exit 10

buildFunc supervisor_insert_events || exit 10
buildFunc worker_insert_events || exit 10

buildFunc supervisor_insert_stage2 || exit 10

buildFunc supervisor_db1_to_db2 || exit 10
buildFunc worker_db1_to_db2 || exit 10

buildFunc supervisor_ecs || exit 10
buildFunc worker_ecs || exit 10

buildFunc process_completion_notify || exit 10

buildFunc resource_cleanup || exit 10

if [ "$1" = "includefullrefresh" ]; then
  echo "Running full refresh lambdas"
  buildFunc api_full_refresh || exit 10

  buildFunc supervisor_ecs_full || exit 10
  buildFunc supervisor_ecs_full_batch || exit 10

  buildFunc worker_ecs_full || exit 10
  buildFunc worker_ecs_sftp || exit 10

  buildFunc ../../../../lambdas/price_history_api || exit 10
else
  echo "Full refresh lambdas are not built. If needed run the script like ./build.sh includefullrefresh"
fi

echo "DONE ALL OK! :)"
