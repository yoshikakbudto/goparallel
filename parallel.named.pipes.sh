#!/bin/bash

FinishedTasksPipe="./task4all.pipe"
LogFile="./task4all.log"
TasksTotal=30
MaxParallelTasks=8
ParallelTasks=0

# generate ${TasksTotal} random numbers for later use as tasknames. They're also a task working time (secs)
TasksList=$( while [ $(( TasksTotal-- )) -ne 0 ]; do echo\
                "$(dd if=/dev/urandom  bs=192 count=1 2>/dev/null | strings | wc -c)";
             done;
           )
# alt: use echo $(( RANDOM%12 ))

[ -p $FinishedTasksPipe ] || mkfifo $FinishedTasksPipe

# trap on ANY exit reason (FAIL/FAULT/normal exit)
# -v for verbosely delete
trap "rm -v $FinishedTasksPipe; truncate -s 0 $LogFile" EXIT

for i in $TasksList; {
        [ $ParallelTasks -eq $MaxParallelTasks ]&& {
                echo "[$(date +'%M:%S')] queue bank is full ($ParallelTasks). wait till at least one task to be completed..." >> $LogFile
                taskscompleted=$(wc -l $FinishedTasksPipe| cut -d" " -f 1)
                echo "[$(date +'%M:%S')] released $taskscompleted tasks from pipe finished queue" >> $LogFile
                (( ParallelTasks-=taskscompleted ))
       }

                ((ParallelTasks++))
                echo "[$(date +'%M:%S')] t$i started (running:$ParallelTasks)" >> $LogFile  && sleep ${i}s &&
         echo "[$(date +'%M:%S')] t$i finished" | tee -a $FinishedTasksPipe >> $LogFile &
                sleep 1;        #this is just for green buffer
}

echo "[$(date +'%M:%S')] All tasks started! Soon they will be finished" | tee -a $LogFile


while [ ! $(egrep -c 't[0-9]+ started' $LogFile) -eq $(grep -Ec 't[0-9]+ finished' $LogFile) ] ; do
        cat $FinishedTasksPipe
done
