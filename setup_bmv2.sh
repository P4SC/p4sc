set -e
mkdir ./bmv2/p4src
cp -r ./backend/switch.p4 ./bmv2/p4src
cp -r ./backend/copy ./bmv2/p4src
cp -r ./backend/blocks ./bmv2/p4src
cp -r ./backend/includes ./bmv2/p4src
p4-validate ./bmv2/p4src/switch.p4
echo "Setup BMv2 successfully."
