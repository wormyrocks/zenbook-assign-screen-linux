#!/bin/bash

top_screen_xrr_id=eDP-1
top_screen_xi_id=ELAN9008

bot_screen_xrr_id=DP-1
bot_screen_xi_id=ELAN9009

get_mon_dims () { 
  sed -rn "s/^$1 connected[^0-9]*([^ ]*).*$/\1/p" $tf1 | sed -rn 's/[x\+]/ /gp' 
}
all_dims () {
  sed -rn 's/^.*current ([0-9]*) x ([0-9]*).*$/\1 \2/p' $tf1
}
get_xinput_ids_by () {
  sed -rn "s/^.*$1.*id=([0-9]*).*$/\1/p" $tf2 
}
calc () { 
  bc -ql <<< ${1}
}
get_matrix () {
  read -r A B a b c d <<< ${1}
  c0=$(calc "${a}/${A}")
  c1=$(calc "${c}/${A}")
  c2=$(calc "${b}/${B}")
  c3=$(calc "${d}/${B}")
  echo "${c0} 0 ${c1} 0 ${c2} ${c3} 0 0 1"
}

tf1=$(mktemp)
xrandr>$tf1
tf2=$(mktemp)
xinput --list|grep pointer>$tf2
total_dims=$(all_dims)
top_dims=$(get_mon_dims $top_screen_xrr_id)
bot_dims=$(get_mon_dims $bot_screen_xrr_id)
top_matrix=$(get_matrix "$total_dims $top_dims")
bot_matrix=$(get_matrix "$total_dims $bot_dims")
echo total: [${total_dims}] top: [${top_dims}] bottom: [${bot_dims}]
ts_ids=$(get_xinput_ids_by ${top_screen_xi_id})
bs_ids=$(get_xinput_ids_by ${bot_screen_xi_id})
echo "top matrix: " ${top_matrix}
echo "bot matrix: " ${bot_matrix}
identity_matrix="1 0 0 0 1 0 0 0 1"

for id in ${bs_ids}
do
	echo ${id} -\> ${bot_matrix}
	xinput --set-prop ${id} --type=float "Coordinate Transformation Matrix" ${bot_matrix} && {
		xinput --set-prop ${id} --type=float "libinput Calibration Matrix" ${identity_matrix}
	} || xinput --disable ${id}
done

for id in ${ts_ids}
do
	echo ${id} -\> ${top_matrix}
	xinput --set-prop ${id} --type=float "Coordinate Transformation Matrix" ${top_matrix}
	xinput --set-prop ${id} --type=float "libinput Calibration Matrix" ${identity_matrix}
done

rm $tf1 $tf2
