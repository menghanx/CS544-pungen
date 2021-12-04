# Final Presentation Video
https://www.youtube.com/watch?v=m5_Nk-UQlxE

## Requirements
- Cuda 11 (Version we used for the project)
- Python 3.6
```
pip install -r requirements.txt
python -m spacy download en_core_web_sm
python nltk_download_data.py
```
- Fairseq(-py)
```
git clone -b pungen https://github.com/hhexiy/fairseq.git
cd fairseq
python setup.py build develop
```
- Pretrained WikiText-103 model from Fairseq
```
curl --create-dirs --output models/wikitext/model https://dl.fbaipublicfiles.com/fairseq/models/wiki103_fconv_lm.tar.bz2
tar xjf models/wikitext/model -C models/wikitext
rm models/wikitext/model
```
- Java SDK
```
apt-get install openjdk-8-jdk
pip install --upgrade language_tool_python
```
## Training

### Word relatedness model
Skipgram model is pre-trained and ready to use

### Edit model
The edit model takes a word and a template (masked sentence) and combine the two coherently.

Preprocess data:
```
python scripts/parsed_to_tokenized.py --input data/train.txt --output /tmp/train.tokenized.txt
python scripts/parsed_to_tokenized.py --input data/valid.txt --output /tmp/valid.tokenized.txt
cat /tmp/train.tokenized.txt /tmp/valid.tokenized.txt > /tmp/sent.tokenized.txt

for split in train valid; do \
	PYTHONPATH=. python scripts/make_src_tgt_files.py -i data/$split.txt \
        -o /tmp/edit/$split --delete-frac 0.5 \
		--window-size 2 --random-window-size; \
done

python -m pungen.preprocess --source-lang src --target-lang tgt \
	--destdir /tmp/edit/bin/data --thresholdtgt 80 --thresholdsrc 80 \
	--validpref /tmp/edit/valid \
	--trainpref /tmp/edit/train \
	--workers 8
```

### Retriever
Build a sentence retriever based on Bookcorpus.
The input should have a tokenized sentence per line.
```
python -m pungen.retriever --doc-file /tmp/sent.tokenized.txt --path retriever.pkl --overwrite
```

Training:
```
python -m pungen.train /tmp/edit/bin/data -a lstm \
    --source-lang src --target-lang tgt \
    --task edit --insert deleted --combine token \
    --criterion cross_entropy \
    --encoder lstm --decoder-attention True \
    --optimizer adagrad --lr 0.01 --lr-scheduler reduce_lr_on_plateau --lr-shrink 0.5 \
    --clip-norm 5 --max-epoch 50 --max-tokens 7000 --no-epoch-checkpoints \
    --save-dir models --no-progress-bar --log-interval 5000
```


## Generate puns
We generate puns with the following methods specified by the `system` argument.
- `rule`: the SURGEN method Retrieve+Swap+Topic described in the paper we followed 

All results and logs are saved in `reuslts`.
```
python generate_pun.py combiner-data \
	--path models/checkpoint_best.pt \
	--beam 20 --nbest 1 --unkpen 100 \
	--system rule --task edit \
	--retriever-model retriever.pkl --doc-file /tmp/sent.tokenized.txt \
	--lm-path models/wikitext/wiki103.pt \
	--word-counts-path models/wikitext/dict.txt \
	--skipgram-model skipgram/dict.txt skipgram/model.pt \
	--num-candidates 500 --num-templates 100 \
	--num-topic-word 100 --type-consistency-threshold 0.3 \
	--pun-words pun-data/test.json \
	--outdir results/new_result \
	--scorer random \
	--max-num-examples 100
```

## Analyze grammar score
```
python grammar.py --input results/new_result/result.json --output results/new_result/scored_result.json
```
