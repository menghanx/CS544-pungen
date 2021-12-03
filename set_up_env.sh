conda create --name pungen --file spec-file.txt
conda activate pungen
pip install -r requirements.txt
python -m spacy download en_core_web_sm
python tmp.py

apt-get update
apt-get install -y build-essential gcc checkinstall cmake pkg-config git unzip wget gdb

pip install fuzzy
cd ../fairseq
python setup.py build develop

apt-get install openjdk-8-jdk
pip install --upgrade language_tool_python

python grammar.py --input data/result.json --output scored.json