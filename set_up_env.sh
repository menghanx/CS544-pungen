conda create --name pungen --file spec-file.txt
conda activate pungen
pip install -r requirements.txt
python -m spacy download en_core_web_sm
python tmp.py