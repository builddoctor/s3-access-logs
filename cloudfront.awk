#/[0-9]+\-[0-9]+\-[0-9]+/ { gsub(/-/, "/"); 1 }
{ print $5 " - - " "[" $1 ":" $2 "+0000] \"" $6 $8 "\" " $9 " " $4 }