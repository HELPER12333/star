#!/bin/bash
# check for errors under valgrind or sanitizers.

error()
{
  echo "instrumented testing failed on line $1"
  exit 1
}
trap 'error ${LINENO}' ERR

# define suitable post and prefixes for testing options
case $1 in
  --valgrind)
    echo "valgrind testing started"
    prefix=''
    exeprefix='valgrind --error-exitcode=42'
    postfix='1>/dev/null'
    threads="1"
  ;;
  --sanitizer-undefined)
    echo "sanitizer testing started"
    prefix='!'
    exeprefix=''
    postfix='2>&1 | grep -B40 -A40 "runtime error:"'
    threads="1"
  ;;
  --sanitizer-thread)
    echo "sanitizer testing started"
    prefix='!'
    exeprefix=''
    postfix='2>&1 | grep -B40 -A40 "WARNING: ThreadSanitizer:"'
    threads="2"

cat << EOF > tsan.supp
race:TTEntry::move
race:TTEntry::depth
race:TTEntry::bound
race:TTEntry::save
race:TTEntry::value
race:TTEntry::eval

race:TranspositionTable::probe
race:TranspositionTable::hashfull

EOF

    export TSAN_OPTIONS="halt_on_error=1 suppressions=./tsan.supp"

  ;;
  *)
    echo "unknown testing started"
    prefix=''
    exeprefix=''
    postfix=''
    threads="1"
  ;;
esac

# simple command line testing
for args in "eval" \
            "perft 4" \
            "go nodes 1000" \
            "go depth 10" \
            "go movetime 1000" \
            "go wtime 8000 btime 8000 winc 500 binc 500" \
            "bench 128 $threads 9 default depth"
do

   echo "$prefix $exeprefix ./stockfish $args $postfix"
   eval "$prefix $exeprefix ./stockfish $args $postfix"

done

# more general testing, following an uci protocol exchange
cat << EOF > game.exp
 set timeout 60
 spawn $exeprefix ./stockfish

 send "uci\n"
 expect "uciok"

 send "setoption name Threads value $threads\n"

 send "position startpos\n"
 send "go nodes 1000\n"
 expect "bestmove"

 send "position startpos moves e2e4 e7e6\n"
 send "go nodes 1000\n"
 expect "bestmove"

 send "d\n"

 send "position startpos\n"
 send "setoption name Skill Level value 7\n"
 send "go wtime 8000 btime 8000 winc 500 binc 500\n"
 expect "bestmove"

 send "setoption name Skill Level value 20\n"

 send "position startpos\n"
 send "go wtime 8000 btime 8000 winc 500 binc 500 nodestime 200\n"
 expect "bestmove"

 send "position fen 8/8/8/7k/3BBK2/4P3/8/8 w - - 0 1\n"
 send "go mate 7\n"
 expect "bestmove"

 send "setoption name UCI_Chess960 value true\n"
 send "position startpos\n"
 send "go depth 10\n"
 expect "bestmove"

 send "position fen 5rk1/1K4p1/8/8/3B4/8/8/8 b - - 0 1\n"
 send "go depth 30\n"
 expect "bestmove"

 send "quit\n"
 expect eof

 # return error code of the spawned program, useful for valgrind
 lassign [wait] pid spawnid os_error_flag value
 exit \$value
EOF

for exps in game.exp
do

  echo "$prefix expect $exps $postfix"
  eval "$prefix expect $exps $postfix"

  rm $exps

done

rm -f tsan.supp

echo "instrumented testing OK"
