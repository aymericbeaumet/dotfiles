# set the tab name
function tabname {
  printf "\e]1;${1:-default}\a"
}

function winname {
  printf "\e]2;$1\a"
}

str=`whoami`@`hostname`

tabname $str
winname $str
