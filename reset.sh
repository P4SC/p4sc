rm ./c4/*.txt

rm backend/chain.txt
rm backend/*.pyc
sudo rm -rf backend/src/control_flow.p4
touch backend/src/control_flow.p4
rm -rf backend/switch.p4
rm -rf backend/src/__pycache__/
rm -rf backend/copy/
mkdir backend/copy
touch backend/copy/includes.p4

rm frontend/*.pyc
rm frontend/lcsSrc/*.pyc
rm frontend/tableCmpSrc/*.pyc

cd bmv2/
./cleanup.sh
cd ..
rm -rf bmv2/p4src 

rm test/*.txt
